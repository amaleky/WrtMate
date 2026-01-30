package util

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"strings"
	"sync"
	"time"

	box "github.com/sagernet/sing-box"
)

func parseOutbounds(paths []string, jobs int) chan EntryType {
	seenKeys := sync.Map{}
	var wg sync.WaitGroup
	outboundChan := make(chan EntryType, jobs)

	wg.Add(1)
	go func() {
		defer wg.Done()
		defer close(outboundChan)
		for _, path := range paths {
			file, err := os.Open(path)
			if err != nil {
				fmt.Println(err)
				continue
			}
			scanner := bufio.NewScanner(file)
			buf := make([]byte, 0, 64*1024)
			scanner.Buffer(buf, 2*1024*1024)
			for scanner.Scan() {
				line := strings.TrimSpace(scanner.Text())
				if len(line) > 2000 || strings.Count(line, "://") != 1 || line == "" || strings.HasPrefix(line, "#") || strings.HasPrefix(line, "//") {
					continue
				}
				outbound, parsed, err := GetOutbound(line)
				if err != nil {
					continue
				}
				tag, ok := outbound["tag"].(string)
				if !ok || tag == "" {
					continue
				}
				if _, exists := seenKeys.LoadOrStore(tag, true); exists {
					continue
				}
				outboundChan <- EntryType{Tag: tag, Raw: parsed, Outbound: outbound}
			}
			if err := scanner.Err(); err != nil {
				fmt.Println(err)
			}
			file.Close()
		}
	}()
	return outboundChan
}

func testOutbounds(batch []EntryType, urlTestURLs []string, timeout int, callback func(EntryType)) {
	batchOutbounds := make([]OutboundType, len(batch))
	for i, entry := range batch {
		batchOutbounds[i] = entry.Outbound
	}
	ctx, instance, err := StartSinBox(batchOutbounds, nil, 0, "")
	if err != nil {
		fmt.Println("# Failed to start test instance: ", err)
		return
	}
	defer instance.Close()
	defer ctx.Done()
	var wg sync.WaitGroup
	semaphore := make(chan struct{}, len(batch))
	for _, entry := range batch {
		semaphore <- struct{}{}
		wg.Add(1)
		go func(e EntryType) {
			defer wg.Done()
			defer func() { <-semaphore }()
			out, ok := instance.Outbound().Outbound(e.Tag)
			if !ok {
				return
			}
			for _, testURL := range urlTestURLs {
				testCtx, cancel := context.WithTimeout(ctx, time.Duration(timeout)*time.Second)
				testErr := urlTest(testCtx, testURL, out)
				cancel()
				if testErr != nil {
					return
				}
			}
			callback(e)
		}(entry)
	}
	wg.Wait()
	close(semaphore)
}

func TestOutbounds(paths []string, urlTestURLs []string, jobs int, timeout int, socks int, printResults bool) ([]string, []OutboundType, []string, int, int) {
	entries := sync.Map{}
	var selectOnce sync.Once
	var ctx context.Context
	var instance *box.Box

	callback := func(entry EntryType) {
		entries.Store(entry.Tag, entry)
		if printResults {
			fmt.Println(entry.Raw)
		}
		selectOnce.Do(func() {
			if socks > 0 {
				ctx, instance, _ = StartSinBox([]OutboundType{entry.Outbound}, []string{entry.Tag}, socks, urlTestURLs[0])
			}
		})
	}

	batch := make([]EntryType, 0, jobs)

	totalCount := 0
	for outbound := range parseOutbounds(paths, jobs) {
		batch = append(batch, outbound)
		if len(batch) >= jobs {
			testOutbounds(batch, urlTestURLs, timeout, callback)
			fmt.Println("Processing", totalCount, "to", totalCount+len(batch)-1)
			totalCount += len(batch)
			batch = batch[:0]
		}
	}
	if len(batch) > 0 {
		testOutbounds(batch, urlTestURLs, timeout, callback)
		fmt.Println("Processing", totalCount, "to", totalCount+len(batch)-1)
		totalCount += len(batch)
	}

	raws := make([]string, 0)
	tags := make([]string, 0, 50)
	outbounds := make([]OutboundType, 0, 50)
	foundCount := 0
	entries.Range(func(key, value interface{}) bool {
		foundCount++
		entry := value.(EntryType)
		raws = append(raws, entry.Raw)
		if len(outbounds) < 50 {
			tags = append(tags, entry.Tag)
			outbounds = append(outbounds, entry.Outbound)
		}
		return true
	})

	if ctx != nil {
		ctx.Done()
	}
	if instance != nil {
		instance.Close()
	}

	return raws, outbounds, tags, foundCount, totalCount
}

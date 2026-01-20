package util

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"strings"
	"sync"
	"time"
)

func ProcessFile(filePath string, jobs int, urlTestURLs []string, verbose bool, seenKeys *sync.Map, timeout int, printResults bool) {
	if jobs < 1 {
		jobs = 1
	}

	var wg sync.WaitGroup
	semaphore := make(chan struct{}, jobs)
	entries := make([]SeenKeyType, 0)
	outbounds := make([]OutboundType, 0)

	file, err := os.Open(filePath)
	if err != nil {
		fmt.Println(err)
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	buf := make([]byte, 0, 64*1024)
	scanner.Buffer(buf, 2*1024*1024)

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") || strings.HasPrefix(line, "//") {
			continue
		}

		outbound, parsed, err := GetOutbound(line)
		if err != nil {
			if verbose {
				fmt.Printf("# Failed to get outbound: %s => %v\n", parsed, err)
			}
			continue
		}

		entry := SeenKeyType{
			Ok:       false,
			Raw:      parsed,
			Outbound: outbound,
		}

		tag, _ := entry.Outbound["tag"].(string)

		_, loaded := seenKeys.Load(tag)
		if loaded {
			continue
		}
		seenKeys.Store(tag, entry)

		outbounds = append(outbounds, outbound)
		entries = append(entries, entry)
	}

	if err := scanner.Err(); err != nil {
		fmt.Println(err)
		return
	}

	ctx, instance, err := StartOutbound(outbounds)
	if err != nil {
		fmt.Println("# Failed to start service: ", err)
		return
	}
	defer instance.Close()

	worker := func(entry SeenKeyType) {
		defer wg.Done()
		defer func() { <-semaphore }()

		tag, _ := entry.Outbound["tag"].(string)

		out, ok := instance.Outbound().Outbound(tag)
		if !ok {
			return
		}

		var testErr error
		for _, testURL := range urlTestURLs {
			testCtx, cancel := context.WithTimeout(ctx, time.Duration(timeout)*time.Second)
			testErr = URLTest(testCtx, testURL, out)
			cancel()
			if testErr != nil {
				break
			}
		}
		if testErr != nil {
			return
		}

		seenKeys.Store(tag, SeenKeyType{
			Ok:       true,
			Raw:      entry.Raw,
			Outbound: entry.Outbound,
		})

		if printResults {
			fmt.Println(entry.Raw)
		}
	}

	for _, entry := range entries {
		semaphore <- struct{}{}
		wg.Add(1)
		go worker(entry)
	}

	wg.Wait()
}

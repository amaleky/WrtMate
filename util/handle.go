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

func ProcessLines(lines []string, jobs int, urlTestURLs []string, verbose bool, hasOutput bool, seenKeys map[string]OutboundEntry) {
	var entries []OutboundEntry
	outbounds := make([]map[string]interface{}, 0, len(entries))

	for i, line := range lines {
		uri, parsed, err := ParseLink(line)
		if err != nil || uri == nil {
			continue
		}
		outbound, _, err := GetOutbound(uri, i+1)
		if err != nil {
			if verbose {
				fmt.Printf("# Failed to get outbound: %s => %v\n", parsed, err)
			}
			continue
		}
		tag := ParseOutboundKey(*outbound)
		if _, exists := seenKeys[tag]; exists {
			continue
		}
		(*outbound)["tag"] = tag
		entry := OutboundEntry{
			Ok:       false,
			Tag:      tag,
			Raw:      parsed,
			Outbound: *outbound,
		}
		seenKeys[tag] = entry
		singleOutbound := make([]map[string]interface{}, 0, 1)
		singleOutbound = append(singleOutbound, entry.Outbound)
		_, instance, err := NewOutbound(singleOutbound)
		if err == nil {
			entries = append(entries, entry)
			outbounds = append(outbounds, entry.Outbound)
		} else {
			if verbose {
				fmt.Printf("# Failed to parse config: %s => %v\n", parsed, err)
			}
		}
		if instance != nil {
			instance.Close()
		}
	}

	if len(entries) == 0 {
		return
	}

	ctx, instance, err := NewOutbound(outbounds)
	if err != nil {
		fmt.Println("# Failed to parse configs: ", err)
		return
	}
	defer instance.Close()
	if err := instance.Start(); err != nil {
		fmt.Println("# Failed to start service: ", err)
		return
	}

	if jobs < 1 {
		jobs = 1
	}

	entriesCh := make(chan OutboundEntry, jobs*2)
	var wg sync.WaitGroup
	var okMu sync.Mutex

	worker := func() {
		defer wg.Done()
		for entry := range entriesCh {
			outbound, ok := instance.Outbound().Outbound(entry.Tag)
			if !ok {
				continue
			}
			var testErr error
			for _, testURL := range urlTestURLs {
				testCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
				testErr = URLTest(testCtx, testURL, outbound)
				cancel()
				if testErr != nil {
					break
				}
			}
			if testErr != nil {
				fmt.Printf("# Failed to parse config: %s => %v\n", entry.Raw, testErr)
				continue
			}

			okMu.Lock()
			entry.Ok = true
			seenKeys[entry.Tag] = entry
			okMu.Unlock()

			if !hasOutput {
				fmt.Println(entry.Raw)
			}
		}
	}

	for i := 0; i < jobs; i++ {
		wg.Add(1)
		go worker()
	}

	for _, entry := range entries {
		entriesCh <- entry
	}
	close(entriesCh)
	wg.Wait()

	return
}

func ProcessFile(filePath string, jobs int, urlTestURLs []string, verbose bool, hasOutput bool, seenKeys map[string]OutboundEntry, archivePath string, truncate bool) {
	file, err := os.Open(filePath)
	if err != nil {
		return
	}
	defer file.Close()

	fmt.Println("# Processing", filePath)

	scanner := bufio.NewScanner(file)
	buf := make([]byte, 0, 64*1024)
	scanner.Buffer(buf, 2*1024*1024)

	var lines []string
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") || strings.HasPrefix(line, "//") {
			continue
		}
		lines = append(lines, line)
	}
	if err := scanner.Err(); err != nil {
		return
	}
	if len(lines) == 0 {
		return
	}

	if truncate {
		err := os.Truncate(archivePath, 0)
		if err != nil {
			return
		}
	}

	ProcessLines(lines, jobs, urlTestURLs, verbose, hasOutput, seenKeys)
}

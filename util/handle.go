package util

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"sync"
	"time"
)

func ProcessLines(lines []string, jobs int, urlTestURLs []string, verbose bool, hasOutput bool, seenKeys map[string]SeenKeyType) {
	if jobs < 1 {
		jobs = 1
	}

	linesCh := make(chan string, jobs*2)
	var wg sync.WaitGroup
	var seenKeysMu sync.Mutex

	worker := func() {
		defer wg.Done()
		for line := range linesCh {
			uri, parsed, err := ParseLink(line)
			if err != nil || uri == nil {
				continue
			}
			outbound, _, err := GetOutbound(uri)
			if err != nil {
				if verbose {
					fmt.Printf("# Failed to get outbound: %s => %v\n", parsed, err)
				}
				continue
			}
			tag := outbound["tag"].(string)

			seenKeysMu.Lock()
			if _, exists := seenKeys[tag]; exists {
				seenKeysMu.Unlock()
				continue
			}
			seenKeys[tag] = SeenKeyType{
				Ok:       false,
				Tag:      tag,
				Raw:      parsed,
				Outbound: outbound,
			}
			seenKeysMu.Unlock()

			singleOutbound := make([]OutboundType, 0, 1)
			singleOutbound = append(singleOutbound, outbound)
			ctx, instance, err := NewOutbound(singleOutbound)
			if err != nil {
				outboundJSON, marshalErr := json.Marshal(outbound)
				if marshalErr != nil {
					fmt.Println("# Failed to marshaling outbound: ", marshalErr, outbound)
					continue
				}
				fmt.Println("# Failed to parse config: ", err, string(outboundJSON), parsed)
				continue
			}
			defer instance.Close()
			if err := instance.Start(); err != nil {
				if verbose {
					fmt.Println("# Failed to start service: ", err)
				}
				continue
			}
			out, ok := instance.Outbound().Outbound(tag)
			if !ok {
				continue
			}
			var testErr error
			for _, testURL := range urlTestURLs {
				testCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
				testErr = URLTest(testCtx, testURL, out)
				cancel()
				if testErr != nil {
					break
				}
			}
			if testErr != nil {
				if verbose {
					fmt.Printf("# Failed to test config: %s => %v\n", parsed, testErr)
				}
				continue
			}

			seenKeysMu.Lock()
			updatedTag := seenKeys[tag]
			updatedTag.Ok = true
			seenKeys[tag] = updatedTag
			seenKeysMu.Unlock()

			if !hasOutput {
				fmt.Println(parsed)
			}
		}
	}

	for i := 0; i < jobs; i++ {
		wg.Add(1)
		go worker()
	}

	for _, line := range lines {
		linesCh <- line
	}

	close(linesCh)
	wg.Wait()
}

func ProcessFile(filePath string, jobs int, urlTestURLs []string, verbose bool, hasOutput bool, seenKeys map[string]SeenKeyType, archivePath string, truncate bool) {
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

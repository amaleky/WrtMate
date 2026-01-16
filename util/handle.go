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

func ProcessFile(filePath string, jobs int, urlTestURLs []string, verbose bool, seenKeys *sync.Map, printResults bool) {
	file, err := os.Open(filePath)
	if err != nil {
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	buf := make([]byte, 0, 64*1024)
	scanner.Buffer(buf, 2*1024*1024)
	if err := scanner.Err(); err != nil {
		return
	}

	if jobs < 1 {
		jobs = 1
	}

	linesCh := make(chan string, jobs*2)
	var wg sync.WaitGroup

	worker := func() {
		defer wg.Done()
		for line := range linesCh {
			outbound, err := GetOutbound(line)
			if err != nil {
				if verbose {
					fmt.Printf("# Failed to get outbound: %s => %v\n", line, err)
				}
				return
			}
			tag := outbound["tag"].(string)

			_, loaded := seenKeys.Load(tag)
			if loaded {
				continue
			}

			seenKeys.Store(tag, SeenKeyType{
				Ok:       false,
				Raw:      line,
				Outbound: outbound,
			})

			ctx, instance, err := StartOutbound(outbound)
			if err != nil {
				if verbose {
					outboundJSON, marshalErr := json.Marshal(outbound)
					if marshalErr != nil {
						fmt.Println("# Failed to marshaling outbound: ", marshalErr, outbound)
						continue
					}
					fmt.Println("# Failed to start service: ", err, string(outboundJSON), line)
				}
				continue
			}
			defer instance.Close()
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
				continue
			}

			seenKeys.Store(tag, SeenKeyType{
				Ok:       true,
				Raw:      line,
				Outbound: outbound,
			})

			if printResults {
				fmt.Println(line)
			}
		}
	}

	for i := 0; i < jobs; i++ {
		wg.Add(1)
		go worker()
	}

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") || strings.HasPrefix(line, "//") {
			continue
		}
		linesCh <- line
	}

	close(linesCh)
	wg.Wait()
}

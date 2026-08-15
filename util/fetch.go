package util

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"sync"
	"time"
)

const (
	subscriptionCheckTimeout           = 5 * time.Second
	subscriptionDownloadTimeout        = 2 * time.Minute
	maxConcurrentSubscriptionDownloads = 6
)

func fetchURL(rawURL, outputDir string) string {
	fileName := hashAsFileName(rawURL)
	filePath := filepath.Join(outputDir, fileName)
	hasCachedFile := false
	fi, err := os.Stat(filePath)
	if err == nil && !fi.IsDir() {
		hasCachedFile = true
		client := &http.Client{Timeout: subscriptionCheckTimeout}
		headReq, err := http.NewRequest(http.MethodHead, rawURL, nil)
		if err != nil {
			return filePath
		}
		headResp, err := client.Do(headReq)
		if err != nil {
			return filePath
		}
		headResp.Body.Close()
		if headResp.StatusCode != http.StatusOK {
			return filePath
		}
		remoteSizeStr := headResp.Header.Get("Content-Length")
		if remoteSizeStr != "" {
			remoteSize, err := strconv.ParseInt(remoteSizeStr, 10, 64)
			if err != nil {
				fmt.Println(err)
			} else if remoteSize == fi.Size() {
				return filePath
			}
		}
	}
	client := &http.Client{Timeout: subscriptionDownloadTimeout}
	resp, err := client.Get(rawURL)
	if err != nil {
		fmt.Println("# Can't download:", rawURL, err)
		if hasCachedFile {
			return filePath
		}
		return ""
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusOK {
		data, err := io.ReadAll(resp.Body)
		if err != nil {
			fmt.Println("# Can't download:", rawURL, err)
			if hasCachedFile {
				return filePath
			}
			return ""
		}
		decodedData, err := DecodeBase64IfNeeded(string(data))
		if err == nil {
			data = []byte(decodedData)
		}
		if err := os.WriteFile(filePath, data, 0o644); err != nil {
			fmt.Println("# Can't save subscription:", fileName, err)
			if hasCachedFile {
				return filePath
			}
			return ""
		}
		fmt.Println("# Downloaded subscription:", fileName)
	} else {
		fmt.Println("# Can't download:", rawURL, resp.StatusCode)
		if !hasCachedFile {
			return ""
		}
	}
	return filePath
}

func GetSubscriptions(outputDir string) []string {
	return getSubscriptions(SUBSCRIPTIONS, outputDir, fetchURL)
}

func getSubscriptions(rawURLs []string, outputDir string, fetch func(string, string) string) []string {
	results := make([]string, len(rawURLs))
	jobs := make(chan int)
	var wg sync.WaitGroup

	worker := func() {
		defer wg.Done()
		for index := range jobs {
			results[index] = fetch(rawURLs[index], outputDir)
		}
	}

	workerCount := min(maxConcurrentSubscriptionDownloads, len(rawURLs))
	for range workerCount {
		wg.Add(1)
		go worker()
	}
	for index := range rawURLs {
		jobs <- index
	}
	close(jobs)
	wg.Wait()

	paths := make([]string, 0, len(results))
	for _, path := range results {
		if path != "" {
			paths = append(paths, path)
		}
	}
	return paths
}

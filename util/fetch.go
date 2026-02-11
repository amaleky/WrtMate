package util

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"sync"
	"time"
)

func fetchURL(rawURL, outputDir string) string {
	fileName := hashAsFileName(rawURL)
	filePath := filepath.Join(outputDir, fileName)
	etagFilePath := filePath + ".etag"
	fi, err := os.Stat(filePath)
	if err == nil && !fi.IsDir() {
		storedETag, _ := os.ReadFile(etagFilePath)
		if len(storedETag) > 0 {
			client := &http.Client{Timeout: time.Duration(2) * time.Second}
			headReq, _ := http.NewRequest(http.MethodHead, rawURL, nil)
			headReq.Header.Set("If-None-Match", string(storedETag))
			headResp, err := client.Do(headReq)
			if err != nil || headResp.StatusCode == http.StatusNotModified {
				return filePath
			}
			defer headResp.Body.Close()
		}
	}

	client := &http.Client{Timeout: time.Duration(30) * time.Second}
	resp, err := client.Get(rawURL)
	if err != nil {
		fmt.Println(err)
		return filePath
	}

	defer resp.Body.Close()
	if resp.StatusCode == http.StatusOK {
		data, err := io.ReadAll(resp.Body)
		if err != nil {
			fmt.Println(err)
			return filePath
		}

		decodedData, err := DecodeBase64IfNeeded(string(data))
		if err != nil {
			fmt.Println(err)
			return filePath
		}

		data = []byte(decodedData)
		fmt.Println("# Downloaded subscription:", fileName)
		_ = os.WriteFile(filePath, data, 0o644)
		if etag := resp.Header.Get("ETag"); etag != "" {
			_ = os.WriteFile(etagFilePath, []byte(etag), 0o644)
		}
	}

	return filePath
}

func GetSubscriptions(outputDir string) []string {
	paths := make([]string, 0)
	var wg sync.WaitGroup

	worker := func(rawURL string) {
		defer wg.Done()
		path := fetchURL(rawURL, outputDir)
		paths = append(paths, path)
	}

	for _, rawURL := range SUBSCRIPTIONS {
		wg.Add(1)
		go worker(rawURL)
	}
	wg.Wait()

	return paths
}

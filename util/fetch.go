package util

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

func FetchURL(rawURL, outputDir string, timeout int) string {
	fileName := hashAsFileName(rawURL)
	filePath := filepath.Join(outputDir, fileName)
	fi, err := os.Stat(filePath)
	if err == nil && !fi.IsDir() {
		client := &http.Client{Timeout: time.Duration(2) * time.Second}
		headReq, _ := http.NewRequest(http.MethodHead, rawURL, nil)
		headResp, err := client.Do(headReq)
		if err != nil || headResp.StatusCode != http.StatusOK {
			return filePath
		}
		defer headResp.Body.Close()
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
	client := &http.Client{Timeout: time.Duration(timeout) * time.Second}
	resp, err := client.Get(rawURL)
	if err != nil {
		fmt.Println(err)
		return filePath
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusOK {
		data, err := io.ReadAll(resp.Body)
		if err == nil {
			decodedData, err := DecodeBase64IfNeeded(string(data))
			if err == nil {
				data = []byte(decodedData)
			}
			fmt.Println("# Downloaded subscription:", fileName)
			_ = os.WriteFile(filePath, data, 0o644)
		}
	}
	return filePath
}

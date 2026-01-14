package util

import (
	"io"
	"net/http"
	"os"
	"path/filepath"
	"time"
)

func FetchURL(rawURL, outputDir string, timeout int) string {
	client := &http.Client{Timeout: time.Duration(timeout) * time.Second}
	fileName := hashAsFileName(rawURL)
	filePath := filepath.Join(outputDir, fileName)
	resp, err := client.Get(rawURL)
	if err != nil {
		return filePath
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusOK {
		data, err := io.ReadAll(resp.Body)
		if err == nil {
			decodedData, err := DecodeBase64IfNeeded(string(data))
			if err != nil {
				data = []byte(decodedData)
			}
			_ = os.WriteFile(filePath, data, 0o644)
		}
	}
	return filePath
}

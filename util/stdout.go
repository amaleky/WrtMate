package util

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

func hashAsFileName(url string) string {
	sum := sha256.Sum256([]byte(url))
	return hex.EncodeToString(sum[:]) + ".txt"
}

func WriteJSONOutput(outputPath string, outbounds []OutboundType) error {
	if outputPath == "" {
		return fmt.Errorf("output path is empty")
	}
	filtered := make([]OutboundType, 0, len(outbounds))
	tags := make([]string, 0, len(outbounds))
	for _, outbound := range outbounds {
		if outboundType, ok := outbound["type"].(string); ok {
			if outboundType == "selector" || outboundType == "urltest" || outboundType == "direct" {
				continue
			}
		}
		if tag, ok := outbound["tag"].(string); ok && tag != "" {
			tags = append(tags, tag)
		}
		filtered = append(filtered, outbound)
	}

	configJSON, err := json.MarshalIndent(map[string]interface{}{
		"log": map[string]interface{}{
			"level": "warning",
		},
		"inbounds": []map[string]interface{}{
			{
				"type":        "mixed",
				"tag":         "mixed-in",
				"listen":      "0.0.0.0",
				"listen_port": 9802,
			},
		},
		"outbounds": append([]OutboundType{
			{
				"type":                        "urltest",
				"tag":                         "Auto",
				"outbounds":                   tags,
				"url":                         DEFAULT_URL_TEST,
				"interval":                    "10m",
				"tolerance":                   50,
				"interrupt_exist_connections": false,
			},
		}, filtered...),
		"route": map[string]interface{}{
			"final": "Auto",
		},
	}, "", "  ")
	if err != nil {
		return err
	}
	configJSON = append(configJSON, '\n')
	return os.WriteFile(outputPath, configJSON, 0o644)
}

func WriteRawOutput(outputPath string, rawConfigs []string) error {
	return os.WriteFile(outputPath, []byte(strings.Join(rawConfigs, "\n")), 0o644)
}

func SaveResult(outputPath string, archivePath string, start time.Time, seenKeys *sync.Map, truncateArchives bool) {
	if truncateArchives {
		err := os.Truncate(archivePath, 0)
		if err != nil {
			fmt.Println(err)
		}
	}

	linesCount := 0
	foundCount := 0
	var rawConfigs []string
	jsonOutbounds := make([]OutboundType, 0, 50)
	outputIsJSON := strings.HasSuffix(strings.ToLower(outputPath), ".json")

	seenKeys.Range(func(key, value interface{}) bool {
		linesCount++
		entry := value.(SeenKeyType)
		if entry.Ok == true {
			foundCount++
			rawConfigs = append(rawConfigs, entry.Raw)
			if outputIsJSON && len(jsonOutbounds) <= 50 {
				jsonOutbounds = append(jsonOutbounds, entry.Outbound)
			}
		}
		return true
	})

	if outputIsJSON {
		WriteJSONOutput(outputPath, jsonOutbounds)
	} else if outputPath != "" {
		WriteRawOutput(outputPath, rawConfigs)
	}
	WriteRawOutput(archivePath, rawConfigs)

	fmt.Printf("# Found %d configurations from %d lines in %.2fs\n", foundCount, linesCount, time.Since(start).Seconds())
}

func GeneratePaths(output *string, urlTestURL *string) (string, string, string, []string, bool) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Println("# Failed to use home dir: ", err)
		return "", "", "", nil, false
	}
	outputDir := filepath.Join(homeDir, ".subscriptions")
	err = os.MkdirAll(outputDir, 0o755)
	if err != nil {
		fmt.Println("# Failed to create cache directory: ", err)
		return "", "", "", nil, false
	}

	outputPath := *output
	archivePath := filepath.Join(homeDir, ".subscriptions", "archive.txt")

	urlTestURLs := ParseURLTestURLs(*urlTestURL)

	return outputDir, outputPath, archivePath, urlTestURLs, true
}

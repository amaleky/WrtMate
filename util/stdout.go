package util

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"strings"
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

func SaveResult(outputPath string, archivePath string, seenKeys map[string]SeenKeyType) {
	if len(seenKeys) == 0 {
		return
	}
	var rawConfigs []string
	jsonOutbounds := make([]OutboundType, 0, 50)
	outputIsJSON := strings.HasSuffix(strings.ToLower(outputPath), ".json")

	for _, entry := range seenKeys {
		if entry.Ok == true {
			rawConfigs = append(rawConfigs, entry.Raw)
			if outputIsJSON {
				if len(jsonOutbounds) < 50 {
					jsonOutbounds = append(jsonOutbounds, entry.Outbound)
				}
			}
		}
	}

	if outputIsJSON {
		WriteJSONOutput(outputPath, jsonOutbounds)
	} else if outputPath != "" {
		WriteRawOutput(outputPath, rawConfigs)
	}
	WriteRawOutput(archivePath, rawConfigs)
}

func PrintResult(archivePath string, seenKeys map[string]SeenKeyType, start time.Time) {
	file, fileOpenErr := os.Open(archivePath)
	if fileOpenErr != nil {
		fmt.Printf("Error opening file: %v\n", fileOpenErr)
		return
	}
	defer file.Close()
	data, fileReadErr := io.ReadAll(file)
	if fileReadErr != nil {
		fmt.Printf("Error reading file: %v\n", fileReadErr)
		return
	}
	lineCount := strings.Count(string(data), "\n")
	if len(data) > 0 && data[len(data)-1] != '\n' {
		lineCount++
	}
	fmt.Printf("Found %d/%d configs in %.2fs\n", lineCount, len(seenKeys), time.Since(start).Seconds())
}

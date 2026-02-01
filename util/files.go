package util

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func hashAsFileName(url string) string {
	sum := sha256.Sum256([]byte(url))
	return hex.EncodeToString(sum[:]) + ".txt"
}

func WriteJSONOutput(outputPath string, config map[string]interface{}) error {
	configJSON, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return err
	}
	configJSON = append(configJSON, '\n')
	return os.WriteFile(outputPath, configJSON, 0o644)
}

func WriteRawOutput(outputPath string, rawConfigs []string) error {
	if len(rawConfigs) < 10 {
		file, err := os.OpenFile(outputPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
		if err != nil {
			return err
		}
		defer file.Close()
		_, err = file.WriteString(strings.Join(rawConfigs, "\n"))
		return err
	}
	return os.WriteFile(outputPath, []byte(strings.Join(rawConfigs, "\n")), 0o644)
}

func SaveResult(outputPath string, archivePath string, rawConfigs []string, outbounds []OutboundType, tags []string, socks int, urlTest string) {
	if strings.HasSuffix(strings.ToLower(outputPath), ".json") {
		jsonOutput, _ := GetSingBoxConf(outbounds, tags, socks, urlTest)
		WriteJSONOutput(outputPath, jsonOutput)
	} else if outputPath != "" {
		WriteRawOutput(outputPath, rawConfigs)
	}
	WriteRawOutput(archivePath, rawConfigs)
}

func GeneratePaths(output *string) (string, string, string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", "", "", err
	}
	outputDir := filepath.Join(homeDir, ".subscriptions")
	err = os.MkdirAll(outputDir, 0o755)
	if err != nil {
		fmt.Println("# Failed to create cache directory: ", err)
		return "", "", "", err
	}

	outputPath := *output
	archivePath := filepath.Join(homeDir, ".subscriptions", "archive.txt")

	return outputDir, outputPath, archivePath, nil
}

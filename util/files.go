package util

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func hashAsFileName(url string) string {
	sum := sha256.Sum256([]byte(url))
	return hex.EncodeToString(sum[:]) + ".txt"
}

func WriteRawOutput(outputPath string, rawConfigs []string) error {
	return os.WriteFile(outputPath, []byte(strings.Join(rawConfigs, "\n")), 0o644)
}

func SaveResult(outputPath string, archivePath string, rawConfigs []string) {
	if outputPath != "" {
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

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

	box "github.com/sagernet/sing-box"
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
	return os.WriteFile(outputPath, []byte(strings.Join(rawConfigs, "\n")), 0o644)
}

var previousInstance *box.Box = nil
var previousOutboundCount = 0

func SaveResult(outputPath string, archivePath string, start time.Time, seenKeys *sync.Map, truncateArchives bool, socks int) {
	linesCount := 0
	foundCount := 0
	var rawConfigs []string
	tags := make([]string, 0, 50)
	outbounds := make([]OutboundType, 0, 50)
	outputIsJSON := strings.HasSuffix(strings.ToLower(outputPath), ".json")

	seenKeys.Range(func(key, value interface{}) bool {
		linesCount++
		entry := value.(SeenKeyType)
		tag := key.(string)
		if entry.Ok == true {
			foundCount++
			rawConfigs = append(rawConfigs, entry.Raw)
			if len(outbounds) < 50 {
				tags = append(tags, tag)
				outbounds = append(outbounds, entry.Outbound)
			}
		}
		return true
	})

	fmt.Printf("# Found %d configurations from %d lines in %.2fs\n", foundCount, linesCount, time.Since(start).Seconds())

	if foundCount < 1 {
		return
	}

	if truncateArchives {
		err := os.Truncate(archivePath, 0)
		if err != nil {
			fmt.Println(err)
		}
	}

	config := GetSingBoxConf(tags, outbounds, socks)

	if socks > 0 && len(outbounds) != previousOutboundCount {
		if previousInstance != nil {
			previousInstance.Close()
		}
		previousOutboundCount = len(outbounds)
		_, instance, err := StartSinBox(outbounds, config)
		if err != nil {
			fmt.Println("# Failed to start service: ", err, config)
		} else {
			previousInstance = instance
		}
	}

	if outputIsJSON {
		WriteJSONOutput(outputPath, config)
	} else if outputPath != "" {
		WriteRawOutput(outputPath, rawConfigs)
	}
	WriteRawOutput(archivePath, rawConfigs)
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

package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"scanner/util"
	"time"
)

func main() {
	start := time.Now()
	jobs := flag.Int("jobs", runtime.NumCPU(), "number of parallel jobs")
	urlTestURL := flag.String("urltest", util.DEFAULT_URL_TEST, "comma-separated list of URLs to use for urltest")
	output := flag.String("output", "", "path to write output (default stdout)")
	timeout := flag.Int("timeout", 15, "subscription download timeout")
	verbose := flag.Bool("verbose", false, "print extra output")
	flag.Parse()

	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Println("# Failed to use home dir: ", err)
		return
	}
	outputDir := filepath.Join(homeDir, ".subscriptions")
	err = os.MkdirAll(outputDir, 0o755)
	if err != nil {
		fmt.Println("# Failed to create cache directory: ", err)
		return
	}

	outputPath := *output
	hasOutput := output != nil && *output != ""
	archivePath := filepath.Join(homeDir, ".subscriptions", "archive.txt")

	seenKeys := make(map[string]util.OutboundEntry)
	urlTestURLs := util.ParseURLTestURLs(*urlTestURL)

	util.ProcessFile(archivePath, *jobs, urlTestURLs, *verbose, hasOutput, seenKeys, archivePath, true)
	util.SaveResult(outputPath, archivePath, seenKeys)

	for _, rawURL := range util.SUBSCRIPTIONS {
		filePath := util.FetchURL(rawURL, outputDir, *timeout)
		util.ProcessFile(filePath, *jobs, urlTestURLs, *verbose, hasOutput, seenKeys, archivePath, false)
		util.SaveResult(outputPath, archivePath, seenKeys)
	}

	util.PrintResult(archivePath, seenKeys, start)
}

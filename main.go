package main

import (
	"flag"
	"runtime"
	"scanner/util"
	"sync"
	"time"
)

func main() {
	start := time.Now()
	jobs := flag.Int("jobs", runtime.NumCPU(), "number of parallel jobs")
	urlTestURL := flag.String("urltest", util.DEFAULT_URL_TEST, "comma-separated list of URLs to use for urltest")
	output := flag.String("output", "", "path to write output (default stdout)")
	timeout := flag.Int("timeout", 15, "network timeout in seconds")
	verbose := flag.Bool("verbose", false, "print extra output")
	flag.Parse()

	seenKeys := &sync.Map{}
	outputDir, outputPath, archivePath, urlTestURLs, ok := util.GeneratePaths(output, urlTestURL)
	if !ok {
		return
	}

	util.ProcessFile(archivePath, *jobs, urlTestURLs, *verbose, seenKeys, *timeout, *output == "")
	util.SaveResult(outputPath, archivePath, start, seenKeys, true)

	for _, rawURL := range util.SUBSCRIPTIONS {
		filePath := util.FetchURL(rawURL, outputDir, *timeout)
		util.ProcessFile(filePath, *jobs, urlTestURLs, *verbose, seenKeys, *timeout, *output == "")
		util.SaveResult(outputPath, archivePath, start, seenKeys, false)
	}
}

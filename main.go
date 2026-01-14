package main

import (
	"flag"
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

	seenKeys := make(map[string]util.SeenKeyType)
	outputDir, outputPath, archivePath, urlTestURLs, ok := util.GeneratePaths(output, urlTestURL)
	if !ok {
		return
	}

	util.ProcessFile(archivePath, *jobs, urlTestURLs, *verbose, *output != "", seenKeys, archivePath, true)
	util.SaveResult(outputPath, archivePath, seenKeys)

	for _, rawURL := range util.SUBSCRIPTIONS {
		filePath := util.FetchURL(rawURL, outputDir, *timeout)
		util.ProcessFile(filePath, *jobs, urlTestURLs, *verbose, *output != "", seenKeys, archivePath, false)
		util.SaveResult(outputPath, archivePath, seenKeys)
	}

	util.PrintResult(archivePath, seenKeys, start)
}

package main

import (
	"flag"
	"fmt"
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
	socks := flag.Int("socks", 0, "socks proxy port")
	verbose := flag.Bool("verbose", false, "print extra output")
	flag.Parse()

	seenKeys := &sync.Map{}
	outputDir, outputPath, archivePath, urlTestURLs, ok := util.GeneratePaths(output, urlTestURL)
	if !ok {
		return
	}

	util.ProcessFile(archivePath, *jobs, urlTestURLs, *verbose, seenKeys, *timeout, *output == "" && *socks == 0)
	util.SaveResult(outputPath, archivePath, start, seenKeys, true, *socks)

	if *socks > 0 {
		fmt.Printf("\033[32mRunning SOCKS proxy: socks://127.0.0.1:%d\033[0m\n", *socks)
	}

	for _, rawURL := range util.SUBSCRIPTIONS {
		filePath := util.FetchURL(rawURL, outputDir, *timeout)
		util.ProcessFile(filePath, *jobs, urlTestURLs, *verbose, seenKeys, *timeout, *output == "" && *socks == 0)
		util.SaveResult(outputPath, archivePath, start, seenKeys, false, *socks)
	}

	if *socks > 0 {
		select {}
	}
}

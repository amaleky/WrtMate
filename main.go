package main

import (
	"flag"
	"fmt"
	"scanner/util"
	"sync"
	"time"
)

func main() {
	start := time.Now()
	jobs := flag.Int("jobs", 1000, "number of parallel jobs")
	urlTest := flag.String("urltest", util.DEFAULT_URL_TEST, "comma-separated list of URLs to use for urltest")
	output := flag.String("output", "", "path to write output (default stdout)")
	timeout := flag.Int("timeout", 5, "network timeout in seconds")
	socks := flag.Int("socks", 0, "socks proxy port")
	flag.Parse()

	seenKeys := &sync.Map{}
	outputDir, outputPath, archivePath, err := util.GeneratePaths(output)
	if err != nil {
		fmt.Println(err)
		return
	}

	paths := util.GetSubscriptions(outputDir)
	paths = append([]string{archivePath}, paths...)
	util.ParseFiles(paths, seenKeys)
	instance, StopInterval := util.StartProxy(socks, seenKeys, outputPath, archivePath, start)
	util.TestOutbounds(seenKeys, util.ParseURLTestURLs(*urlTest), *jobs, *timeout, *socks, *output == "" && *socks == 0)
	fmt.Printf("\033[32mDone in %.2fs\n", time.Since(start).Seconds())
	StopInterval()

	if *socks > 0 && instance != nil {
		select {}
	}
}

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
	urlTestURLs := util.ParseURLTestURLs(*urlTest)
	outputDir, outputPath, archivePath, err := util.GeneratePaths(output)
	if err != nil {
		fmt.Println(err)
		return
	}

	util.ParseFiles([]string{archivePath}, seenKeys, *jobs)
	foundOutbounds, foundTags := util.TestOutbounds(seenKeys, urlTestURLs, *jobs, *timeout, *output == "" && *socks == 0)
	_, instance, _ := util.StartSinBox(foundOutbounds, foundTags, *socks, urlTestURLs[0])

	util.ParseFiles(util.GetSubscriptions(outputDir), seenKeys, *jobs)
	foundOutbounds, foundTags = util.TestOutbounds(seenKeys, urlTestURLs, *jobs, *timeout, *output == "" && *socks == 0)

	outbounds, tags, rawConfigs, foundCount, linesCount := util.ParseOutbounds(seenKeys)
	if len(outbounds) > 0 {
		util.SaveResult(outputPath, archivePath, rawConfigs, outbounds, tags, *socks, urlTestURLs[0])
	}
	seenKeys = nil
	rawConfigs = nil
	fmt.Printf("# Found %d/%d configs in %.2fs\n", foundCount, linesCount, time.Since(start).Seconds())

	if *socks > 0 && len(outbounds) > 0 {
		if instance != nil {
			instance.Close()
		}
		_, instance, err := util.StartSinBox(outbounds, tags, *socks, urlTestURLs[0])
		if err != nil {
			fmt.Println(err)
			return
		}
		defer instance.Close()
		select {}
	}
}

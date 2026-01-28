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

	urlTestURLs := util.ParseURLTestURLs(*urlTest)
	util.TestOutbounds(seenKeys, urlTestURLs, *jobs, *timeout, *socks, *output == "" && *socks == 0)

	outbounds, tags, rawConfigs, foundCount, linesCount := util.ParseOutbounds(seenKeys)
	fmt.Printf("# Found %d configs from %d in %.2fs\n", foundCount, linesCount, time.Since(start).Seconds())

	if *socks > 0 && len(outbounds) > 0 {
		util.SaveResult(outputPath, archivePath, rawConfigs, outbounds, tags, *socks, urlTestURLs[0])
		_, instance, err := util.StartSinBox(outbounds, tags, *socks, urlTestURLs[0])
		if err != nil {
			fmt.Println(err)
			return
		}
		defer instance.Close()
		select {}
	}
}

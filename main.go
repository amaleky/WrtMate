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
	ctx1, instance1 := util.TestOutbounds(seenKeys, urlTestURLs, *jobs, *timeout, *socks, true, *output == "" && *socks == 0)

	util.ParseFiles(util.GetSubscriptions(outputDir), seenKeys, *jobs)
	ctx2, instance2 := util.TestOutbounds(seenKeys, urlTestURLs, *jobs, *timeout, *socks, instance1 == nil, *output == "" && *socks == 0)

	outbounds, tags, rawConfigs, foundCount, linesCount := util.ParseOutbounds(seenKeys)
	if len(outbounds) > 0 {
		util.SaveResult(outputPath, archivePath, rawConfigs, outbounds, tags, *socks, urlTestURLs[0])
	}
	seenKeys = nil
	rawConfigs = nil
	fmt.Printf("# Found %d/%d configs in %.2fs\n", foundCount, linesCount, time.Since(start).Seconds())

	if ctx1 != nil {
		ctx1.Done()
	}
	if instance1 != nil {
		instance1.Close()
	}
	if ctx2 != nil {
		ctx2.Done()
	}
	if instance2 != nil {
		instance2.Close()
	}

	if *socks > 0 && len(outbounds) > 0 {
		_, instance, err := util.StartSinBox(outbounds, tags, *socks, urlTestURLs[0])
		if err != nil {
			fmt.Println(err)
			return
		}
		defer instance.Close()
		select {}
	}
}

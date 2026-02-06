package main

import (
	"flag"
	"fmt"
	"scanner/util"
	"time"
)

func main() {
	start := time.Now()
	jobs := flag.Int("jobs", 1000, "number of parallel jobs")
	urlTest := flag.String("urltest", "https://gemini.google.com", "comma-separated list of URLs to use for urltest")
	output := flag.String("output", "", "path to write output (default stdout)")
	timeout := flag.Int("timeout", 5, "network timeout in seconds")
	socks := flag.Int("socks", 0, "socks proxy port")
	flag.Parse()

	urlTestURLs := util.ParseURLTestURLs(*urlTest)
	outputDir, outputPath, archivePath, err := util.GeneratePaths(output)
	if err != nil {
		fmt.Println(err)
		return
	}

	raws, outbounds, tags, foundCount, totalCount := util.TestOutbounds([]string{archivePath}, urlTestURLs, *jobs, *timeout, *socks, *output == "" && *socks == 0)

	if len(outbounds) < 10 {
		raws, outbounds, tags, foundCount, totalCount = util.TestOutbounds(util.GetSubscriptions(outputDir), urlTestURLs, *jobs, *timeout, *socks, *output == "" && *socks == 0)
	}

	fmt.Printf("# Found %d/%d configs in %.2fs\n", foundCount, totalCount, time.Since(start).Seconds())

	if len(outbounds) > 0 {
		util.SaveResult(outputPath, archivePath, raws, outbounds, tags, *socks, urlTestURLs[0])
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

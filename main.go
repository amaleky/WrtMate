package main

import (
	"flag"
	"fmt"
	"scanner/util"
	"sync"
	"time"

	box "github.com/sagernet/sing-box"
)

func main() {
	start := time.Now()
	jobs := flag.Int("jobs", 1000, "number of parallel jobs")
	urlTest := flag.String("urltest", util.DEFAULT_URL_TEST, "comma-separated list of URLs to use for urltest")
	output := flag.String("output", "", "path to write output (default stdout)")
	timeout := flag.Int("timeout", 15, "network timeout in seconds")
	socks := flag.Int("socks", 0, "socks proxy port")
	flag.Parse()

	interval := 10
	seenKeys := &sync.Map{}
	outputDir, outputPath, archivePath, err := util.GeneratePaths(output)
	if err != nil {
		fmt.Println(err)
		return
	}

	paths := util.GetSubscriptions(outputDir, timeout)
	paths = append([]string{archivePath}, paths...)
	util.ParseFiles(paths, seenKeys)

	if *socks > 0 {
		fmt.Printf("\033[32mRunning SOCKS proxy: socks://127.0.0.1:%d\033[0m\n", *socks)
	}

	ticker := time.NewTicker(time.Duration(interval) * time.Second)
	prevCount := 0
	var prevInstance *box.Box

	tester := func() {
		for range ticker.C {
			outbounds, tags, rawConfigs, foundCount, linesCount := util.ParseOutbounds(seenKeys)
			if foundCount == prevCount {
				continue
			}
			util.SaveResult(outputPath, archivePath, rawConfigs, outbounds, *socks)
			if *socks <= 0 {
				continue
			}
			if prevInstance != nil {
				prevInstance.Close()
			}
			prevCount = foundCount
			_, instance, err := util.StartSinBox(outbounds, tags, *socks)
			if err != nil {
				fmt.Println(err)
			} else {
				prevInstance = instance
				fmt.Printf("# Found %d configs from %d in %.2fs\n", foundCount, linesCount, time.Since(start).Seconds())
			}
		}
	}

	go tester()

	util.TestOutbounds(seenKeys, util.ParseURLTestURLs(*urlTest), *jobs, *timeout, *socks, *output == "" && *socks == 0)
	fmt.Printf("\033[32mDone in %.2fs\n", time.Since(start).Seconds())
	time.AfterFunc(time.Duration(interval)*time.Second, ticker.Stop)

	if *socks > 0 && prevInstance != nil {
		select {}
	}
}

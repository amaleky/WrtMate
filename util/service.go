package util

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/sagernet/sing-box"
	"github.com/sagernet/sing-box/include"
	"github.com/sagernet/sing-box/option"
)

func invalidOutboundKey(err error) int {
	msg := err.Error()
	start := strings.Index(msg, "[")
	end := strings.Index(msg, "]")
	if start == -1 || end == -1 || end <= start+1 {
		fmt.Printf("Index not found in error message: %s\n", msg)
		return -1
	}
	numStr := msg[start+1 : end]
	index, errParse := strconv.Atoi(numStr)
	if errParse != nil {
		return -1
	}
	return index
}

func StartSinBox(outbounds []OutboundType, tags []string, socks int) (context.Context, *box.Box, error) {
	config := GetSingBoxConf(outbounds, socks)
	configJSON, err := json.Marshal(config)
	if err != nil {
		return nil, nil, err
	}
	ctx := include.Context(context.Background())
	var opts option.Options
	if err := opts.UnmarshalJSONContext(ctx, configJSON); err != nil {
		return nil, nil, err
	}
	instance, err := box.New(box.Options{
		Context: ctx,
		Options: opts,
	})
	if err != nil {
		idx := invalidOutboundKey(err)
		if idx >= 0 && idx < len(outbounds) && len(outbounds) > 1 {
			tags = append(tags[:idx], tags[idx+1:]...)
			outbounds = append(outbounds[:idx], outbounds[idx+1:]...)
			return StartSinBox(outbounds, tags, socks)
		}
		return ctx, instance, err
	}
	err = instance.Start()
	if err != nil {
		return nil, nil, err
	}
	return ctx, instance, nil
}

func StartProxy(socks *int, seenKeys *sync.Map, outputPath string, archivePath string, start time.Time) (*box.Box, func()) {
	prevCount := 0
	interval := 10
	var prevInstance *box.Box
	ticker := time.NewTicker(time.Duration(interval) * time.Second)

	reRun := func() {
		outbounds, tags, rawConfigs, foundCount, linesCount := ParseOutbounds(seenKeys)
		if foundCount == prevCount {
			return
		}
		SaveResult(outputPath, archivePath, rawConfigs, outbounds, *socks)
		if *socks <= 0 {
			return
		}
		if prevInstance != nil {
			prevInstance.Close()
		}
		prevCount = foundCount
		_, instance, err := StartSinBox(outbounds, tags, *socks)
		if err != nil {
			fmt.Println(err)
		} else {
			prevInstance = instance
			fmt.Printf("# Found %d configs from %d in %.2fs\n", foundCount, linesCount, time.Since(start).Seconds())
		}
	}

	StopInterval := func() {
		ticker.Stop()
		reRun()
	}

	go func() {
		if *socks > 0 {
			fmt.Printf("\033[32mRunning SOCKS proxy: socks://127.0.0.1:%d\033[0m\n", *socks)
		}
		for range ticker.C {
			reRun()
		}
	}()

	return prevInstance, StopInterval
}

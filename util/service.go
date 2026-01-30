package util

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"

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

func StartSinBox(outbounds []OutboundType, tags []string, socks int, urlTest string) (context.Context, *box.Box, error) {
	if outbounds == nil || len(outbounds) == 0 {
		return nil, nil, fmt.Errorf("no outbounds provided")
	}
	config, defaultOutbounds := GetSingBoxConf(outbounds, tags, socks, urlTest)
	configJSON, err := json.Marshal(config)
	if err != nil {
		return nil, nil, err
	}

	ctx := include.Context(context.Background())
	var opts option.Options
	if err := opts.UnmarshalJSONContext(ctx, configJSON); err != nil {
		if ctx != nil {
			ctx.Done()
		}
		outbounds, tags = getRetry(err, defaultOutbounds, outbounds, tags)
		if outbounds != nil {
			return StartSinBox(outbounds, tags, socks, urlTest)
		}
		return nil, nil, err
	}

	instance, err := box.New(box.Options{
		Context: ctx,
		Options: opts,
	})
	if err != nil {
		if instance != nil {
			instance.Close()
		}
		if ctx != nil {
			ctx.Done()
		}
		outbounds, tags = getRetry(err, defaultOutbounds, outbounds, tags)
		if outbounds != nil {
			return StartSinBox(outbounds, tags, socks, urlTest)
		}
		return ctx, instance, err
	}

	if err := instance.Start(); err != nil {
		if instance != nil {
			instance.Close()
		}
		if ctx != nil {
			ctx.Done()
		}
		return nil, nil, err
	}

	if socks > 0 {
		fmt.Printf("Running SOCKS proxy: socks://127.0.0.1:%d\n", socks)
	}

	return ctx, instance, nil
}

func getRetry(err error, defaultOutbounds int, outbounds []OutboundType, tags []string) ([]OutboundType, []string) {
	idx := invalidOutboundKey(err) - defaultOutbounds
	if idx >= 0 && idx < len(outbounds) && len(outbounds) > 1 {
		outbounds = append(outbounds[:idx], outbounds[idx+1:]...)
		if tags != nil {
			tags = append(tags[:idx], tags[idx+1:]...)
		}
		return outbounds, tags
	}
	return nil, nil
}

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
	curOutbounds := outbounds
	curTags := tags

	for {
		config, defaultOutbounds := GetSingBoxConf(curOutbounds, curTags, socks, "Select", urlTest)
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
			if instance != nil {
				instance.Close()
			}
			idx := invalidOutboundKey(err) - defaultOutbounds
			if idx >= 0 && idx < len(curOutbounds) && len(curOutbounds) > 1 {
				fmt.Println("Removed invalid outbound", err, curOutbounds[idx])
				ctx.Done()
				curOutbounds = append(curOutbounds[:idx], curOutbounds[idx+1:]...)
				if curTags != nil {
					curTags = append(curTags[:idx], curTags[idx+1:]...)
				}
				continue
			}
			return ctx, instance, err
		}

		if err := instance.Start(); err != nil {
			instance.Close()
			return nil, nil, err
		}

		return ctx, instance, nil
	}
}

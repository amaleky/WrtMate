package util

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"strconv"
	"strings"

	"github.com/sagernet/sing-box"
	"github.com/sagernet/sing-box/adapter"
	"github.com/sagernet/sing-box/constant"
	"github.com/sagernet/sing-box/include"
	"github.com/sagernet/sing-box/option"
	"github.com/sagernet/sing/common/metadata"
	"github.com/sagernet/sing/common/network"
	"github.com/sagernet/sing/common/ntp"
)

func URLTest(ctx context.Context, link string, detour network.Dialer) error {
	linkURL, err := url.Parse(link)
	if err != nil {
		return err
	}
	hostname := linkURL.Hostname()
	port := linkURL.Port()
	if port == "" {
		switch linkURL.Scheme {
		case "http":
			port = "80"
		case "https":
			port = "443"
		}
	}
	instance, err := detour.DialContext(ctx, "tcp", metadata.ParseSocksaddrHostPortStr(hostname, port))
	if err != nil {
		return err
	}
	defer instance.Close()
	req, err := http.NewRequest(http.MethodGet, link, nil)
	if err != nil {
		return err
	}
	client := http.Client{
		Transport: &http.Transport{
			DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
				return instance, nil
			},
			TLSClientConfig: &tls.Config{
				Time:    ntp.TimeFuncFromContext(ctx),
				RootCAs: adapter.RootPoolFromContext(ctx),
			},
		},
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return http.ErrUseLastResponse
		},
		Timeout: constant.TCPTimeout,
	}
	defer client.CloseIdleConnections()
	resp, err := client.Do(req.WithContext(ctx))
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode > 399 {
		return fmt.Errorf("unexpected status: %d", resp.StatusCode)
	}
	_, err = io.Copy(io.Discard, resp.Body)
	if err != nil {
		return err
	}
	return nil
}

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

func StartSinBox(outbounds []OutboundType, config map[string]interface{}) (context.Context, *box.Box, error) {
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
		if err != nil && idx >= 0 && idx < len(outbounds) && len(outbounds) > 1 {
			fmt.Printf("# Skipping outbound %d because of error: %v %v\n", idx, err, outbounds[idx])
			outbounds = append(outbounds[:idx], outbounds[idx+1:]...)
			return StartSinBox(outbounds, config)
		}
		return ctx, instance, err
	}
	err = instance.Start()
	if err != nil {
		return nil, nil, err
	}
	return ctx, instance, nil
}

func GetSingBoxConf(tags []string, outbounds []OutboundType, socks int) map[string]interface{} {
	return map[string]interface{}{
		"log": map[string]interface{}{
			"level": "warning",
		},
		"inbounds": []map[string]interface{}{
			{
				"type":        "mixed",
				"listen":      "0.0.0.0",
				"listen_port": socks,
			},
		},
		"outbounds": append([]OutboundType{
			{
				"type":                        "urltest",
				"tag":                         "Auto",
				"outbounds":                   tags,
				"url":                         "https://1.1.1.1/cdn-cgi/trace/",
				"interval":                    "10m",
				"tolerance":                   50,
				"interrupt_exist_connections": false,
			},
			{
				"tag":  "direct",
				"type": "direct",
			},
		}, outbounds...),
		"route": map[string]interface{}{
			"rules": []map[string]interface{}{
				{
					"action": "sniff",
				},
				{
					"ip_is_private": true,
					"outbound":      "direct",
				},
				{
					"domain_suffix": []string{"ir"},
					"outbound":      "direct",
				},
			},
			"final": "Auto",
		},
	}
}

package util

import (
	"context"
	"crypto/tls"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"sync"
	"time"

	"github.com/sagernet/sing-box/adapter"
	"github.com/sagernet/sing-box/constant"
	"github.com/sagernet/sing/common/metadata"
	"github.com/sagernet/sing/common/network"
	"github.com/sagernet/sing/common/ntp"
)

func urlTest(ctx context.Context, link string, detour network.Dialer) error {
	linkURL, err := url.Parse(link)
	if err != nil {
		return err
	}
	hostname := linkURL.Hostname()
	port := linkURL.Port()
	if port == "" && linkURL.Scheme == "http" {
		port = "80"
	} else if port == "" && linkURL.Scheme == "https" {
		port = "443"
	}
	dialAddr := metadata.ParseSocksaddrHostPortStr(hostname, port)
	req, err := http.NewRequest(http.MethodGet, link, nil)
	if err != nil {
		return err
	}
	timeout := timeoutFromContext(ctx, constant.TCPTimeout)
	transport := &http.Transport{
		DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
			return detour.DialContext(ctx, "tcp", dialAddr)
		},
		TLSClientConfig: &tls.Config{
			Time:    ntp.TimeFuncFromContext(ctx),
			RootCAs: adapter.RootPoolFromContext(ctx),
		},
		DisableKeepAlives:     true,
		MaxIdleConns:          1,
		MaxIdleConnsPerHost:   1,
		IdleConnTimeout:       1 * time.Second,
		TLSHandshakeTimeout:   timeout,
		ResponseHeaderTimeout: timeout,
		ExpectContinueTimeout: 1 * time.Second,
	}
	client := &http.Client{Transport: transport, Timeout: timeout}
	defer transport.CloseIdleConnections()
	resp, err := client.Do(req.WithContext(ctx))
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 400 {
		return fmt.Errorf("unexpected status: %d", resp.StatusCode)
	}
	const maxBodySize = 1024 * 1024 // 1MB
	_, err = io.CopyN(io.Discard, resp.Body, maxBodySize)
	if err != nil && err != io.EOF {
		return fmt.Errorf("failed to read response body: %w", err)
	}
	return nil
}

func timeoutFromContext(ctx context.Context, fallback time.Duration) time.Duration {
	if deadline, ok := ctx.Deadline(); ok {
		remaining := time.Until(deadline)
		if remaining > 0 {
			return remaining
		}
	}
	return fallback
}

func TestOutbounds(seenKeys *sync.Map, urlTestURLs []string, jobs int, timeout int, printResults bool) ([]OutboundType, []string) {
	var entries []SeenKeyType
	seenKeys.Range(func(key, value interface{}) bool {
		entries = append(entries, value.(SeenKeyType))
		return true
	})

	var selectOnce sync.Once
	var foundTags []string
	var foundOutbounds []OutboundType
	total := len(entries)

	for start := 0; start < total; start += jobs {
		end := start + jobs
		if end > total {
			end = total
		}
		fmt.Printf("# Processing %d/%d configs\n", end, total)

		batchEntries := entries[start:end]
		batchOutbounds := make([]OutboundType, len(batchEntries))
		for i, entry := range batchEntries {
			batchOutbounds[i] = entry.Outbound
		}

		ctx, instance, err := StartSinBox(batchOutbounds, nil, 0, "")
		if err != nil {
			fmt.Println("# Failed to start test instance: ", err)
			continue
		}

		semaphore := make(chan struct{}, len(batchEntries))
		var wg sync.WaitGroup

		worker := func(entry SeenKeyType) {
			defer wg.Done()
			defer func() { <-semaphore }()

			tag, _ := entry.Outbound["tag"].(string)

			out, ok := instance.Outbound().Outbound(tag)
			if !ok {
				return
			}

			for _, testURL := range urlTestURLs {
				testCtx, cancel := context.WithTimeout(ctx, time.Duration(timeout)*time.Second)
				testErr := urlTest(testCtx, testURL, out)
				cancel()
				if testErr != nil {
					return
				}
			}

			seenKeys.Store(tag, SeenKeyType{
				Ok:       true,
				Raw:      entry.Raw,
				Outbound: entry.Outbound,
			})

			if printResults {
				fmt.Println(entry.Raw)
			}

			selectOnce.Do(func() {
				foundTags = []string{tag}
				foundOutbounds = []OutboundType{entry.Outbound}
			})
		}

		for _, entry := range batchEntries {
			semaphore <- struct{}{}
			wg.Add(1)
			go worker(entry)
		}

		wg.Wait()
		close(semaphore)
		instance.Close()
		ctx.Done()
		batchEntries = nil
		batchOutbounds = nil
	}

	entries = nil
	return foundOutbounds, foundTags
}

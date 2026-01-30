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

	box "github.com/sagernet/sing-box"
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

func runTempProxy(tag string, entry SeenKeyType, socks int, urlTest string) *box.Box {
	type outboundSelector interface {
		SelectOutbound(tag string) bool
	}
	var instanceTags []string
	instanceTags = append(instanceTags, tag)
	var instanceOutbounds []OutboundType
	instanceOutbounds = append(instanceOutbounds, entry.Outbound)
	_, instance, err := StartSinBox(instanceOutbounds, instanceTags, socks, urlTest)
	if err != nil {
		fmt.Println("# Failed to start service: ", err)
		return nil
	}
	selectorOutbound, ok := instance.Outbound().Outbound("Select")
	if !ok {
		fmt.Println("# Selector outbound 'Select' not found.")
		return nil
	}
	selector, ok := selectorOutbound.(outboundSelector)
	if !ok {
		fmt.Println("# Outbound 'Select' does not implement outboundSelector.")
		return nil
	}
	if socks > 0 && selector.SelectOutbound(tag) {
		fmt.Printf("Running SOCKS proxy: socks://127.0.0.1:%d\n", socks)
	}
	return instance
}

func TestOutbounds(seenKeys *sync.Map, urlTestURLs []string, jobs int, timeout int, socks int, printResults bool) {
	var entries []SeenKeyType
	var tags []string
	seenKeys.Range(func(key, value interface{}) bool {
		entry := value.(SeenKeyType)
		tag := key.(string)
		entries = append(entries, entry)
		tags = append(tags, tag)
		return true
	})

	var selectOnce sync.Once
	var serviceInstance *box.Box
	maxBatchSize := jobs
	total := len(entries)

	for start := 0; start < total; start += maxBatchSize {
		end := start + maxBatchSize
		if end > total {
			end = total
		}
		fmt.Printf("# Processing %d/%d configs\n", end, total)

		batchEntries := entries[start:end]
		batchTags := tags[start:end]
		batchOutbounds := make([]OutboundType, len(batchEntries))
		for i, entry := range batchEntries {
			batchOutbounds[i] = entry.Outbound
		}

		ctx, instance, err := StartSinBox(batchOutbounds, batchTags, 0, "")
		if err != nil {
			fmt.Println("# Failed to start service: ", err)
			continue
		}

		batchJobs := jobs
		if len(batchEntries) < batchJobs {
			batchJobs = len(batchEntries)
		}
		semaphore := make(chan struct{}, batchJobs)
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
				serviceInstance = runTempProxy(tag, entry, socks, urlTestURLs[0])
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
	}

	if serviceInstance != nil {
		serviceInstance.Close()
	}
}

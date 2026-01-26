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

type outboundSelector interface {
	SelectOutbound(tag string) bool
}

func TestOutbounds(seenKeys *sync.Map, url string, jobs int, timeout int, socks int, printResults bool) {
	urlTestURLs := ParseURLTestURLs(url)
	if jobs < 1 {
		jobs = 1
	}

	var wg sync.WaitGroup
	var selectOnce sync.Once
	tags := make([]string, 0, 50)
	semaphore := make(chan struct{}, jobs)
	outbounds := make([]OutboundType, 0)

	seenKeys.Range(func(key, value interface{}) bool {
		entry := value.(SeenKeyType)
		tag := key.(string)
		tags = append(tags, tag)
		outbounds = append(outbounds, entry.Outbound)
		return true
	})

	ctx, instance, err := StartSinBox(outbounds, tags, socks)
	if err != nil {
		fmt.Println("# Failed to start service: ", err)
		return
	}
	defer instance.Close()

	selectorOutbound, ok := instance.Outbound().Outbound("Select")
	if !ok {
		fmt.Println("# Selector outbound 'Select' not found.")
	}
	selector, ok := selectorOutbound.(outboundSelector)
	if !ok {
		fmt.Println("# Outbound 'Select' does not implement outboundSelector.")
	}

	worker := func(entry SeenKeyType) {
		defer wg.Done()
		defer func() { <-semaphore }()

		tag, _ := entry.Outbound["tag"].(string)

		out, ok := instance.Outbound().Outbound(tag)
		if !ok {
			return
		}

		var testErr error
		for _, testURL := range urlTestURLs {
			testCtx, cancel := context.WithTimeout(ctx, time.Duration(timeout)*time.Second)
			testErr = urlTest(testCtx, testURL, out)
			cancel()
			if testErr != nil {
				break
			}
		}
		if testErr != nil {
			return
		}

		seenKeys.Store(tag, SeenKeyType{
			Ok:       true,
			Raw:      entry.Raw,
			Outbound: entry.Outbound,
		})

		selectOnce.Do(func() {
			if selector.SelectOutbound(tag) {
				fmt.Printf("Running SOCKS proxy: socks://127.0.0.1:%d\n", socks)
				if printResults {
					fmt.Println(entry.Raw)
				}
			}
		})
	}

	seenKeys.Range(func(key, value interface{}) bool {
		entry := value.(SeenKeyType)
		semaphore <- struct{}{}
		wg.Add(1)
		go worker(entry)
		return true
	})

	wg.Wait()
}

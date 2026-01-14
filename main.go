package main

import (
	"bufio"
	"context"
	"crypto/sha256"
	"crypto/tls"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"runtime"
	"scanner/util"
	"strings"
	"sync"
	"time"
	"unicode"

	B "github.com/sagernet/sing-box"
	"github.com/sagernet/sing-box/adapter"
	C "github.com/sagernet/sing-box/constant"
	"github.com/sagernet/sing-box/include"
	"github.com/sagernet/sing-box/option"
	M "github.com/sagernet/sing/common/metadata"
	N "github.com/sagernet/sing/common/network"
	"github.com/sagernet/sing/common/ntp"
)

type outboundEntry struct {
	ok       bool
	tag      string
	raw      string
	outbound map[string]interface{}
}

func main() {
	start := time.Now()
	jobs := flag.Int("jobs", runtime.NumCPU(), "number of parallel jobs")
	urlTestURL := flag.String("urltest", "https://1.1.1.1/cdn-cgi/trace/", "comma-separated list of URLs to use for urltest")
	output := flag.String("output", "", "path to write output (default stdout)")
	timeout := flag.Int("timeout", 15, "subscription download timeout")
	verbose := flag.Bool("verbose", false, "print extra output")
	flag.Parse()

	hasOutput := output != nil && *output != ""

	homeDir, err := os.UserHomeDir()
	if err != nil {
		if *verbose {
			fmt.Println(err)
		}
		return
	}
	outputDir := filepath.Join(homeDir, ".subscriptions")
	err = os.MkdirAll(outputDir, 0o755)
	if err != nil {
		if *verbose {
			fmt.Println(err)
		}
		return
	}

	outputPath := *output
	archivePath := filepath.Join(homeDir, ".subscriptions", "archive.txt")

	subscriptionURLs := []string{
		"https://raw.githubusercontent.com/sinavm/SVM/main/subscriptions/xray/normal/mix",
		"https://raw.githubusercontent.com/Rayan-Config/C-Sub/main/configs/proxy.txt",
		"https://raw.githubusercontent.com/4n0nymou3/multi-proxy-config-fetcher/main/configs/proxy_configs.txt",
		"https://raw.githubusercontent.com/Mahdi0024/ProxyCollector/master/sub/proxies.txt",
		"https://raw.githubusercontent.com/ALIILAPRO/v2rayNG-Config/main/server.txt",
		"https://raw.githubusercontent.com/liketolivefree/kobabi/main/sub.txt",
		"https://raw.githubusercontent.com/hans-thomas/v2ray-subscription/master/servers.txt",
		"https://raw.githubusercontent.com/darkvpnapp/CloudflarePlus/main/proxy",
		"https://raw.githubusercontent.com/VPNforWindowsSub/configs/master/full.txt",
		"https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/vless.txt",
		"https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/ss.txt",
		"https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/wireguard.txt",
		"https://raw.githubusercontent.com/miladtahanian/V2RayCFGDumper/main/config.txt",
		"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/shadowsocks.txt",
		"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/trojan.txt",
		"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/vless.txt",
		"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/vmess.txt",
		"https://raw.githubusercontent.com/MatinGhanbari/v2ray-CONFIGs/main/subscriptions/v2ray/all_sub.txt",
		"https://raw.githubusercontent.com/barry-far/V2ray-Config/main/All_Configs_Sub.txt",
		"https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/main/all_configs.txt",
		"https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/main/all_extracted_configs.txt",
		"https://raw.githubusercontent.com/Epodonios/v2ray-CONFIGs/main/All_Configs_Sub.txt",
		"https://raw.githubusercontent.com/liMilCo/v2r/main/all_configs.txt",
		"https://raw.githubusercontent.com/mahdibland/V2RayAggregator/master/Eternity",
		"https://raw.githubusercontent.com/peasoft/NoMoreWalls/master/list.txt",
		"https://raw.githubusercontent.com/Surfboardv2ray/TGParse/main/splitted/mixed",
		"https://raw.githubusercontent.com/ermaozi/get_subscribe/main/subscribe/v2ray.txt",
		"https://raw.githubusercontent.com/itsyebekhe/PSG/main/subscriptions/xray/base64/mix",
		"https://raw.githubusercontent.com/roosterkid/openproxylist/main/V2RAY_BASE64.txt",
		"https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mci/sub_1.txt",
		"https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mtn/sub_1.txt",
		"https://raw.githubusercontent.com/R-the-coder/V2ray-configs/main/config.txt",
		"https://raw.githubusercontent.com/Joker-funland/V2ray-configs/main/config.txt",
		"https://raw.githubusercontent.com/AzadNetCH/Clash/main/AzadNet.txt",
		"https://raw.githubusercontent.com/ripaojiedian/freenode/main/sub",
	}

	seenKeys := make(map[string]outboundEntry)
	urlTestURLs := parseURLTestURLs(*urlTestURL)

	processFile(archivePath, *jobs, urlTestURLs, *verbose, hasOutput, seenKeys, archivePath, true)
	saveResult(outputPath, archivePath, seenKeys)

	for _, rawURL := range subscriptionURLs {
		filePath := fetchURL(rawURL, outputDir, *timeout)
		processFile(filePath, *jobs, urlTestURLs, *verbose, hasOutput, seenKeys, archivePath, false)
		saveResult(outputPath, archivePath, seenKeys)
	}

	printResult(archivePath, seenKeys, start)
}

func printResult(archivePath string, seenKeys map[string]outboundEntry, start time.Time) {
	file, fileOpenErr := os.Open(archivePath)
	if fileOpenErr != nil {
		fmt.Printf("Error opening file: %v\n", fileOpenErr)
		return
	}
	defer file.Close()
	data, fileReadErr := io.ReadAll(file)
	if fileReadErr != nil {
		fmt.Printf("Error reading file: %v\n", fileReadErr)
		return
	}
	lineCount := strings.Count(string(data), "\n")
	if len(data) > 0 && data[len(data)-1] != '\n' {
		lineCount++
	}
	fmt.Printf("Found %d/%d configs in %.2fs\n", lineCount, len(seenKeys), time.Since(start).Seconds())
}

func saveResult(outputPath string, archivePath string, seenKeys map[string]outboundEntry) {
	if len(seenKeys) == 0 {
		return
	}
	var rawConfigs []string
	jsonOutbounds := make([]map[string]interface{}, 0, 50)
	outputIsJSON := strings.HasSuffix(strings.ToLower(outputPath), ".json")

	for _, entry := range seenKeys {
		if entry.ok == true {
			rawConfigs = append(rawConfigs, entry.raw)
			if outputIsJSON {
				if len(jsonOutbounds) < 50 {
					jsonOutbounds = append(jsonOutbounds, entry.outbound)
				}
			}
		}
	}

	if outputIsJSON {
		writeJSONOutput(outputPath, jsonOutbounds)
	} else if outputPath != "" {
		writeRawOutput(outputPath, rawConfigs)
	}
	writeRawOutput(archivePath, rawConfigs)
}

func fetchURL(rawURL, outputDir string, timeout int) string {
	client := &http.Client{Timeout: time.Duration(timeout) * time.Second}
	fileName := hashAsFileName(rawURL)
	filePath := filepath.Join(outputDir, fileName)
	resp, err := client.Get(rawURL)
	if err != nil {
		return filePath
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusOK {
		data, err := io.ReadAll(resp.Body)
		if err == nil {
			decodedData, isDecoded := decodeBase64IfNeeded(data)
			if isDecoded {
				data = decodedData
			}
			_ = os.WriteFile(filePath, data, 0o644)
		}
	}
	return filePath
}

func hashAsFileName(url string) string {
	sum := sha256.Sum256([]byte(url))
	return hex.EncodeToString(sum[:]) + ".txt"
}

func decodeBase64IfNeeded(data []byte) ([]byte, bool) {
	var input = string(data)
	var builder strings.Builder
	builder.Grow(len(input))
	for _, r := range input {
		if !unicode.IsSpace(r) {
			builder.WriteRune(r)
		}
	}
	compact := builder.String()
	if compact == "" {
		return data, false
	}
	if !looksLikeBase64(compact) {
		return data, false
	}
	decoded, err := base64.StdEncoding.DecodeString(compact)
	if err != nil {
		decoded, err = base64.RawStdEncoding.DecodeString(compact)
	}
	if err != nil {
		return data, false
	}
	return decoded, true
}

func looksLikeBase64(input string) bool {
	if len(input) < 16 {
		return false
	}
	for _, r := range input {
		switch {
		case r >= 'A' && r <= 'Z':
		case r >= 'a' && r <= 'z':
		case r >= '0' && r <= '9':
		case r == '+' || r == '/' || r == '=' || r == '-' || r == '_':
		default:
			return false
		}
	}
	return true
}

func outboundKey(outbound map[string]interface{}) string {
	getStr := func(keys ...string) string {
		for _, k := range keys {
			if v, ok := outbound[k]; ok && v != "" {
				return fmt.Sprint(v)
			}
		}
		return ""
	}
	server := getStr("server", "address", "host")
	port := getStr("server_port", "port")
	typ := getStr("type", "protocol")
	return server + "|" + port + "|" + typ
}

func parseURLTestURLs(value string) []string {
	if strings.TrimSpace(value) == "" {
		return nil
	}
	rawParts := strings.Split(value, ",")
	urls := make([]string, 0, len(rawParts))
	for _, part := range rawParts {
		trimmed := strings.TrimSpace(part)
		if trimmed == "" {
			urls = append(urls, "https://1.1.1.1/cdn-cgi/trace/")
		} else {
			urls = append(urls, trimmed)
		}
	}
	return urls
}

func processFile(filePath string, jobs int, urlTestURLs []string, verbose bool, hasOutput bool, seenKeys map[string]outboundEntry, archivePath string, truncate bool) {
	file, err := os.Open(filePath)
	if err != nil {
		return
	}
	defer file.Close()

	if verbose {
		fmt.Println("# Processing", filePath)
	}

	scanner := bufio.NewScanner(file)
	buf := make([]byte, 0, 64*1024)
	scanner.Buffer(buf, 2*1024*1024)

	var lines []string
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") || strings.HasPrefix(line, "//") {
			continue
		}
		lines = append(lines, line)
	}
	if err := scanner.Err(); err != nil {
		return
	}
	if len(lines) == 0 {
		return
	}

	if truncate {
		err := os.Truncate(archivePath, 0)
		if err != nil {
			return
		}
	}

	processLines(lines, jobs, urlTestURLs, verbose, hasOutput, seenKeys)
}

func URLTest(ctx context.Context, link string, detour N.Dialer) error {
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
	instance, err := detour.DialContext(ctx, "tcp", M.ParseSocksaddrHostPortStr(hostname, port))
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
		Timeout: C.TCPTimeout,
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

func processLines(lines []string, jobs int, urlTestURLs []string, verbose bool, hasOutput bool, seenKeys map[string]outboundEntry) {
	var entries []outboundEntry

	for i, line := range lines {
		outbound, _, err := util.GetOutbound(line, i+1)
		if err != nil {
			if verbose {
				fmt.Printf("GetOutbound error: %s => %v\n", line, err)
			}
			continue
		}
		tag := outboundKey(*outbound)
		if _, exists := seenKeys[tag]; exists {
			continue
		}
		(*outbound)["tag"] = tag
		entry := outboundEntry{
			ok:       false,
			tag:      tag,
			raw:      line,
			outbound: *outbound,
		}
		seenKeys[tag] = entry
		entries = append(entries, entry)
	}

	if len(entries) == 0 {
		return
	}

	outbounds := make([]map[string]interface{}, 0, len(entries))
	for _, entry := range entries {
		outbounds = append(outbounds, entry.outbound)
	}

	config := map[string]interface{}{
		"log": map[string]interface{}{
			"disabled": true,
		},
		"outbounds": outbounds,
	}
	configJSON, err := json.Marshal(config)
	if err != nil {
		if verbose {
			fmt.Println(err)
		}
		return
	}

	ctx := include.Context(context.Background())
	var opts option.Options
	if err := opts.UnmarshalJSONContext(ctx, configJSON); err != nil {
		if verbose {
			fmt.Println(err)
		}
		return
	}
	instance, err := B.New(B.Options{
		Context: ctx,
		Options: opts,
	})
	if err != nil {
		if verbose {
			fmt.Println(err)
		}
		return
	}
	defer instance.Close()
	if err := instance.Start(); err != nil {
		if verbose {
			fmt.Println(err)
		}
		return
	}

	if jobs < 1 {
		jobs = 1
	}

	entriesCh := make(chan outboundEntry, jobs*2)
	var wg sync.WaitGroup
	var okMu sync.Mutex

	worker := func() {
		defer wg.Done()
		for entry := range entriesCh {
			outbound, ok := instance.Outbound().Outbound(entry.tag)
			if !ok {
				continue
			}
			var testErr error
			for _, testURL := range urlTestURLs {
				testCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
				testErr = URLTest(testCtx, testURL, outbound)
				cancel()
				if testErr != nil {
					break
				}
			}
			if testErr != nil {
				continue
			}

			okMu.Lock()
			entry.ok = true
			seenKeys[entry.tag] = entry
			okMu.Unlock()

			if !hasOutput {
				fmt.Println(entry.raw)
			}
		}
	}

	for i := 0; i < jobs; i++ {
		wg.Add(1)
		go worker()
	}

	for _, entry := range entries {
		entriesCh <- entry
	}
	close(entriesCh)
	wg.Wait()

	return
}

func writeJSONOutput(outputPath string, outbounds []map[string]interface{}) error {
	if outputPath == "" {
		return fmt.Errorf("output path is empty")
	}
	filtered := make([]map[string]interface{}, 0, len(outbounds))
	tags := make([]string, 0, len(outbounds))
	for _, outbound := range outbounds {
		if outboundType, ok := outbound["type"].(string); ok {
			if outboundType == "selector" || outboundType == "urltest" || outboundType == "direct" {
				continue
			}
		}
		if tag, ok := outbound["tag"].(string); ok && tag != "" {
			tags = append(tags, tag)
		}
		filtered = append(filtered, outbound)
	}

	configJSON, err := json.MarshalIndent(map[string]interface{}{
		"log": map[string]interface{}{
			"level": "warning",
		},
		"inbounds": []map[string]interface{}{
			{
				"type":        "mixed",
				"tag":         "mixed-in",
				"listen":      "0.0.0.0",
				"listen_port": 9802,
			},
		},
		"outbounds": append([]map[string]interface{}{
			{
				"type":                        "urltest",
				"tag":                         "Auto",
				"outbounds":                   tags,
				"url":                         "https://1.1.1.1/cdn-cgi/trace/",
				"interval":                    "10m",
				"tolerance":                   50,
				"interrupt_exist_connections": false,
			},
		}, filtered...),
		"route": map[string]interface{}{
			"final": "Auto",
		},
	}, "", "  ")
	if err != nil {
		return err
	}
	configJSON = append(configJSON, '\n')
	return os.WriteFile(outputPath, configJSON, 0o644)
}

func writeRawOutput(outputPath string, rawConfigs []string) error {
	return os.WriteFile(outputPath, []byte(strings.Join(rawConfigs, "\n")), 0o644)
}

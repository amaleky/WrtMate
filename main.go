package main

import (
	"bufio"
	"context"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"sync/atomic"
	"time"
	"unicode"

	"github.com/alireza0/s-ui/util"
	B "github.com/sagernet/sing-box"
	"github.com/sagernet/sing-box/common/urltest"
	"github.com/sagernet/sing-box/include"
	"github.com/sagernet/sing-box/option"
)

func main() {
	jobs := flag.Int("jobs", runtime.NumCPU(), "number of parallel jobs")
	urlTestURL := flag.String("urltest", "https://1.1.1.1/cdn-cgi/trace/", "comma-separated list of URLs to use for urltest (empty uses sing-box default)")
	output := flag.String("output", "", "path to write output (default stdout)")
	verbose := flag.Bool("verbose", false, "print extra output")
	flag.Parse()

	var outputWriter io.Writer = os.Stdout
	var outputFile *os.File
	outputPath := *output
	if outputPath == "" && flag.NArg() > 0 {
		outputPath = flag.Arg(0)
	}
	outputIsJSON := strings.HasSuffix(strings.ToLower(outputPath), ".json")
	if outputPath != "" && !outputIsJSON {
		file, err := os.Create(outputPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "open output file error (%s): %v\n", outputPath, err)
			return
		}
		outputFile = file
		outputWriter = file
		defer outputFile.Close()
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		if *verbose {
			fmt.Println("get user home dir error:", err)
		}
		return
	}
	outputDir := filepath.Join(homeDir, ".subscriptions")
	if err := os.MkdirAll(outputDir, 0o755); err != nil {
		if *verbose {
			fmt.Println("create output dir error:", err)
		}
		return
	}
	resultsPath := filepath.Join(outputDir, "results")
	if _, err := os.Stat(resultsPath); os.IsNotExist(err) {
		file, err := os.OpenFile(resultsPath, os.O_RDONLY|os.O_CREATE, 0o644)
		if err != nil {
			if *verbose {
				fmt.Println("create results file error:", err)
			}
			return
		}
		file.Close()
	}

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

	client := &http.Client{Timeout: 15 * time.Second}
	seenKeys := make(map[string]map[string]interface{})
	urlTestURLs := parseURLTestURLs(*urlTestURL)

	if outputIsJSON {
		configJSON, _ := buildJSONTemplate([]map[string]interface{}{})
		configJSON = append(configJSON, '\n')
		if outputPath == "" {
			os.Stdout.Write(configJSON)
		} else {
			os.WriteFile(outputPath, configJSON, 0o644)
		}
	}

	for _, rawURL := range subscriptionURLs {
		fileData, _, filePath, fetchErr := fetchURL(client, rawURL, outputDir)
		if fetchErr != nil && *verbose {
			fmt.Printf("fetch error (%s): %v\n", rawURL, fetchErr)
		}
		if len(fileData) == 0 {
			if *verbose {
				fmt.Printf("file is empty, skipping process (%s)\n", filePath)
			}
			continue
		}
		err = processFile(filePath, *jobs, urlTestURLs, *verbose, outputWriter, outputIsJSON, seenKeys, outputPath)
		if err != nil && *verbose {
			fmt.Printf("process error (%s): %v\n", filePath, err)
		}
	}
}

func fetchURL(client *http.Client, rawURL, outputDir string) ([]byte, bool, string, error) {
	fileName := hashAsFileName(rawURL)
	filePath := filepath.Join(outputDir, fileName)
	resp, err := client.Get(rawURL)
	decoded := false
	if err == nil {
		defer resp.Body.Close()
		if resp.StatusCode == http.StatusOK {
			data, err := io.ReadAll(resp.Body)
			if err == nil {
				decodedData, isDecoded := decodeBase64IfNeeded(data)
				if isDecoded {
					decoded = true
					data = decodedData
				}
				_ = os.WriteFile(filePath, data, 0o644)
			}
		}
	}
	fileData, readErr := os.ReadFile(filePath)
	if readErr != nil {
		return nil, decoded, filePath, readErr
	}
	return fileData, decoded, filePath, err
}

func hashAsFileName(url string) string {
	sum := sha256.Sum256([]byte(url))
	return hex.EncodeToString(sum[:]) + ".txt"
}

func decodeBase64IfNeeded(data []byte) ([]byte, bool) {
	compact := compactWhitespace(string(data))
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

func compactWhitespace(input string) string {
	var builder strings.Builder
	builder.Grow(len(input))
	for _, r := range input {
		if !unicode.IsSpace(r) {
			builder.WriteRune(r)
		}
	}
	return builder.String()
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
			continue
		}
		urls = append(urls, trimmed)
	}
	return urls
}

func processFile(filePath string, jobs int, urlTestURLs []string, verbose bool, output io.Writer, outputJSON bool, seenKeys map[string]map[string]interface{}, outputPath string) error {
	file, err := os.Open(filePath)
	if err != nil {
		return err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	buf := make([]byte, 0, 64*1024)
	scanner.Buffer(buf, 2*1024*1024)

	var lines []string
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}
		lines = append(lines, line)
	}
	if err := scanner.Err(); err != nil {
		return err
	}
	if len(lines) == 0 {
		return nil
	}

	type outboundEntry struct {
		tag      string
		outbound map[string]interface{}
		rawLine  string
	}

	var entries []outboundEntry
	var parseFailCount int64
	var printMu sync.Mutex
	seenKeySet := make(map[string]struct{})

	for i, line := range lines {
		outbound, tag, err := util.GetOutbound(line, i+1)
		if err != nil {
			atomic.AddInt64(&parseFailCount, 1)
			if verbose {
				printMu.Lock()
				fmt.Printf("GetOutbound error (%s): %s%v\n\n", filePath, line, err)
				printMu.Unlock()
			}
			continue
		}
		tag = outboundKey(*outbound)
		if _, exists := seenKeySet[tag]; exists {
			continue
		}
		seenKeySet[tag] = struct{}{}
		(*outbound)["tag"] = tag
		entries = append(entries, outboundEntry{
			tag:      tag,
			outbound: *outbound,
			rawLine:  line,
		})
	}

	if len(entries) == 0 {
		if verbose {
			fmt.Printf("processed %s: ok=0 urltest_failed=0 parse_failed=%d\n", filePath, parseFailCount)
		}
		return nil
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
		return err
	}

	ctx := include.Context(context.Background())
	var opts option.Options
	if err := opts.UnmarshalJSONContext(ctx, configJSON); err != nil {
		return err
	}
	instance, err := B.New(B.Options{
		Context: ctx,
		Options: opts,
	})
	if err != nil {
		return err
	}
	defer instance.Close()
	if err := instance.Start(); err != nil {
		return err
	}

	if jobs < 1 {
		jobs = 1
	}

	entriesCh := make(chan outboundEntry, jobs*2)
	var wg sync.WaitGroup
	var okCount int64
	var urlTestFailCount int64
	var okMu sync.Mutex

	worker := func() {
		defer wg.Done()
		for entry := range entriesCh {
			outbound, ok := instance.Outbound().Outbound(entry.tag)
			if !ok {
				atomic.AddInt64(&urlTestFailCount, 1)
				if verbose {
					printMu.Lock()
					fmt.Printf("urltest error (%s): outbound not found for tag %s\n", filePath, entry.tag)
					printMu.Unlock()
				}
				continue
			}
			testURLs := urlTestURLs
			if len(testURLs) == 0 {
				testURLs = []string{""}
			}
			var testErr error
			for _, testURL := range testURLs {
				testCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
				_, testErr = urltest.URLTest(testCtx, testURL, outbound)
				cancel()
				if testErr != nil {
					break
				}
			}
			_, jsonErr := json.MarshalIndent(entry.outbound, "", "  ")
			printMu.Lock()
			if testErr != nil {
				atomic.AddInt64(&urlTestFailCount, 1)
				printMu.Unlock()
				continue
			}
			if jsonErr != nil {
				atomic.AddInt64(&urlTestFailCount, 1)
				printMu.Unlock()
				continue
			}
			if outputJSON && seenKeys != nil {
				key := outboundKey(entry.outbound)
				if ok {
					okMu.Lock()
					seenKeys[key] = entry.outbound
					if outputPath != "" {
						outboundsForJSON := make([]map[string]interface{}, 0, len(seenKeys))
						for _, outbound := range seenKeys {
							if outbound != nil {
								outboundsForJSON = append(outboundsForJSON, outbound)
							}
						}
						if err := writeJSONOutput(outputPath, outboundsForJSON); err != nil {
							fmt.Fprintf(os.Stderr, "write json output error (%s): %v\n", outputPath, err)
						}
					}
					okMu.Unlock()
				}
			} else if output != nil {
				fmt.Fprintln(output, entry.rawLine)
			} else {
				fmt.Printf("%s\n", entry.rawLine)
			}
			printMu.Unlock()
			atomic.AddInt64(&okCount, 1)
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

	if output != nil {
		fmt.Printf("processed %s: ok=%d urltest_failed=%d parse_failed=%d\n", filePath, okCount, urlTestFailCount, parseFailCount)
	}
	return nil
}

func writeJSONOutput(outputPath string, outbounds []map[string]interface{}) error {
	if outputPath == "" {
		return fmt.Errorf("output path is empty")
	}
	configJSON, err := buildJSONTemplate(outbounds)
	if err != nil {
		return err
	}
	configJSON = append(configJSON, '\n')
	return os.WriteFile(outputPath, configJSON, 0o644)
}

func buildJSONTemplate(outbounds []map[string]interface{}) ([]byte, error) {
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

	config := map[string]interface{}{
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
	}

	return json.MarshalIndent(config, "", "  ")
}

package util

import (
	"bufio"
	"fmt"
	"net/url"
	"os"
	"strings"
	"sync"
)

func ParseLink(uri string) (*url.URL, error) {
	u, err := url.Parse(uri)
	if err == nil && u != nil {
		if u.Scheme != "vmess" {
			data, err := DecodeBase64IfNeeded(strings.TrimPrefix(u.String(), u.Scheme+"://"))
			if err == nil {
				uri, err := url.Parse(u.Scheme + "://" + data)
				if err == nil {
					u = uri
				}
			}
		}

		params := u.Query()
		if u != nil {
			delete(params, "remark")
			delete(params, "spx")
			u.Fragment = ""
			u.RawQuery = params.Encode()
		}
		return u, err
	}
	return nil, err
}

func ParseURLTestURLs(value string) []string {
	if strings.TrimSpace(value) == "" {
		return nil
	}
	rawParts := strings.Split(value, ",")
	urls := make([]string, 0, len(rawParts))
	for _, part := range rawParts {
		trimmed := strings.TrimSpace(part)
		if trimmed == "" {
			urls = append(urls, DEFAULT_URL_TEST)
		} else {
			urls = append(urls, trimmed)
		}
	}
	return urls
}

func ParseFiles(paths []string, seenKeys *sync.Map) {
	var wg sync.WaitGroup

	worker := func(filePath string) {
		defer wg.Done()
		file, err := os.Open(filePath)
		if err != nil {
			fmt.Println(err)
			return
		}
		defer file.Close()

		scanner := bufio.NewScanner(file)
		buf := make([]byte, 0, 64*1024)
		scanner.Buffer(buf, 2*1024*1024)

		for scanner.Scan() {
			line := strings.TrimSpace(scanner.Text())
			if line == "" || strings.HasPrefix(line, "#") || strings.HasPrefix(line, "//") {
				continue
			}

			outbound, parsed, err := GetOutbound(line)
			if err != nil {
				continue
			}

			tag, ok := outbound["tag"].(string)
			if !ok || tag == "" {
				continue
			}

			seenKeys.LoadOrStore(tag, SeenKeyType{
				Ok:       false,
				Raw:      parsed,
				Outbound: outbound,
			})
		}

		if err := scanner.Err(); err != nil {
			fmt.Println(err)
		}
	}

	for _, path := range paths {
		wg.Add(1)
		go worker(path)
	}
	wg.Wait()
}

func ParseOutbounds(seenKeys *sync.Map) ([]OutboundType, []string, []string, int, int) {
	linesCount := 0
	foundCount := 0
	rawConfigs := make([]string, 0)
	tags := make([]string, 0, 50)
	outbounds := make([]OutboundType, 0, 50)

	seenKeys.Range(func(key, value interface{}) bool {
		linesCount++
		entry := value.(SeenKeyType)
		tag := key.(string)
		if entry.Ok == true {
			foundCount++
			rawConfigs = append(rawConfigs, entry.Raw)
			if len(outbounds) < 50 {
				tags = append(tags, tag)
				outbounds = append(outbounds, entry.Outbound)
			}
		}
		return true
	})

	return outbounds, tags, rawConfigs, foundCount, linesCount
}

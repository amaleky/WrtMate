package util

import (
	"fmt"
	"net/url"
	"strings"
)

func ParseLink(uri string) (*url.URL, string, error) {
	u, err := url.Parse(uri)
	if err == nil && u != nil {
		params := u.Query()
		delete(params, "remark")
		u.Fragment = ""
		u.RawQuery = params.Encode()
		return u, u.String(), err
	}
	return nil, "", err
}

func ParseOutboundKey(outbound OutboundType) string {
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

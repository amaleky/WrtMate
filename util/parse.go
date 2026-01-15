package util

import (
	"net/url"
	"strings"
)

func ParseLink(uri string) (*url.URL, string, error) {
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
		delete(params, "remark")
		delete(params, "spx")
		u.Fragment = ""
		u.RawQuery = params.Encode()
		return u, u.String(), err
	}
	return nil, "", err
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

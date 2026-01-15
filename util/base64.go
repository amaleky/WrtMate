package util

import (
	"encoding/base64"
	"errors"
	"strings"
	"unicode"
)

func DecodeBase64IfNeeded(input string) (string, error) {
	var builder strings.Builder
	builder.Grow(len(input))
	for _, r := range input {
		if !unicode.IsSpace(r) {
			builder.WriteRune(r)
		}
	}
	compact := builder.String()
	if compact == "" && input != "" {
		return input, errors.New("Input is empty")
	}
	if !LooksLikeBase64(compact) {
		return input, nil
	}
	decoded, err := base64.StdEncoding.DecodeString(compact)
	if err != nil {
		decoded, err = base64.RawStdEncoding.DecodeString(compact)
	}
	if err != nil {
		return input, err
	}
	return string(decoded), nil
}

func LooksLikeBase64(input string) bool {
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

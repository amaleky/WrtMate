package util

func GetSingBoxConf(outbounds []OutboundType, socks int) map[string]interface{} {
	if socks <= 0 {
		socks = DEFAULT_SOCKS_PORT
	}

	var finalOutbound string
	for _, outbound := range outbounds {
		if outbound["type"] == "urltest" {
			if tag, ok := outbound["tag"].(string); ok {
				finalOutbound = tag
				break
			}
		}
	}

	routeConfig := map[string]interface{}{
		"rules": []map[string]interface{}{
			{
				"action": "sniff",
			},
		},
	}

	if finalOutbound != "" {
		routeConfig["final"] = finalOutbound
	}

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
		"outbounds": outbounds,
		"route":     routeConfig,
	}
}

package util

func GetSingBoxConf(outbounds []OutboundType, socks int) map[string]interface{} {
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

	config := map[string]interface{}{
		"log": map[string]interface{}{
			"level": "warning",
		},
		"outbounds": outbounds,
		"route":     routeConfig,
	}

	if socks > 1 && socks <= 65535 {
		config["inbounds"] = []map[string]interface{}{
			{
				"type":        "mixed",
				"listen":      "0.0.0.0",
				"listen_port": socks,
			},
		}
	}

	return config
}

package util

func GetSingBoxConf(outbounds []OutboundType, tags []string, socks int, finalOutbound string) (map[string]interface{}, int) {
	if socks <= 1 || socks > 65535 {
		socks = 9802
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
				"listen_port": socks,
			},
		},
		"outbounds": append([]OutboundType{
			{
				"type":                        "urltest",
				"tag":                         "Auto",
				"outbounds":                   tags,
				"url":                         "https://1.1.1.1/cdn-cgi/trace/",
				"interval":                    "1m",
				"tolerance":                   50,
				"interrupt_exist_connections": false,
			},
			{
				"type":      "selector",
				"tag":       "Select",
				"outbounds": tags,
			},
			{
				"type": "direct",
				"tag":  "Direct",
			},
			{
				"type": "block",
				"tag":  "Block",
			},
		}, outbounds...),
		"route": map[string]interface{}{
			"rules": []map[string]interface{}{
				{
					"action": "sniff",
				},
				{
					"inbound":  []string{"mixed-in"},
					"outbound": finalOutbound,
				},
			},
		},
	}

	return config, len(config["outbounds"].([]OutboundType)) - len(outbounds)
}

package util

func GetSingBoxConf(outbounds []OutboundType, tags []string, socks int, finalOutbound string, urlTest string) (map[string]interface{}, int) {
	if socks <= 1 || socks > 65535 || urlTest == "" || outbounds == nil || len(outbounds) == 0 {
		return map[string]interface{}{
			"log": map[string]interface{}{
				"level": "fatal",
			},
			"outbounds": outbounds,
		}, 0
	}

	var defaultOutbounds []OutboundType

	if finalOutbound == "Auto" {
		defaultOutbounds = append(defaultOutbounds, OutboundType{
			"type":                        "urltest",
			"tag":                         "Auto",
			"outbounds":                   tags,
			"url":                         urlTest,
			"interval":                    "1m",
			"tolerance":                   50,
			"interrupt_exist_connections": false,
		})
	}

	if finalOutbound == "Select" {
		defaultOutbounds = append(defaultOutbounds, OutboundType{
			"type":      "selector",
			"tag":       "Select",
			"outbounds": tags,
		})
	}

	defaultOutbounds = append(defaultOutbounds, OutboundType{
		"type": "direct",
		"tag":  "Direct",
	}, OutboundType{
		"type": "block",
		"tag":  "Block",
	})

	config := map[string]interface{}{
		"log": map[string]interface{}{
			"level": "fatal",
		},
		"inbounds": []map[string]interface{}{
			{
				"type":        "mixed",
				"tag":         "mixed-in",
				"listen":      "0.0.0.0",
				"listen_port": socks,
			},
		},
		"outbounds": append(defaultOutbounds, outbounds...),
		"route": map[string]interface{}{
			"rules": []map[string]interface{}{
				{
					"action": "sniff",
				},
				{
					"ip_is_private": true,
					"outbound":      "direct",
				},
				{
					"domain_suffix": []string{".ir", ".cn"},
					"outbound":      "Direct",
				},
			},
			"final": finalOutbound,
		},
	}

	return config, len(defaultOutbounds)
}

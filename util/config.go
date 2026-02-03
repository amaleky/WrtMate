package util

func GetSingBoxConf(outbounds []OutboundType, tags []string, socks int, urlTest string) (map[string]interface{}, int) {
	if socks <= 1 || socks > 65535 || urlTest == "" || outbounds == nil || len(outbounds) == 0 {
		return map[string]interface{}{
			"log": map[string]interface{}{
				"level": "fatal",
			},
			"outbounds": outbounds,
		}, 0
	}

	return map[string]interface{}{
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
		"outbounds": append([]OutboundType{
			{
				"type":                        "urltest",
				"tag":                         "Auto",
				"outbounds":                   tags,
				"url":                         urlTest,
				"interval":                    "30m",
				"tolerance":                   50,
				"interrupt_exist_connections": false,
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
					"ip_is_private": true,
					"outbound":      "Direct",
				},
				{
					"domain_suffix": []string{".ir", ".cn"},
					"outbound":      "Direct",
				},
			},
			"final": "Auto",
		},
	}, 3
}

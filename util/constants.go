package util

type OutboundType map[string]interface{}

type SeenKeyType struct {
	Ok       bool
	Raw      string
	Outbound OutboundType
}

var DEFAULT_URL_TEST = "https://cachefly.cachefly.net/1mb.test"

var SUBSCRIPTIONS = []string{
	"https://raw.githubusercontent.com/10ium/V2Hub3/main/merged",
	"https://raw.githubusercontent.com/10ium/V2rayCollector/main/mixed_iran.txt",
	"https://raw.githubusercontent.com/10ium/V2rayCollectorLite/main/mixed_iran.txt",
	"https://raw.githubusercontent.com/10ium/telegram-configs-collector/main/splitted/mixed",
	"https://raw.githubusercontent.com/4n0nymou3/multi-proxy-config-fetcher/main/configs/proxy_configs.txt",
	"https://raw.githubusercontent.com/Created-By/Telegram-Eag1e_YT/main/%40Eag1e_YT",
	"https://raw.githubusercontent.com/F0rc3Run/F0rc3Run/main/Best-Results/proxies.txt",
	"https://raw.githubusercontent.com/Freedom-Guard-Builder/Freedom-Finder/main/out/raw_all.txt",
	"https://raw.githubusercontent.com/MatinGhanbari/v2ray-CONFIGs/main/subscriptions/v2ray/all_sub.txt",
	"https://raw.githubusercontent.com/Mosifree/-FREE2CONFIG/main/Reality",
	"https://raw.githubusercontent.com/ShatakVPN/ConfigForge-V2Ray/main/configs/all.txt",
	"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/shadowsocks.txt",
	"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/trojan.txt",
	"https://raw.githubusercontent.com/VPNforWindowsSub/configs/master/full.txt",
	"https://raw.githubusercontent.com/crackbest/V2ray-Config/main/config.txt",
	"https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/main/all_extracted_configs.txt",
	"https://raw.githubusercontent.com/giromo/Collector/main/All_Configs_Sub.txt",
	"https://raw.githubusercontent.com/hamedp-71/Sub_Checker_Creator/main/final.txt",
	"https://raw.githubusercontent.com/itsyebekhe/PSG/main/subscriptions/xray/normal/mix",
	"https://raw.githubusercontent.com/liMilCo/v2r/main/all_configs.txt",
	"https://raw.githubusercontent.com/maimengmeng/mysub/main/valid_content_all.txt",
	"https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/ss.txt",
	"https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/vless.txt",
	"https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/vmess.txt",
	"https://raw.githubusercontent.com/roosterkid/openproxylist/main/V2RAY_RAW.txt",
	"https://raw.githubusercontent.com/sinavm/SVM/main/subscriptions/xray/normal/mix",
	"https://raw.githubusercontent.com/zieng2/wl/main/vless_universal.txt",
}

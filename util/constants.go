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
	"https://raw.githubusercontent.com/Argh94/V2RayAutoConfig/main/configs/Hysteria2.txt",
	"https://raw.githubusercontent.com/Argh94/V2RayAutoConfig/main/configs/ShadowSocks.txt",
	"https://raw.githubusercontent.com/Argh94/V2RayAutoConfig/main/configs/Trojan.txt",
	"https://raw.githubusercontent.com/Argh94/V2RayAutoConfig/main/configs/Vmess.txt",
	"https://raw.githubusercontent.com/Created-By/Telegram-Eag1e_YT/main/%40Eag1e_YT",
	"https://raw.githubusercontent.com/Danialsamadi/v2go/main/AllConfigsSub.txt",
	"https://raw.githubusercontent.com/F0rc3Run/F0rc3Run/main/Best-Results/proxies.txt",
	"https://raw.githubusercontent.com/Farid-Karimi/Config-Collector/main/mixed_iran.txt",
	"https://raw.githubusercontent.com/Firmfox/Proxify/main/v2ray_configs/seperated_by_protocol/other.txt",
	"https://raw.githubusercontent.com/Firmfox/Proxify/main/v2ray_configs/seperated_by_protocol/shadowsocks.txt",
	"https://raw.githubusercontent.com/Firmfox/Proxify/main/v2ray_configs/seperated_by_protocol/trojan.txt",
	"https://raw.githubusercontent.com/Firmfox/Proxify/main/v2ray_configs/seperated_by_protocol/vless.txt",
	"https://raw.githubusercontent.com/Firmfox/Proxify/main/v2ray_configs/seperated_by_protocol/vmess.txt",
	"https://raw.githubusercontent.com/Freedom-Guard-Builder/Freedom-Finder/main/out/raw_all.txt",
	"https://raw.githubusercontent.com/LalatinaHub/Mineral/master/result/nodes",
	"https://raw.githubusercontent.com/Leon406/SubCrawler/main/sub/share/hysteria2",
	"https://raw.githubusercontent.com/Leon406/SubCrawler/main/sub/share/vless",
	"https://raw.githubusercontent.com/MatinGhanbari/v2ray-CONFIGs/main/subscriptions/v2ray/all_sub.txt",
	"https://raw.githubusercontent.com/Mosifree/-FREE2CONFIG/main/Reality",
	"https://raw.githubusercontent.com/NiREvil/vless/main/sub/SSTime",
	"https://raw.githubusercontent.com/ShatakVPN/ConfigForge-V2Ray/main/configs/all.txt",
	"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/shadowsocks.txt",
	"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/trojan.txt",
	"https://raw.githubusercontent.com/VPNforWindowsSub/configs/master/full.txt",
	"https://raw.githubusercontent.com/crackbest/V2ray-Config/main/config.txt",
	"https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/main/all_extracted_configs.txt",
	"https://raw.githubusercontent.com/giromo/Collector/main/All_Configs_Sub.txt",
	"https://raw.githubusercontent.com/hamedcode/port-based-v2ray-configs/main/sub/ss.txt",
	"https://raw.githubusercontent.com/hamedcode/port-based-v2ray-configs/main/sub/trojan.txt",
	"https://raw.githubusercontent.com/hamedcode/port-based-v2ray-configs/main/sub/vless.txt",
	"https://raw.githubusercontent.com/hamedcode/port-based-v2ray-configs/main/sub/vmess.txt",
	"https://raw.githubusercontent.com/hamedp-71/Sub_Checker_Creator/main/final.txt",
	"https://raw.githubusercontent.com/itsyebekhe/PSG/main/subscriptions/xray/normal/mix",
	"https://raw.githubusercontent.com/liMilCo/v2r/main/all_configs.txt",
	"https://raw.githubusercontent.com/liketolivefree/kobabi/main/sub_all.txt",
	"https://raw.githubusercontent.com/maimengmeng/mysub/main/valid_content_all.txt",
	"https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/ss.txt",
	"https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/vless.txt",
	"https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/vmess.txt",
	"https://raw.githubusercontent.com/mshojaei77/v2rayAuto/main/telegram/popular_channels",
	"https://raw.githubusercontent.com/nscl5/5/main/configs/all.txt",
	"https://raw.githubusercontent.com/roosterkid/openproxylist/main/V2RAY_RAW.txt",
	"https://raw.githubusercontent.com/sinavm/SVM/main/subscriptions/xray/normal/mix",
	"https://raw.githubusercontent.com/zieng2/wl/main/vless_universal.txt",
}

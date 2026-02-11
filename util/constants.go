package util

type OutboundType map[string]interface{}

type EntryType struct {
	Tag      string
	Raw      string
	Outbound OutboundType
}

var SUBSCRIPTIONS = []string{
	"https://cdn.jsdelivr.net/gh/10ium/V2Hub3@main/merged",
	"https://cdn.jsdelivr.net/gh/10ium/V2rayCollector@main/mixed_iran.txt",
	"https://cdn.jsdelivr.net/gh/10ium/V2rayCollectorLite@main/mixed_iran.txt",
	"https://cdn.jsdelivr.net/gh/10ium/telegram-configs-collector@main/splitted/mixed",
	"https://cdn.jsdelivr.net/gh/4n0nymou3/multi-proxy-config-fetcher@main/configs/proxy_configs.txt",
	"https://cdn.jsdelivr.net/gh/Argh94/V2RayAutoConfig@main/configs/Hysteria2.txt",
	"https://cdn.jsdelivr.net/gh/Argh94/V2RayAutoConfig@main/configs/ShadowSocks.txt",
	"https://cdn.jsdelivr.net/gh/Argh94/V2RayAutoConfig@main/configs/Trojan.txt",
	"https://cdn.jsdelivr.net/gh/Argh94/V2RayAutoConfig@main/configs/Vmess.txt",
	"https://cdn.jsdelivr.net/gh/Created-By/Telegram-Eag1e_YT@main/%40Eag1e_YT",
	"https://cdn.jsdelivr.net/gh/Danialsamadi/v2go@main/AllConfigsSub.txt",
	"https://cdn.jsdelivr.net/gh/F0rc3Run/F0rc3Run@main/Best-Results/proxies.txt",
	"https://cdn.jsdelivr.net/gh/Farid-Karimi/Config-Collector@main/mixed_iran.txt",
	"https://cdn.jsdelivr.net/gh/Firmfox/Proxify@main/v2ray_configs/seperated_by_protocol/other.txt",
	"https://cdn.jsdelivr.net/gh/Firmfox/Proxify@main/v2ray_configs/seperated_by_protocol/shadowsocks.txt",
	"https://cdn.jsdelivr.net/gh/Firmfox/Proxify@main/v2ray_configs/seperated_by_protocol/trojan.txt",
	"https://cdn.jsdelivr.net/gh/Firmfox/Proxify@main/v2ray_configs/seperated_by_protocol/vless.txt",
	"https://cdn.jsdelivr.net/gh/Firmfox/Proxify@main/v2ray_configs/seperated_by_protocol/vmess.txt",
	"https://cdn.jsdelivr.net/gh/Freedom-Guard-Builder/Freedom-Finder@main/out/raw_all.txt",
	"https://cdn.jsdelivr.net/gh/LalatinaHub/Mineral@master/result/nodes",
	"https://cdn.jsdelivr.net/gh/Leon406/SubCrawler@main/sub/share/hysteria2",
	"https://cdn.jsdelivr.net/gh/Leon406/SubCrawler@main/sub/share/vless",
	"https://cdn.jsdelivr.net/gh/MatinGhanbari/v2ray-CONFIGs@main/subscriptions/v2ray/all_sub.txt",
	"https://cdn.jsdelivr.net/gh/Mosifree/-FREE2CONFIG@main/Reality",
	"https://cdn.jsdelivr.net/gh/NiREvil/vless@main/sub/SSTime",
	"https://cdn.jsdelivr.net/gh/ShatakVPN/ConfigForge-V2Ray@main/configs/all.txt",
	"https://cdn.jsdelivr.net/gh/V2RayRoot/V2RayConfig@main/Config/shadowsocks.txt",
	"https://cdn.jsdelivr.net/gh/V2RayRoot/V2RayConfig@main/Config/trojan.txt",
	"https://cdn.jsdelivr.net/gh/VPNforWindowsSub/configs@master/full.txt",
	"https://cdn.jsdelivr.net/gh/crackbest/V2ray-Config@main/config.txt",
	"https://cdn.jsdelivr.net/gh/ebrasha/free-v2ray-public-list@main/all_extracted_configs.txt",
	"https://cdn.jsdelivr.net/gh/expressalaki/ExpressVPN@main/configs.txt",
	"https://cdn.jsdelivr.net/gh/giromo/Collector@main/All_Configs_Sub.txt",
	"https://cdn.jsdelivr.net/gh/hamedcode/port-based-v2ray-configs@main/sub/ss.txt",
	"https://cdn.jsdelivr.net/gh/hamedcode/port-based-v2ray-configs@main/sub/trojan.txt",
	"https://cdn.jsdelivr.net/gh/hamedcode/port-based-v2ray-configs@main/sub/vless.txt",
	"https://cdn.jsdelivr.net/gh/hamedcode/port-based-v2ray-configs@main/sub/vmess.txt",
	"https://cdn.jsdelivr.net/gh/hamedp-71/Sub_Checker_Creator@main/final.txt",
	"https://cdn.jsdelivr.net/gh/itsyebekhe/PSG@main/subscriptions/xray/normal/mix",
	"https://cdn.jsdelivr.net/gh/liMilCo/v2r@main/all_configs.txt",
	"https://cdn.jsdelivr.net/gh/liketolivefree/kobabi@main/sub_all.txt",
	"https://cdn.jsdelivr.net/gh/maimengmeng/mysub@main/valid_content_all.txt",
	"https://cdn.jsdelivr.net/gh/mohamadfg-dev/telegram-v2ray-configs-collector@main/category/ss.txt",
	"https://cdn.jsdelivr.net/gh/mohamadfg-dev/telegram-v2ray-configs-collector@main/category/vless.txt",
	"https://cdn.jsdelivr.net/gh/mohamadfg-dev/telegram-v2ray-configs-collector@main/category/vmess.txt",
	"https://cdn.jsdelivr.net/gh/mshojaei77/v2rayAuto@main/telegram/popular_channels",
	"https://cdn.jsdelivr.net/gh/nscl5/5@main/configs/all.txt",
	"https://cdn.jsdelivr.net/gh/roosterkid/openproxylist@main/V2RAY_RAW.txt",
	"https://cdn.jsdelivr.net/gh/sinavm/SVM@main/subscriptions/xray/normal/mix",
	"https://cdn.jsdelivr.net/gh/zieng2/wl@main/vless_universal.txt",
}

package util

type OutboundType map[string]interface{}

type SeenKeyType struct {
	Ok       bool
	Raw      string
	Outbound OutboundType
}

var DEFAULT_URL_TEST = "https://1.1.1.1/cdn-cgi/trace/"

var SUBSCRIPTIONS = []string{
	"https://raw.githubusercontent.com/sinavm/SVM/main/subscriptions/xray/normal/mix",
	"https://raw.githubusercontent.com/Rayan-Config/C-Sub/main/configs/proxy.txt",
	"https://raw.githubusercontent.com/4n0nymou3/multi-proxy-config-fetcher/main/configs/proxy_configs.txt",
	"https://raw.githubusercontent.com/Mahdi0024/ProxyCollector/master/sub/proxies.txt",
	"https://raw.githubusercontent.com/ALIILAPRO/v2rayNG-Config/main/server.txt",
	"https://raw.githubusercontent.com/darkvpnapp/CloudflarePlus/main/proxy",
	"https://raw.githubusercontent.com/VPNforWindowsSub/configs/master/full.txt",
	"https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/vless.txt",
	"https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/ss.txt",
	"https://raw.githubusercontent.com/miladtahanian/V2RayCFGDumper/main/config.txt",
	"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/shadowsocks.txt",
	"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/trojan.txt",
	"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/vless.txt",
	"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/vmess.txt",
	"https://raw.githubusercontent.com/MatinGhanbari/v2ray-CONFIGs/main/subscriptions/v2ray/all_sub.txt",
	"https://raw.githubusercontent.com/barry-far/V2ray-Config/main/All_Configs_Sub.txt",
	"https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/main/all_configs.txt",
	"https://raw.githubusercontent.com/liMilCo/v2r/main/all_configs.txt",
	"https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/main/all_extracted_configs.txt",
}

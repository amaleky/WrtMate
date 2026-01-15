package util

type OutboundType map[string]interface{}

type SeenKeyType struct {
	Ok       bool
	Tag      string
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
	"https://raw.githubusercontent.com/liketolivefree/kobabi/main/sub.txt",
	"https://raw.githubusercontent.com/hans-thomas/v2ray-subscription/master/servers.txt",
	"https://raw.githubusercontent.com/darkvpnapp/CloudflarePlus/main/proxy",
	"https://raw.githubusercontent.com/VPNforWindowsSub/configs/master/full.txt",
	"https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/vless.txt",
	"https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/ss.txt",
	"https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/wireguard.txt",
	"https://raw.githubusercontent.com/miladtahanian/V2RayCFGDumper/main/config.txt",
	"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/shadowsocks.txt",
	"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/trojan.txt",
	"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/vless.txt",
	"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/vmess.txt",
	"https://raw.githubusercontent.com/MatinGhanbari/v2ray-CONFIGs/main/subscriptions/v2ray/all_sub.txt",
	"https://raw.githubusercontent.com/barry-far/V2ray-Config/main/All_Configs_Sub.txt",
	"https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/main/all_configs.txt",
	"https://raw.githubusercontent.com/Epodonios/v2ray-CONFIGs/main/All_Configs_Sub.txt",
	"https://raw.githubusercontent.com/liMilCo/v2r/main/all_configs.txt",
	"https://raw.githubusercontent.com/mahdibland/V2RayAggregator/master/Eternity",
	"https://raw.githubusercontent.com/peasoft/NoMoreWalls/master/list.txt",
	"https://raw.githubusercontent.com/Surfboardv2ray/TGParse/main/splitted/mixed",
	"https://raw.githubusercontent.com/ermaozi/get_subscribe/main/subscribe/v2ray.txt",
	"https://raw.githubusercontent.com/itsyebekhe/PSG/main/subscriptions/xray/base64/mix",
	"https://raw.githubusercontent.com/roosterkid/openproxylist/main/V2RAY_BASE64.txt",
	"https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mci/sub_1.txt",
	"https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mtn/sub_1.txt",
	"https://raw.githubusercontent.com/R-the-coder/V2ray-configs/main/config.txt",
	"https://raw.githubusercontent.com/Joker-funland/V2ray-configs/main/config.txt",
	"https://raw.githubusercontent.com/AzadNetCH/Clash/main/AzadNet.txt",
	"https://raw.githubusercontent.com/ripaojiedian/freenode/main/sub",
}

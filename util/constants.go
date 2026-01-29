package util

type OutboundType map[string]interface{}

type SeenKeyType struct {
	Ok       bool
	Raw      string
	Outbound OutboundType
}

var DEFAULT_URL_TEST = "https://1.1.1.1/cdn-cgi/trace/"

var SUBSCRIPTIONS = []string{
	"https://raw.githubusercontent.com/10ium/multi-proxy-config-fetcher/main/configs/proxy_configs.txt",
	"https://raw.githubusercontent.com/10ium/telegram-configs-collector/main/splitted/mixed",
	"https://raw.githubusercontent.com/10ium/V2Hub3/main/merged",
	"https://raw.githubusercontent.com/10ium/V2ray-Config/main/All_Configs_Sub.txt",
	"https://raw.githubusercontent.com/10ium/V2RayAggregator/master/Eternity.txt",
	"https://raw.githubusercontent.com/10ium/V2rayCollector/main/mixed_iran.txt",
	"https://raw.githubusercontent.com/4n0nymou3/multi-proxy-config-fetcher/main/configs/proxy_configs.txt",
	"https://raw.githubusercontent.com/ALIILAPRO/v2rayNG-Config/main/server.txt",
	"https://raw.githubusercontent.com/arshiacomplus/robinhood-v1-v2-v3ray/main/conf.txt",
	"https://raw.githubusercontent.com/arshiacomplus/v2rayExtractor/main/mix/sub.html",
	"https://raw.githubusercontent.com/barry-far/V2ray-Config/main/All_Configs_Sub.txt",
	"https://raw.githubusercontent.com/code3-dev/v-data/main/vip",
	"https://raw.githubusercontent.com/crackbest/V2ray-Config/main/config.txt",
	"https://raw.githubusercontent.com/Created-By/Telegram-Eag1e_YT/main/%40Eag1e_YT",
	"https://raw.githubusercontent.com/darkvpnapp/Cloud2/main/aparatapi",
	"https://raw.githubusercontent.com/darkvpnapp/CloudflarePlus/main/cdn",
	"https://raw.githubusercontent.com/darkvpnapp/CloudflarePlus/main/proxy",
	"https://raw.githubusercontent.com/darkvpnapp/cslab/main/index.html",
	"https://raw.githubusercontent.com/darkvpnapp/IRDevs/main/index.html",
	"https://raw.githubusercontent.com/darkvpnapp/safar724/main/api",
	"https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/main/all_extracted_configs.txt",
	"https://raw.githubusercontent.com/Epodonios/v2ray-configs/main/All_Configs_Sub.txt",
	"https://raw.githubusercontent.com/F0rc3Run/F0rc3Run/main/Best-Results/proxies.txt",
	"https://raw.githubusercontent.com/Freedom-Guard-Builder/Freedom-Finder/main/out/raw_all.txt",
	"https://raw.githubusercontent.com/giromo/Collector/main/All_Configs_Sub.txt",
	"https://raw.githubusercontent.com/hamedp-71/Sub_Checker_Creator/main/final.txt",
	"https://raw.githubusercontent.com/itsyebekhe/PSG/main/subscriptions/xray/normal/mix",
	"https://raw.githubusercontent.com/liMilCo/v2r/main/all_configs.txt",
	"https://raw.githubusercontent.com/Mahdi0024/ProxyCollector/master/sub/proxies.txt",
	"https://raw.githubusercontent.com/mahdibland/V2RayAggregator/master/sub/sub_merge.txt",
	"https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mci/sub_1.txt",
	"https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mci/sub_2.txt",
	"https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mci/sub_3.txt",
	"https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mci/sub_4.txt",
	"https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mtn/sub_1.txt",
	"https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mtn/sub_2.txt",
	"https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mtn/sub_3.txt",
	"https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mtn/sub_4.txt",
	"https://raw.githubusercontent.com/MahsaNetConfigTopic/config/main/xray_final.txt",
	"https://raw.githubusercontent.com/maimengmeng/mysub/main/valid_content_all.txt",
	"https://raw.githubusercontent.com/MatinGhanbari/v2ray-CONFIGs/main/subscriptions/v2ray/all_sub.txt",
	"https://raw.githubusercontent.com/miladtahanian/V2RayCFGDumper/main/config.txt",
	"https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/ss.txt",
	"https://raw.githubusercontent.com/mohamadfg-dev/telegram-v2ray-configs-collector/main/category/vless.txt",
	"https://raw.githubusercontent.com/Rayan-Config/C-Sub/main/configs/proxy.txt",
	"https://raw.githubusercontent.com/roosterkid/openproxylist/main/V2RAY_RAW.txt",
	"https://raw.githubusercontent.com/ShatakVPN/ConfigForge-V2Ray/main/configs/all.txt",
	"https://raw.githubusercontent.com/sinavm/SVM/main/subscriptions/xray/normal/mix",
	"https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/main/all_configs.txt",
	"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/shadowsocks.txt",
	"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/trojan.txt",
	"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/vless.txt",
	"https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/main/Config/vmess.txt",
	"https://raw.githubusercontent.com/VPNforWindowsSub/configs/master/full.txt",
	"https://raw.githubusercontent.com/zieng2/wl/main/vless_universal.txt",
}

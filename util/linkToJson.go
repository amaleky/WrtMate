package util

import (
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"strconv"
	"strings"

	"github.com/sagernet/sing-shadowsocks2/shadowaead"
	"github.com/sagernet/sing-shadowsocks2/shadowaead_2022"
	"github.com/sagernet/sing-shadowsocks2/shadowstream"
)

func GetOutbound(line string) (OutboundType, string, error) {
	var outbound OutboundType
	uri, err := ParseLink(line)
	if err != nil || uri == nil {
		return nil, "", err
	}
	switch uri.Scheme {
	case "vmess":
		outbound, err = vmess(uri)
	case "vless":
		outbound, err = vless(uri)
	case "trojan":
		outbound, err = trojan(uri)
	case "hy", "hysteria":
		outbound, err = hy(uri)
	case "hy2", "hysteria2":
		outbound, err = hy2(uri)
	case "anytls":
		outbound, err = anytls(uri)
	case "tuic":
		outbound, err = tuic(uri)
	case "ss", "shadowsocks":
		outbound, err = ss(uri)
	case "socks", "socks5", "socks4", "socks4a":
		outbound, err = socks(uri)
	case "http", "https":
		outbound, err = httpProxy(uri)
	case "wireguard", "wg":
		outbound, err = wireguard(uri)
	case "shadowtls":
		outbound, err = shadowtls(uri)
	case "ssh":
		outbound, err = sshOutbound(uri)
	case "naive":
		outbound, err = naive(uri)
	}
	if err == nil && outbound != nil {
		return outbound, uri.String(), nil
	}
	return nil, "", errors.New("Unsupported protocol scheme: " + uri.Scheme)
}

func isInList(list []string, method string) bool {
	for _, listMethod := range list {
		if listMethod == method {
			return true
		}
	}
	return false
}

func getHostPort(u *url.URL, defaultPort int) (string, int) {
	host := u.Hostname()
	port := defaultPort
	if ps := u.Port(); len(ps) > 0 {
		if p, err := strconv.Atoi(ps); err == nil && p > 0 {
			port = p
		}
	}
	return host, port
}

func vmess(u *url.URL) (OutboundType, error) {
	data := strings.TrimPrefix(u.String(), "vmess://")
	dataByte, err := DecodeBase64IfNeeded(data)
	if err != nil {
		return nil, err
	}
	var dataJson map[string]interface{}
	err = json.Unmarshal([]byte(dataByte), &dataJson)
	if err != nil {
		return nil, err
	}
	transport := map[string]interface{}{}
	tp_net, _ := dataJson["net"].(string)
	tp_type, _ := dataJson["type"].(string)
	tp_host, _ := dataJson["host"].(string)
	tp_path, _ := dataJson["path"].(string)
	switch strings.ToLower(tp_net) {
	case "tcp", "":
		if tp_type == "http" {
			transport["type"] = tp_type
			if len(tp_host) > 0 {
				transport["host"] = strings.Split(tp_host, ",")
			}
			transport["path"] = tp_path
		}
	case "http", "h2":
		transport["type"] = "http"
		if len(tp_host) > 0 {
			transport["host"] = strings.Split(tp_host, ",")
		}
		transport["path"] = tp_path
	case "ws":
		transport["type"] = tp_net
		transport["path"] = tp_path
		transport["early_data_header_name"] = "Sec-WebSocket-Protocol"
		if len(tp_host) > 0 {
			transport["headers"] = map[string]interface{}{
				"Host": tp_host,
			}
		}
	case "quic":
		transport["type"] = tp_net
	case "grpc":
		transport["type"] = tp_net
		transport["service_name"] = tp_path
	case "httpupgrade":
		transport["type"] = tp_net
		transport["path"] = tp_path
		transport["host"] = tp_host
	default:
		return nil, errors.New("Invalid vmess")
	}
	tls := map[string]interface{}{}
	vmess_tls, _ := dataJson["tls"].(string)
	if vmess_tls == "tls" {
		tls["enabled"] = true
		tls_sni, _ := dataJson["sni"].(string)
		tls_alpn, _ := dataJson["alpn"].(string)
		_, tls_insecure := dataJson["allowInsecure"]
		tls_fp, _ := dataJson["fp"].(string)
		if len(tls_sni) > 0 {
			tls["server_name"] = tls_sni
		}
		if len(tls_alpn) > 0 {
			tls["alpn"] = strings.Split(tls_alpn, ",")
		}
		if tls_insecure {
			tls["insecure"] = true
		}
		if len(tls_fp) > 0 {
			tls["utls"] = map[string]interface{}{
				"enabled":     true,
				"fingerprint": tls_fp,
			}
		}
	}
	alter_id := 0
	if aid, ok := dataJson["aid"].(float64); ok {
		alter_id = int(aid)
	}
	var serverPort int
	switch v := dataJson["port"].(type) {
	case string:
		portInt, err := strconv.Atoi(v)
		if err != nil {
			return nil, err
		}
		serverPort = portInt
	case float64:
		serverPort = int(v)
	case int:
		serverPort = v
	default:
		return nil, fmt.Errorf("unsupported port type: %T", v)
	}
	add, ok := dataJson["add"].(string)
	if !ok || len(add) == 0 {
		return nil, errors.New("Invalid vmess: missing add")
	}
	uuid, ok := dataJson["id"].(string)
	if !ok || len(uuid) == 0 {
		return nil, errors.New("Invalid vmess: missing uuid")
	}
	if len(uuid) != 36 || strings.Count(uuid, "-") != 4 {
		return nil, errors.New("Invalid vmess: invalid uuid format")
	}
	tag := "vmess" + "|" + add + "|" + strconv.Itoa(serverPort)
	vmess := OutboundType{
		"type":        "vmess",
		"tag":         tag,
		"server":      add,
		"server_port": serverPort,
		"uuid":        uuid,
		"security":    "auto",
		"alter_id":    alter_id,
		"tls":         tls,
		"transport":   transport,
	}
	return vmess, nil
}

func vless(u *url.URL) (OutboundType, error) {
	query, _ := url.ParseQuery(u.RawQuery)
	security := query.Get("security")
	host := u.Hostname()
	port := 80
	if security == "tls" || security == "reality" {
		port = 443
	}
	if ps := u.Port(); len(ps) > 0 {
		if p, err := strconv.Atoi(ps); err == nil && p > 0 {
			port = p
		}
	}
	tp_type := query.Get("type")
	tag := "vless" + "|" + host + "|" + strconv.Itoa(port)
	tls, err := getTls(security, &query)
	if err != nil {
		return nil, err
	}
	flow := strings.TrimSpace(query.Get("flow"))
	if flow == "xtls-rprx-vision-udp443" {
		flow = "xtls-rprx-vision"
	}
	if !isInList([]string{"", "xtls-rprx-vision"}, flow) {
		return nil, errors.New("Unsupported vless flow: " + flow)
	}
	uuid := u.User.Username()
	if len(uuid) != 36 || strings.Count(uuid, "-") != 4 {
		return nil, errors.New("Invalid vless: invalid uuid format")
	}
	vless := OutboundType{
		"type":        "vless",
		"tag":         tag,
		"server":      host,
		"server_port": port,
		"uuid":        uuid,
		"flow":        flow,
		"tls":         tls,
		"transport":   getTransport(tp_type, &query),
	}
	return vless, nil
}

func trojan(u *url.URL) (OutboundType, error) {
	query, _ := url.ParseQuery(u.RawQuery)
	security := query.Get("security")
	host := u.Hostname()
	port := 80
	if security == "tls" || security == "reality" {
		port = 443
	}
	if ps := u.Port(); len(ps) > 0 {
		if p, err := strconv.Atoi(ps); err == nil && p > 0 {
			port = p
		}
	}
	tp_type := query.Get("type")
	tag := "trojan" + "|" + host + "|" + strconv.Itoa(port)
	tls, err := getTls(security, &query)
	if err != nil {
		return nil, err
	}
	password := u.User.Username()
	if len(password) == 0 {
		return nil, errors.New("Invalid trojan: missing password")
	}
	trojan := OutboundType{
		"type":        "trojan",
		"tag":         tag,
		"server":      host,
		"server_port": port,
		"password":    password,
		"tls":         tls,
		"transport":   getTransport(tp_type, &query),
	}
	return trojan, nil
}

func hy(u *url.URL) (OutboundType, error) {
	query, _ := url.ParseQuery(u.RawQuery)
	host, port := getHostPort(u, 443)
	tls := map[string]interface{}{
		"enabled":     true,
		"server_name": query.Get("peer"),
	}
	alpn := query.Get("alpn")
	insecure := query.Get("insecure")
	if len(alpn) > 0 {
		tls["alpn"] = strings.Split(alpn, ",")
	}
	if insecure == "1" || insecure == "true" {
		tls["insecure"] = true
	}
	tag := "hysteria" + "|" + host + "|" + strconv.Itoa(port)
	hy := OutboundType{
		"type":        "hysteria",
		"tag":         tag,
		"server":      host,
		"server_port": port,
		"obfs":        query.Get("obfsParam"),
		"auth_str":    query.Get("auth"),
		"tls":         tls,
	}
	down, _ := strconv.Atoi(query.Get("downmbps"))
	up, _ := strconv.Atoi(query.Get("upmbps"))
	recv_window_conn, _ := strconv.Atoi(query.Get("recv_window_conn"))
	recv_window, _ := strconv.Atoi(query.Get("recv_window"))
	if down > 0 {
		hy["down_mbps"] = down
	}
	if up > 0 {
		hy["up_mbps"] = up
	}
	if recv_window_conn > 0 {
		hy["recv_window_conn"] = recv_window_conn
	}
	if recv_window > 0 {
		hy["recv_window"] = recv_window
	}
	return hy, nil
}

func hy2(u *url.URL) (OutboundType, error) {
	query, _ := url.ParseQuery(u.RawQuery)
	host, port := getHostPort(u, 443)
	tls := map[string]interface{}{
		"enabled":     true,
		"server_name": query.Get("sni"),
	}
	alpn := query.Get("alpn")
	insecure := query.Get("insecure")
	if len(alpn) > 0 {
		tls["alpn"] = strings.Split(alpn, ",")
	}
	if insecure == "1" || insecure == "true" {
		tls["insecure"] = true
	}
	tag := "hysteria2" + "|" + host + "|" + strconv.Itoa(port)
	hy2 := OutboundType{
		"type":        "hysteria2",
		"tag":         tag,
		"server":      host,
		"server_port": port,
		"password":    u.User.Username(),
		"tls":         tls,
	}
	down, _ := strconv.Atoi(query.Get("downmbps"))
	up, _ := strconv.Atoi(query.Get("upmbps"))
	obfs := query.Get("obfs")
	if down > 0 {
		hy2["down_mbps"] = down
	}
	if up > 0 {
		hy2["up_mbps"] = up
	}
	if obfs == "salamander" {
		hy2["obfs"] = map[string]interface{}{
			"type":     "salamander",
			"password": query.Get("obfs-password"),
		}
		if len(query.Get("obfs-password")) == 0 {
			return nil, errors.New("Missing hysteria2 obfs password")
		}
	}
	return hy2, nil
}

func anytls(u *url.URL) (OutboundType, error) {
	query, _ := url.ParseQuery(u.RawQuery)
	host, port := getHostPort(u, 443)
	tls := map[string]interface{}{
		"enabled":     true,
		"server_name": query.Get("sni"),
	}
	alpn := query.Get("alpn")
	insecure := query.Get("insecure")
	if len(alpn) > 0 {
		tls["alpn"] = strings.Split(alpn, ",")
	}
	if insecure == "1" || insecure == "true" {
		tls["insecure"] = true
	}
	tag := "anytls" + "|" + host + "|" + strconv.Itoa(port)
	anytls := OutboundType{
		"type":        "anytls",
		"tag":         tag,
		"server":      host,
		"server_port": port,
		"password":    u.User.Username(),
		"tls":         tls,
	}
	return anytls, nil
}

func tuic(u *url.URL) (OutboundType, error) {
	query, _ := url.ParseQuery(u.RawQuery)
	host, port := getHostPort(u, 443)
	tls := map[string]interface{}{
		"enabled":     true,
		"server_name": query.Get("sni"),
	}
	alpn := query.Get("alpn")
	insecure := query.Get("allow_insecure")
	disable_sni := query.Get("disable_sni")
	if len(alpn) > 0 {
		tls["alpn"] = strings.Split(alpn, ",")
	}
	if insecure == "1" || insecure == "true" {
		tls["insecure"] = true
	}
	if disable_sni == "1" || disable_sni == "true" {
		tls["disable_sni"] = true
	}
	tag := "tuic" + "|" + host + "|" + strconv.Itoa(port)
	uuid := u.User.Username()
	if len(uuid) != 36 || strings.Count(uuid, "-") != 4 {
		return nil, errors.New("Invalid tuic: invalid uuid format")
	}
	password, _ := u.User.Password()
	tuic := OutboundType{
		"type":               "tuic",
		"tag":                tag,
		"server":             host,
		"server_port":        port,
		"uuid":               uuid,
		"password":           password,
		"congestion_control": query.Get("congestion_control"),
		"udp_relay_mode":     query.Get("udp_relay_mode"),
		"tls":                tls,
	}
	return tuic, nil
}

func ss(u *url.URL) (OutboundType, error) {
	query, _ := url.ParseQuery(u.RawQuery)
	if len(query.Get("ech")) > 0 {
		return nil, errors.New("shadowsocks does not support ECH")
	}
	host, port := getHostPort(u, 443)
	method := strings.TrimSpace(u.User.Username())
	password, ok := u.User.Password()
	if !ok {
		decrypted, err := DecodeBase64IfNeeded(method)
		if err != nil {
			return nil, fmt.Errorf("failed to decode base64: %w", err)
		}
		decrypted_arr := strings.Split(decrypted, ":")
		if len(decrypted_arr) > 1 {
			method = strings.TrimSpace(decrypted_arr[0])
			password = strings.Join(decrypted_arr[1:], ":")
			if len(password) == 0 {
				return nil, errors.New("Missing shadowsocks password")
			}
		} else {
			return nil, errors.New("Unsupported shadowsocks format")
		}
	}
	method = strings.ToLower(strings.TrimSpace(method))
	if isInList([]string{"chacha20-poly1305", "chacha20"}, method) {
		method = "chacha20-ietf-poly1305"
	}
	if !isInList(shadowaead.MethodList, method) && !isInList(shadowstream.MethodList, method) && !isInList(shadowaead_2022.MethodList, method) {
		return nil, errors.New("Unsupported shadowsocks method")
	}
	tag := "shadowsocks" + "|" + host + "|" + strconv.Itoa(port)
	ss := OutboundType{
		"type":        "shadowsocks",
		"tag":         tag,
		"server":      host,
		"server_port": port,
		"method":      method,
		"password":    password,
	}

	v2ray_type := query.Get("type")
	if len(v2ray_type) > 0 {
		pl_arr := []string{}
		host_header := query.Get("host")
		if query.Get("security") == "tls" {
			pl_arr = append(pl_arr, "tls")
		}
		if v2ray_type == "quic" {
			pl_arr = append(pl_arr, "mode=quic")
		}
		if len(host_header) > 0 {
			pl_arr = append(pl_arr, "host="+host_header)
		}
		ss["plugin"] = "v2ray-plugin"
		ss["plugin_opts"] = strings.TrimSpace(strings.Join(pl_arr, ";"))
	}
	plugin := query.Get("plugin")
	if len(plugin) > 0 {
		pl_arr := strings.Split(plugin, ";")
		if len(pl_arr) > 0 {
			ss["plugin"] = pl_arr[0]
			ss["plugin_opts"] = strings.TrimSpace(strings.Join(pl_arr[1:], ";"))
		}
	}

	if ss["plugin_opts"] != nil {
		if pluginOpts, ok := ss["plugin_opts"].(string); ok && len(pluginOpts) > 0 {
			_, err := strconv.Atoi(pluginOpts)
			if err != nil {
				return nil, fmt.Errorf("unable to parse mux value '%s': %w", pluginOpts, err)
			}
		}
	}

	return ss, nil
}

func socks(u *url.URL) (OutboundType, error) {
	query, _ := url.ParseQuery(u.RawQuery)
	host, port := getHostPort(u, 1080)
	tag := "socks" + "|" + host + "|" + strconv.Itoa(port)
	socks := OutboundType{
		"type":        "socks",
		"tag":         tag,
		"server":      host,
		"server_port": port,
	}
	username := ""
	password := ""
	if u.User != nil {
		username = u.User.Username()
		password, _ = u.User.Password()
	}
	if len(username) > 0 {
		socks["username"] = username
	}
	if len(password) > 0 {
		socks["password"] = password
	}
	version := strings.TrimSpace(query.Get("version"))
	switch strings.ToLower(u.Scheme) {
	case "socks4":
		version = "4"
	case "socks4a":
		version = "4a"
	case "socks5", "socks":
		if version == "" {
			version = "5"
		}
	}
	if len(version) > 0 {
		socks["version"] = version
	}
	return socks, nil
}

func httpProxy(u *url.URL) (OutboundType, error) {
	query, _ := url.ParseQuery(u.RawQuery)
	host, port := getHostPort(u, 80)
	tag := "http" + "|" + host + "|" + strconv.Itoa(port)
	http := OutboundType{
		"type":        "http",
		"tag":         tag,
		"server":      host,
		"server_port": port,
	}
	username := ""
	password := ""
	if u.User != nil {
		username = u.User.Username()
		password, _ = u.User.Password()
	}
	if len(username) > 0 {
		http["username"] = username
	}
	if len(password) > 0 {
		http["password"] = password
	}
	security := strings.TrimSpace(query.Get("security"))
	if query.Get("tls") == "1" || query.Get("tls") == "true" || strings.EqualFold(u.Scheme, "https") {
		security = "tls"
	}
	if security == "tls" {
		tls, err := getTls("tls", &query)
		if err != nil {
			return nil, err
		}
		http["tls"] = tls
	}
	return http, nil
}

func wireguard(u *url.URL) (OutboundType, error) {
	query, _ := url.ParseQuery(u.RawQuery)
	host, port := getHostPort(u, 51820)
	tag := "wireguard" + "|" + host + "|" + strconv.Itoa(port)
	privateKey := strings.TrimSpace(query.Get("private_key"))
	if privateKey == "" {
		privateKey = strings.TrimSpace(u.User.Username())
	}
	peerPublicKey := strings.TrimSpace(query.Get("peer_public_key"))
	if peerPublicKey == "" {
		peerPublicKey = strings.TrimSpace(query.Get("public_key"))
	}
	if privateKey == "" || peerPublicKey == "" {
		return nil, errors.New("wireguard requires private_key and peer_public_key")
	}
	wireguard := OutboundType{
		"type":            "wireguard",
		"tag":             tag,
		"server":          host,
		"server_port":     port,
		"private_key":     privateKey,
		"peer_public_key": peerPublicKey,
	}
	preSharedKey := strings.TrimSpace(query.Get("pre_shared_key"))
	if preSharedKey == "" {
		preSharedKey = strings.TrimSpace(query.Get("psk"))
	}
	if preSharedKey != "" {
		wireguard["pre_shared_key"] = preSharedKey
	}
	localAddress := strings.TrimSpace(query.Get("local_address"))
	if localAddress == "" {
		localAddress = strings.TrimSpace(query.Get("address"))
	}
	if localAddress != "" {
		wireguard["local_address"] = strings.Split(localAddress, ",")
	}
	mtu, _ := strconv.Atoi(query.Get("mtu"))
	if mtu > 0 {
		wireguard["mtu"] = mtu
	}
	reservedRaw := strings.TrimSpace(query.Get("reserved"))
	if reservedRaw != "" {
		parts := strings.Split(reservedRaw, ",")
		reserved := make([]int, 0, len(parts))
		for _, part := range parts {
			value, err := strconv.Atoi(strings.TrimSpace(part))
			if err != nil {
				return nil, errors.New("wireguard reserved must be comma-separated integers")
			}
			reserved = append(reserved, value)
		}
		wireguard["reserved"] = reserved
	}
	return wireguard, nil
}

func shadowtls(u *url.URL) (OutboundType, error) {
	query, _ := url.ParseQuery(u.RawQuery)
	host, port := getHostPort(u, 443)
	tag := "shadowtls" + "|" + host + "|" + strconv.Itoa(port)
	username := ""
	password := ""
	if u.User != nil {
		username = u.User.Username()
		password, _ = u.User.Password()
	}
	username = strings.TrimSpace(username)
	password = strings.TrimSpace(password)
	if password == "" {
		password = username
	}
	if password == "" {
		password = strings.TrimSpace(query.Get("password"))
	}
	if password == "" {
		return nil, errors.New("shadowtls requires password")
	}
	version := strings.TrimSpace(query.Get("version"))
	if version == "" {
		version = "3"
	}
	tls, err := getTls("tls", &query)
	if err != nil {
		return nil, err
	}
	shadowtls := OutboundType{
		"type":        "shadowtls",
		"tag":         tag,
		"server":      host,
		"server_port": port,
		"version":     version,
		"password":    password,
		"tls":         tls,
	}
	return shadowtls, nil
}

func sshOutbound(u *url.URL) (OutboundType, error) {
	query, _ := url.ParseQuery(u.RawQuery)
	host, port := getHostPort(u, 22)
	tag := "ssh" + "|" + host + "|" + strconv.Itoa(port)
	ssh := OutboundType{
		"type":        "ssh",
		"tag":         tag,
		"server":      host,
		"server_port": port,
	}
	username := ""
	password := ""
	if u.User != nil {
		username = u.User.Username()
		password, _ = u.User.Password()
	}
	username = strings.TrimSpace(username)
	if username == "" {
		username = strings.TrimSpace(query.Get("user"))
	}
	if len(username) > 0 {
		ssh["user"] = username
	}
	if len(password) > 0 {
		ssh["password"] = password
	}
	privateKey := strings.TrimSpace(query.Get("private_key"))
	if privateKey != "" {
		ssh["private_key"] = privateKey
	}
	privateKeyPath := strings.TrimSpace(query.Get("private_key_path"))
	if privateKeyPath != "" {
		ssh["private_key_path"] = privateKeyPath
	}
	hostKey := strings.TrimSpace(query.Get("host_key"))
	if hostKey != "" {
		ssh["host_key"] = hostKey
	}
	hostKeyAlgorithms := strings.TrimSpace(query.Get("host_key_algorithms"))
	if hostKeyAlgorithms != "" {
		ssh["host_key_algorithms"] = strings.Split(hostKeyAlgorithms, ",")
	}
	return ssh, nil
}

func naive(u *url.URL) (OutboundType, error) {
	query, _ := url.ParseQuery(u.RawQuery)
	host, port := getHostPort(u, 443)
	tag := "naive" + "|" + host + "|" + strconv.Itoa(port)
	username := ""
	password := ""
	if u.User != nil {
		username = u.User.Username()
		password, _ = u.User.Password()
	}
	if username == "" || password == "" {
		return nil, errors.New("naive requires username and password")
	}
	tls, err := getTls("tls", &query)
	if err != nil {
		return nil, err
	}
	naive := OutboundType{
		"type":        "naive",
		"tag":         tag,
		"server":      host,
		"server_port": port,
		"username":    username,
		"password":    password,
		"tls":         tls,
	}
	return naive, nil
}

func getTransport(tp_type string, q *url.Values) map[string]interface{} {
	transport := map[string]interface{}{}
	tp_host := q.Get("host")
	tp_path := q.Get("path")
	switch strings.ToLower(tp_type) {
	case "tcp", "":
		if q.Get("headerType") == "http" {
			transport["type"] = "http"
			if len(tp_host) > 0 {
				transport["host"] = strings.Split(tp_host, ",")
			}
			transport["path"] = tp_path
		}
	case "http", "h2":
		transport["type"] = "http"
		if len(tp_host) > 0 {
			transport["host"] = strings.Split(tp_host, ",")
		}
		transport["path"] = tp_path
	case "ws":
		transport["type"] = "ws"
		transport["path"] = tp_path
		if len(tp_host) > 0 {
			transport["headers"] = map[string]interface{}{"Host": tp_host}
		}
		eh := q.Get("eh")
		if len(eh) == 0 {
			eh = "Sec-WebSocket-Protocol"
		}
		ed := q.Get("ed")
		if len(ed) > 0 {
			if n, err := strconv.Atoi(ed); err == nil && n > 0 {
				transport["max_early_data"] = n
				transport["early_data_header_name"] = eh
			}
		}
	case "quic":
		transport["type"] = "quic"
	case "grpc":
		transport["type"] = "grpc"
		transport["service_name"] = q.Get("serviceName")
	case "httpupgrade":
		transport["type"] = "httpupgrade"
		transport["path"] = tp_path
		transport["host"] = tp_host
	}
	return transport
}

func getTls(security string, q *url.Values) (map[string]interface{}, error) {
	tls := map[string]interface{}{}
	tls_fp := q.Get("fp")
	tls_sni := q.Get("sni")
	tls_insecure := q.Get("allowInsecure")
	tls_alpn := q.Get("alpn")
	tls_ech := q.Get("ech")
	switch security {
	case "tls":
		tls["enabled"] = true
	case "reality":
		pbk := strings.TrimSpace(q.Get("pbk"))
		sid := strings.TrimSpace(q.Get("sid"))
		if len(pbk) == 0 {
			return nil, errors.New("reality requires public_key")
		}
		pkBytes, err := base64.RawURLEncoding.DecodeString(pbk)
		if err != nil || len(pkBytes) != 32 {
			return nil, errors.New("reality public_key (pbk) must be base64url")
		}
		if len(sid) > 0 {
			if len(sid)%2 != 0 {
				return nil, errors.New("reality short_id must be even-length hex")
			}
			if _, err := hex.DecodeString(sid); err != nil {
				return nil, errors.New("reality short_id must be hex")
			}
		}
		tls["enabled"] = true
		tls["reality"] = map[string]interface{}{
			"enabled":    true,
			"public_key": pbk,
			"short_id":   sid,
		}
	}
	if len(tls_sni) > 0 {
		tls["server_name"] = tls_sni
	}
	if len(tls_alpn) > 0 {
		tls["alpn"] = strings.Split(tls_alpn, ",")
	}
	if tls_insecure == "1" || tls_insecure == "true" {
		tls["insecure"] = true
	}
	if len(tls_fp) > 0 || security == "reality" {
		fingerprint := tls_fp
		if !isInList([]string{"", "chrome", "firefox", "edge", "safari", "360", "qq", "ios", "android"}, fingerprint) {
			fingerprint = "chrome"
		}
		tls["utls"] = map[string]interface{}{
			"enabled":     true,
			"fingerprint": fingerprint,
		}
	}
	if len(tls_ech) > 0 {
		echBytes, err := base64.StdEncoding.DecodeString(tls_ech)
		if err != nil {
			return nil, errors.New("Invalid ECH config: must be valid base64")
		}
		if len(echBytes) == 0 {
			return nil, errors.New("Invalid ECH config: empty after decoding")
		}
		tls["ech"] = map[string]interface{}{
			"enabled": true,
			"config": []string{
				tls_ech,
			},
		}
	}
	return tls, nil
}

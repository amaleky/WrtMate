#!/bin/sh

if [ -f "/tmp/passwall_install.lock" ]; then
  echo "Passwall is installing. Exiting url-test."
  exit 0
fi

test_socks_port() {
  SOCKS_PORT=$1
  URL=$2
  if curl -s -L -I --max-time 5 --retry 3 --socks5-hostname "127.0.0.1:$SOCKS_PORT" -o "/dev/null" "$URL"; then
    return 0
  else
    return 1
  fi
}

test_serverless() {
  SERVICE="serverless"
  SERVERLESS_CONFIG="/root/xray/serverless.json"
  SERVERLESS_SUBSCRIPTION="/root/xray/subscription.json"

  if ! /etc/init.d/"$SERVICE" enabled; then
    return
  fi

  if test_socks_port "10808" "https://www.youtube.com"; then
    echo "✅ serverless connectivity test passed"
  else
    i=0
    while [ "$i" -lt "$(jq 'length' "$SERVERLESS_SUBSCRIPTION")" ]; do
      jq ".[$i]" "$SERVERLESS_SUBSCRIPTION" > "$SERVERLESS_CONFIG"
      echo "Testing serverless [$(jq -r '.remarks' "$SERVERLESS_CONFIG")]"
      /etc/init.d/"$SERVICE" restart
      sleep 5
      if test_socks_port "10808" "https://www.youtube.com"; then
        echo "✅ serverless connectivity test passed"
        break
      fi
      i=$((i + 1))
    done
  fi
}

test_psiphon() {
  SERVICE="psiphon"
  NODE="Psiphon"
  PSIPHON_CONFIG="/root/psiphon/client.config"

  if ! /etc/init.d/"$SERVICE" enabled; then
    return
  fi

  if test_socks_port "9804" "https://1.1.1.1/cdn-cgi/trace/"; then
    echo "✅ $NODE connectivity test passed"
    return
  fi

  echo "❌ $NODE connectivity test failed"

  set -- AT AU BE CA CH CZ DE DK ES FR GB ID IN IT JP LT NL NO PL RO RS SE SG US
  REGION_INDEX=$(awk 'BEGIN { srand(); print int(rand() * 24) + 1 }')
  shift $((REGION_INDEX - 1))
  EGRESS_REGION="$1"

  if jq --arg region "$EGRESS_REGION" '.EgressRegion = $region' "$PSIPHON_CONFIG" >"${PSIPHON_CONFIG}.tmp"; then
    mv "${PSIPHON_CONFIG}.tmp" "$PSIPHON_CONFIG"
    echo "Changing $NODE egress region to $EGRESS_REGION"
    /etc/init.d/"$SERVICE" restart
  fi
}

test_service() {
  SERVICE="$1"
  NODE="$2"
  PORT="$3"

  if ! /etc/init.d/"$SERVICE" enabled; then
    return
  fi

  if test_socks_port "$PORT" "https://1.1.1.1/cdn-cgi/trace/"; then
    echo "✅ $NODE connectivity test passed"
  else
    echo "❌ $NODE connectivity test failed"
    case "$SERVICE" in
      warp-plus) rm -rfv /.cache/warp-plus ;;
      ssh-proxy) rm -fv /root/.ssh/known_hosts ;;
    esac
    /etc/init.d/"$SERVICE" restart
  fi
}

main() {
  test_service "scanner" "Scanner" 9802
  test_service "warp-plus" "WarpPlus" 9803
  test_service "tor" "Tor" 9805
  test_service "ssh-proxy" "SshProxy" 9806
  test_psiphon
  test_serverless
}

main "$@"

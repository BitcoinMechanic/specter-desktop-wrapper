#!/bin/bash
set -a 
_term() { 
  echo "Caught SIGTERM signal!" 
  kill -TERM "$specter_process" 2>/dev/null
}
# Setting variables
echo "Configuring Specter..."
BTC_RPC_PROTOCOL=http
BTC_RPC_TYPE="$(yq e '.bitcoind.type' /root/start9/config.yaml)"
BTC_RPC_USER="$(yq e '.bitcoind.user' /root/start9/config.yaml)"
BTC_RPC_PASSWORD="$(yq e '.bitcoind.password' /root/start9/config.yaml)"
if [ "$BTC_RPC_TYPE" = "internal-proxy" ]; then
	export BTC_RPC_HOST="btc-rpc-proxy.embassy"
	echo "Running on Bitcoin Proxy..."
else
	export BTC_RPC_HOST="bitcoind.embassy"
	echo "Running on Bitcoin Core..."
fi
echo "Starting Specter..."
export BTC_RPC_PROTOCOL=$BTC_RPC_PROTOCOL
export BTC_RPC_HOST=$BTC_RPC_HOST
export BTC_RPC_USER=$BTC_RPC_USER
export BTC_RPC_PASSWORD=$BTC_RPC_PASSWORD
export BTC_RPC_PORT=8332


python3 -m cryptoadvance.specter server --host specter.embassy

trap _term SIGTERM
wait -n $specter_process

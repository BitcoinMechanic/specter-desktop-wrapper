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
#if [ "$BTC_RPC_TYPE" = "internal-proxy" ]; then
#	export BTC_RPC_HOST="btc-rpc-proxy.embassy"
#	echo "Running on Bitcoin Proxy..."
#else

export BTC_RPC_HOST="bitcoind.embassy"
#echo "Running on Bitcoin Core..."
#fi
export ELECTRUM_HOST="electrs.embassy"
echo $ELECTRUM_HOST
export ELECTRUM_PORT=50001
echo $ELECTRUM_PORT
echo "Running on Electrs on port 50001"

echo "Starting Specter..."
export BTC_RPC_PORT=8332


exec python3 -m cryptoadvance.specter server --host specter.embassy


#!/usr/bin/env bash
# Starts ERC-20 in RESTgym: see /infrastructure/api/restgym-api.sh

source /infrastructure/api/restgym-api.sh

# Proxy script: replaces the valid addresses of unknown contracts in the requests with that of the test contract (see the README)
RESTGYM_PROXY_SCRIPTS=(/api/rewrite-contract-address.py)

# Ganache, a local Ethereum blockchain
restgym_start_service Ganache ganache --wallet.deterministic --wallet.totalAccounts 10 --wallet.defaultBalance 100 \
    --chain.networkId 1337 --server.host 0.0.0.0 --server.port 8545
restgym_wait_for_port Ganache 8545

# Deploy a test contract through the API, before tools can reach it. Without it, the operations on contracts would only
# fail: the container stops (a startup failure), and RESTgym runs the run again
restgym_on_api_ready() {
    python3 /api/init-contract.py || restgym_fail "The deployment of the test contract failed."
    restgym_log "Test contract deployed."
}

restgym_run_api 8080 \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.12-runtime.jar=includes=*,output=tcpserver,port=12345,address=* \
        -Dfile.encoding=UTF-8 \
        -Dserver.port=8080 \
        -DnodeEndpoint=http://localhost:8545 \
        -DfromAddress=0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1 \
        -jar /api/erc20-rest-service-0.1.0.jar

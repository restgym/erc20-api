#!/usr/bin/env bash
# Starts ERC-20 in RESTgym: see /infrastructure/api/restgym-api.sh

source /infrastructure/api/restgym-api.sh

RESTGYM_PROXY_SCRIPTS=(/api/auth.py)

# Ganache, a local Ethereum blockchain
restgym_start_service Ganache ganache --wallet.deterministic --wallet.totalAccounts 10 --wallet.defaultBalance 100 \
    --chain.networkId 1337 --server.host 0.0.0.0 --server.port 8545
restgym_wait_for_port Ganache 8545

# Deploy a test contract through the API, before tools can reach it
restgym_on_api_ready() {
    if python3 /api/init-contract.py; then
        restgym_log "Test contract deployed."
    else
        restgym_log "WARNING: the deployment of the test contract failed: tests may have limited coverage."
    fi
}

restgym_run_api 8080 \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=*,output=tcpserver,port=12345,address=* \
        -Dfile.encoding=UTF-8 \
        -Dserver.port=8080 \
        -DnodeEndpoint=http://localhost:8545 \
        -DfromAddress=0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1 \
        -jar /api/app.jar

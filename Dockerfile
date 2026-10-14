# ERC-20 REST service
# Base image: Ubuntu 22.04, Java 17 (headless JRE), mitmproxy and the RESTgym infrastructure (see infrastructure/api/Dockerfile)
FROM restgym/api-base:java17

# Ganache (a local Ethereum blockchain), with Node.js 18.20.8 from the repository of NodeSource (which serves all the
# versions). Ganache pins its own dependencies (npm-shrinkwrap.json)
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl gnupg \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs=18.20.8-1nodesource1 \
    && npm install -g ganache@7.9.1 \
    && rm -rf /var/lib/apt/lists/* /root/.npm

# The API: its executable, the classes for code coverage, its specifications and scripts
COPY ./apis/erc20/ /api/

# Startup script (in /api): starts the API, the collection of code coverage and the proxy (see infrastructure/api/restgym-api.sh)
ENTRYPOINT ["bash", "/api/entrypoint.sh"]

FROM ubuntu:22.04

ENV API=erc20
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}

RUN mkdir /api && \
    mkdir /infrastructure && \
    mkdir /results && \
    apt update && \
    apt -y upgrade && \
    apt -y install openjdk-17-jdk python3 python3-pip curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt -y install nodejs && \
    apt -y autoremove && \
    pip3 install mitmproxy requests && \
    npm install -g ganache@7.9.1

COPY ./apis/erc20/erc20-rest-service-0.1.0.jar /api/app.jar
COPY ./apis/erc20/classes/ /api/classes/
COPY ./apis/erc20/init-contract.py /api/init-contract.py
COPY ./apis/erc20/auth.py /api/auth.py

# Copy OpenAPI specifications for test generation
COPY ./apis/erc20/specifications/ /api/specifications/

COPY ./infrastructure/ /infrastructure/

EXPOSE 9090 12345 8080 8545

# Startup script: starts the API, the collection of code coverage and the proxy (see infrastructure/api/restgym-api.sh)
COPY ./apis/erc20/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["bash", "/entrypoint.sh"]

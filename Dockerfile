FROM debian:stable-slim AS base

ENV DEBIAN_FRONTEND=noninteractive
# COPY --chmod=700 build/ /tmp/build/
ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
ENV GH_RUNNER_VERSION=2.336.0
WORKDIR /actions-runner
RUN |2 GH_RUNNER_VERSION={GH_RUNNER_VERSION} TARGETPLATFORM=linux/amd64 /bin/bash -o pipefail -c chmod +x /token.sh /entrypoint.sh /app_token.sh # buildkit

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    lttng-ust \
    libkrb5-3 \
    zlib1g \
    libssl3 \
    libicu80 \
    curl \
    openssl-libs

ENTRYPOINT ["/entrypoint.sh"]
CMD ["./bin/Runner.Listener" "run" "--startuptype" "service"]
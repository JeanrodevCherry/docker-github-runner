FROM debian:stable-slim AS base

LABEL maintainer="jean-robin.peiteado@cherrybiotech.com"
ENV DEBIAN_FRONTEND=noninteractive
ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
ENV GH_RUNNER_VERSION=2.336.0
WORKDIR /actions-runner


RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    liblttng-ctl-dev \
    libkrb5-3 \
    zlib1g \
    libssl3 \
    libicu-dev \
    curl \
    libssl3 \
    sudo \
    docker-cli \
    gpg

#Install side
COPY install_actions.sh /actions-runner
RUN chmod +x /actions-runner/install_actions.sh \
  && /actions-runner/install_actions.sh ${GH_RUNNER_VERSION} ${TARGETPLATFORM} \
  && rm /actions-runner/install_actions.sh \
  && chown -R runner /_work /actions-runner 
#/opt/hostedtoolcache

COPY entrypoint.sh /
RUN chmod a+x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["./bin/Runner.Listener" "run" "--startuptype" "service"]
#!/bin/bash -ex
GH_RUNNER_VERSION=$1
TARGETPLATFORM=$2

_USERID="1001"
_GROUPID="121"
# docker-group-id=500
export TARGET_ARCH="x64"
if [[ $TARGETPLATFORM == "linux/arm64" ]]; then
  export TARGET_ARCH="arm64"
fi

# install docker
function configure_docker() {
  # shellcheck source=/dev/null
  source /etc/os-release

  mkdir -p /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/$ID/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  local version DPKG_ARCH
  version=$(echo "$VERSION_CODENAME" | sed 's/trixie\|n\/a/bookworm/g')
  DPKG_ARCH="$(dpkg --print-architecture)"
  echo "deb [arch=${DPKG_ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID ${version} stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null
}
apt-get update && apt-get install -y docker.io

function setup_sudoers() {
  sed -e 's/Defaults.*env_reset/Defaults env_keep = "HTTP_PROXY HTTPS_PROXY NO_PROXY FTP_PROXY http_proxy https_proxy no_proxy ftp_proxy"/' -i /etc/sudoers
  echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
}
configure_docker
_DOCKER_GID=$(getent group docker | awk -F: '{print $3}')
echo "Docker group ID: ${_DOCKER_GROUPID}"
# groupadd -g ${_DOCKER_GROUPID} docker
setup_sudoers
# groupadd -g ${_DOCKER_GID} runner
useradd -mr -d /home/runner -u ${_USERID} -g ${_DOCKER_GID} runner
usermod -aG sudo runner
usermod -aG docker runner

curl -L "https://github.com/actions/runner/releases/download/v${GH_RUNNER_VERSION}/actions-runner-linux-${TARGET_ARCH}-${GH_RUNNER_VERSION}.tar.gz" > actions.tar.gz
tar -zxf actions.tar.gz
rm -f actions.tar.gz
# ./bin/installdependencies.sh
mkdir -p /_work
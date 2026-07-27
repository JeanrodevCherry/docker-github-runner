#!/bin/bash
#Setup vars
export RUNNER_ALLOW_RUNASROOT=1
export PATH=${PATH}:/actions-runner

# Un-export these, so that they must be passed explicitly to the environment of
# any command that needs them.  This may help prevent leaks.
export -n ACCESS_TOKEN
export -n GITHUB_RUNNER_TOKEN
export -n APP_ID
export -n APP_PRIVATE_KEY



_RANDOM_RUNNER_SUFFIX=${RANDOM_RUNNER_SUFFIX:="true"}
_RUNNER_NAME=${RUNNER_NAME:-${RUNNER_NAME_PREFIX:-github-runner}-$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')}
_RUNNER_WORKDIR_ROOT=${RUNNER_WORKDIR_ROOT:-/_work}
_RUNNER_WORKDIR=${RUNNER_WORKDIR:-${_RUNNER_WORKDIR_ROOT}/${_RUNNER_NAME}}
_LABELS=${RUNNER_LABELS:-${LABELS:-default}}
_RUNNER_GROUP=${RUNNER_GROUP:-Default}
_GITHUB_HOST=${GITHUB_HOST:="github.com"}
_GITHUB_HOST="${_GITHUB_HOST#http://}"
_GITHUB_HOST="${_GITHUB_HOST#https://}"
_GITHUB_HOST="${_GITHUB_HOST%%/}"
_RUN_AS_ROOT=${RUN_AS_ROOT:="true"}
_START_DOCKER_SERVICE=${START_DOCKER_SERVICE:="true"}
_UNSET_CONFIG_VARS=${UNSET_CONFIG_VARS:="false"}
_CONFIGURED_ACTIONS_RUNNER_FILES_DIR=${CONFIGURED_ACTIONS_RUNNER_FILES_DIR:-""}

_RUNNER_SCOPE="repo"
RUNNER_SCOPE="${RUNNER_SCOPE,,}" # to lowercase

# Run docker (it is needed)
#actually running the configuration
configure_runner() {
  ARGS=()
  if [ -n "${EPHEMERAL}" ]; then
    echo "Ephemeral option is enabled"
    ARGS+=("--ephemeral")
  fi

  if [ -n "${DISABLE_AUTO_UPDATE}" ]; then
    echo "Disable auto update option is enabled"
    ARGS+=("--disableupdate")
  fi

  if [ -n "${NO_DEFAULT_LABELS}" ]; then
    echo "Disable adding the default self-hosted, platform, and architecture labels"
    ARGS+=("--no-default-labels")
  fi
  # echo "Configuring With ${_SHORT_URL} ${GITHUB_RUNNER_TOKEN} ${_RUNNER_NAME} ${_RUNNER_WORKDIR} ${_LABELS} ${_RUNNER_GROUP}"
  ./config.sh \
      --url "${_SHORT_URL}" \
      --token "${GITHUB_RUNNER_TOKEN}" \
      --name "${_RUNNER_NAME}" \
      --work "${_RUNNER_WORKDIR}" \
      --labels "${_LABELS}" \
      --runnergroup "${_RUNNER_GROUP}" \
      --unattended \
      --replace \
      "${ARGS[@]}"
  [[ ! -d "${_RUNNER_WORKDIR}" ]] && mkdir -p "${_RUNNER_WORKDIR}"
}
[[ -z "${GITHUB_RUNNER_TOKEN}" ]] && { echo "ERROR: RUNNER_TOKEN is not set"; exit 1; }
[[ -z "${REPO_URL}" ]]     && { echo "ERROR: REPO_URL is not set";     exit 1; }

_SHORT_URL="${REPO_URL}"

# Start Docker daemon inside the container if requested (requires privileged: true)
if [[ "${_START_DOCKER_SERVICE}" == "true" ]]; then
  echo "Starting Docker daemon..."
  dockerd >/var/log/dockerd.log 2>&1 &
  # Wait until the socket is ready
  timeout 30 sh -c 'until docker info >/dev/null 2>&1; do sleep 1; done' \
    || { echo "ERROR: dockerd failed to start"; cat /var/log/dockerd.log; exit 1; }
  echo "Docker daemon is ready"
fi

# If the host docker socket is mounted, align the docker group GID inside the
# container so the runner user can actually reach the daemon.
if [[ -e /var/run/docker.sock ]]; then
  _DOCKER_SOCK_GID=$(stat -c '%g' /var/run/docker.sock)
  _CURRENT_DOCKER_GID=$(getent group docker | cut -d: -f3 2>/dev/null || echo "")
  if [[ -n "${_DOCKER_SOCK_GID}" && "${_DOCKER_SOCK_GID}" != "${_CURRENT_DOCKER_GID}" ]]; then
    echo "Adjusting docker group GID to match socket (${_DOCKER_SOCK_GID})"
    groupmod -g "${_DOCKER_SOCK_GID}" docker 2>/dev/null || true
  fi
fi

configure_runner

echo "Starting runner..."
exec ./run.sh
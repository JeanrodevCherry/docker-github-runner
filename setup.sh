#!/bin/bash
# =============================================
# GitHub Actions Runner Configuration Script
# Secure version with input validation and cleanup
# =============================================

set -euo pipefail
trap 'cleanup' EXIT INT TERM ERR

# Configuration
DEFAULT_REPO_URL="https://github.com/JeanrodevCherry/CellProfilerPipeline"
DEFAULT_RUNNER_NAME="github-runner"
TMP_ENV_FILE=".env.tmp"
FINAL_ENV_FILE=".env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =============================================
# Functions
# =============================================

cleanup() {
    local exit_code=$?
    if [[ -f "$TMP_ENV_FILE" ]]; then
        rm -f "$TMP_ENV_FILE"
    fi
    if [[ $exit_code -ne 0 ]]; then
        echo -e "${RED}❌ Script failed with exit code $exit_code${NC}"
    fi
}

validate_repo_url() {
    local url="$1"
    if [[ ! "$url" =~ ^https://github\.com/.*/.*$ ]]; then
        echo -e "${RED}❌ ERROR: Invalid repository URL format${NC}"
        echo "   Expected format: https://github.com/owner/repo"
        return 1
    fi
    return 0
}

validate_path() {
    local path="$1"
    if [[ ! -d "$path" ]]; then
        echo -e "${RED}❌ ERROR: Path does not exist: $path${NC}"
        return 1
    fi
    if [[ ! -w "$path" ]]; then
        echo -e "${RED}❌ ERROR: Path is not writable: $path${NC}"
        return 1
    fi
    if [[ "$path" =~ \.\. ]]; then
        echo -e "${RED}❌ ERROR: Path contains '..' which is not allowed${NC}"
        return 1
    fi
    return 0
}

validate_token() {
    local token="$1"
    if [[ -z "$token" ]]; then
        echo -e "${RED}❌ ERROR: GitHub token cannot be empty${NC}"
        return 1
    fi
    if [[ ${#token} -lt 29 ]]; then
        echo -e "${RED}❌ ERROR: GitHub token is too short (minimum 29 characters)${NC}"
        return 1
    fi
    # Basic check for common token patterns
    if [[ ! "$token" =~ ^[a-zA-Z0-9]{29,}$ ]]; then
        echo -e "${RED}❌ ERROR: GitHub token contains invalid characters${NC}"
        return 1
    fi
    return 0
}

sanitize_input() {
    # Remove leading/trailing whitespace
    echo "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

prompt_with_default() {
    local label="$1"
    local default_value="$2"
    printf "%s[%b%s%b]: " "$label" "$YELLOW" "$default_value" "$NC"
}

# =============================================
# Main Script
# =============================================

echo -e "${GREEN} GitHub Actions Runner Configuration${NC}"
echo "----------------------------------------"

# Repository URL
read -r -p "$(prompt_with_default "Enter the repository URL " "$DEFAULT_REPO_URL")" input_repo
REPO_URL=$(sanitize_input "${input_repo:-$DEFAULT_REPO_URL}")
validate_repo_url "$REPO_URL" || exit 1

REPO_NAME="$(basename "$REPO_URL")"

# Runner path
while true; do
    read -r -p "$(prompt_with_default "Enter the path to the runner files " "$(pwd)")" input_path
    RUNNER_PATH=$(sanitize_input "${input_path:-$(pwd)}")
    validate_path "$RUNNER_PATH" && break
    echo "Please try again."
done

# GitHub Token
while true; do
    read -r -p "Enter your GitHub token (paste allowed): " TOKEN
    validate_token "$TOKEN" || continue
    break
done

# Runner name
read -r -p "$(prompt_with_default "Enter the runner name " "$DEFAULT_RUNNER_NAME")" input_runner_name
RUNNER_NAME=$(sanitize_input "${input_runner_name:-$DEFAULT_RUNNER_NAME}")

# =============================================
# Configuration
# =============================================

echo -e "\n${GREEN}✅ Configuration Summary:${NC}"
echo "   Repository: $REPO_URL"
echo "   Runner name: $RUNNER_NAME"
echo "   Runner path: $RUNNER_PATH"
echo "----------------------------------------"

# Create temporary .env file
{
    echo "REPO_URL=$REPO_URL"
    echo "REPO_NAME=$REPO_NAME"
    echo "LOCATION_TMP=$RUNNER_PATH"
    echo "GITHUB_RUNNER_TOKEN=$TOKEN"
    echo "RUNNER_NAME=$RUNNER_NAME"
} > "$TMP_ENV_FILE"

# Validate the .env file before using it
if [[ ! -s "$TMP_ENV_FILE" ]]; then
    echo -e "${RED}❌ ERROR: Failed to create configuration file${NC}"
    exit 1
fi

# Move to final location
mv "$TMP_ENV_FILE" "$FINAL_ENV_FILE"

echo -e "${GREEN}✅ Configuration saved to $FINAL_ENV_FILE${NC}"
echo -e "${GREEN}✅ You can now run: docker-compose up -d${NC}"

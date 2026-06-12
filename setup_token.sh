#!/bin/bash
REPO_URL="https://github.com/JeanrodevCherry/CellProfilerPipeline"
RUNNER_NAME="github-runner"

read -p "Enter the repository URL (default: $REPO_URL): " input_repo
if [ -n "$input_repo" ]; then
    REPO_URL="$input_repo"
fi

read -p "Enter the path to the runner files: " RUNNER_PATH

if [ ! -d "$RUNNER_PATH" ]; then
    echo "❌ ERROR: Path does not exist: $RUNNER_PATH"
    echo "Please ensure the directory exists and is accessible."
    exit 1
fi
 

read -p "Enter your GitHub token: " TOKEN

read -p "Enter the runner name (default: $RUNNER_NAME): " input_runner_name
if [ -n "$input_runner_name" ]; then
    RUNNER_NAME="$input_runner_name"
fi


echo "Configuring GitHub Actions runner..."
echo "Runner path: $RUNNER_PATH"
echo "Repository: $REPO_URL"

echo REPO_URL=$REPO_URL > ./.env
echo LOCATION_TMP=$RUNNER_PATH >> ./.env
echo GITHUB_RUNNER_TOKEN=$TOKEN >> ./.env
echo RUNNER_NAME=$RUNNER_NAME >> ./.env
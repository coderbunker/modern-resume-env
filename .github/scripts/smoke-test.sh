#!/bin/bash
set -e

# Configuration from arguments
COMPOSE_FILE=${1:-"docker-compose.yml"}
PROFILE=${2:-""}
ATTACH_SERVICES=${3:-""}
EXCLUSIONS_REGEX=${4:-""}
LOG_FILE="${TMPDIR:-/tmp}/smoke-logs.txt"

# Prepare profile flag
PROFILE_FLAG=""
if [ -n "$PROFILE" ]; then
	PROFILE_FLAG="--profile $PROFILE"
fi

# Prepare attach flags
ATTACH_FLAGS=""
if [ -n "$ATTACH_SERVICES" ]; then
	for service in $(echo "$ATTACH_SERVICES" | tr ',' ' '); do
		ATTACH_FLAGS="$ATTACH_FLAGS --attach $service"
	done
fi

echo "🚀 Starting Centralized Smoke Test..."
echo "📂 Compose File: $COMPOSE_FILE"
echo "👥 Profile: ${PROFILE:-none}"
echo "🔗 Attaching to: ${ATTACH_SERVICES:-all}"
echo "-------------------------------------------------------"

# Run docker compose up and stream logs to both console and file
# Using --abort-on-container-exit to stop once smoke-test container finishes
# Using --exit-code-from smoke-test to capture its success/failure
# Note: smoke-test is the assumed name of the one-shot testing service
# shellcheck disable=SC2086
docker compose -f "$COMPOSE_FILE" $PROFILE_FLAG up \
	--abort-on-container-exit \
	--exit-code-from smoke-test \
	$ATTACH_FLAGS \
	--remove-orphans 2>&1 | tee "$LOG_FILE"

echo "-------------------------------------------------------"
echo "🔍 Checking logs for unexpected errors and warnings..."

# Define base exclusions for known safe/expected messages
BASE_EXCLUSIONS="Detected P3005: Baselining database|Found orphan containers|SIGTERM received"

# Combine with user-provided exclusions (handling multi-line input from YAML)
FINAL_EXCLUSIONS="$BASE_EXCLUSIONS"
if [ -n "$EXCLUSIONS_REGEX" ]; then
	# Convert newlines to pipes and remove trailing pipe or extra pipes
	USER_EXCLUSIONS=$(echo "$EXCLUSIONS_REGEX" | tr '\n' '|' | sed 's/||*/|/g' | sed 's/^|//;s/|$//')
	if [ -n "$USER_EXCLUSIONS" ]; then
		FINAL_EXCLUSIONS="$FINAL_EXCLUSIONS|$USER_EXCLUSIONS"
	fi
fi

# Perform the assertion
if grep -E "ERROR|WARN" "$LOG_FILE" | grep -vE "$FINAL_EXCLUSIONS"; then
	echo "❌ Found unexpected errors or warnings in logs!"
	# In CI, the logs are already printed via tee, so we just fail.
	exit 1
fi

echo "✅ No unexpected errors or warnings found in logs."
echo "🚀 Smoke test completed successfully!"

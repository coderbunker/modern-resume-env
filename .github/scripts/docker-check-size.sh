#!/bin/bash
set -eo pipefail

# Required Environment Variables:
# - REMOTE_IMAGE_NAME: The full registry image name (e.g. w90vyjm8.../modern-resume-backend)
# - LOCAL_IMAGE_NAME: The local image name/tag (e.g. modern-resume-std)

if [ -z "$REMOTE_IMAGE_NAME" ] || [ -z "$LOCAL_IMAGE_NAME" ]; then
	echo "Error: REMOTE_IMAGE_NAME and LOCAL_IMAGE_NAME must be set."
	exit 1
fi

# Ensure images have a tag (default to :latest if none provided)
if [[ "$REMOTE_IMAGE_NAME" != *":"* ]]; then
	REMOTE_IMAGE_NAME="$REMOTE_IMAGE_NAME:latest"
fi
if [[ "$LOCAL_IMAGE_NAME" != *":"* ]]; then
	LOCAL_IMAGE_NAME="$LOCAL_IMAGE_NAME:latest"
fi

echo "Comparing image sizes..."
echo "Remote Image: $REMOTE_IMAGE_NAME"
echo "Local Image:  $LOCAL_IMAGE_NAME"

# 1. Get Remote Size (Compressed) via Manifest
# Enable experimental CLI features for manifest inspect
export DOCKER_CLI_EXPERIMENTAL=enabled

# Capture output, handle failure if tag doesn't exist
if ! MANIFEST_JSON=$(docker manifest inspect -v "$REMOTE_IMAGE_NAME" 2>/dev/null); then
	echo "No existing image found in registry for $REMOTE_IMAGE_NAME. Skipping comparison."
	exit 0
fi

# Parse JSON to find linux/amd64 size
# We sum the 'size' of all layers in the manifest for linux/amd64
# Handle both Manifest List (Array) and single Manifest (Object)
JQ_QUERY='
  [
    (if type=="array" then .[] else . end)
    | select(.Descriptor.platform.architecture == "amd64" and .Descriptor.platform.os == "linux")
    | (.SchemaV2Manifest // .OCIManifest)
    | .layers[].size
  ] | add
'

if ! REMOTE_SIZE=$(echo "$MANIFEST_JSON" | jq -r "$JQ_QUERY" 2>jq_error); then
	echo "jq: error processing manifest"
	echo "Error details:"
	cat jq_error
	echo "Incorrectly parsed input (JSON):"
	echo "$MANIFEST_JSON"
	rm -f jq_error
	exit 0
fi
rm -f jq_error

if [ -z "$REMOTE_SIZE" ] || [ "$REMOTE_SIZE" == "null" ]; then
	echo "Could not parse remote image size (amd64/linux) from manifest. Skipping."
	exit 0
fi

# 2. Get Local Size (Compressed approximation)
echo "Calculating local estimated compressed size (50% of uncompressed)..."
if ! UNCOMPRESSED_SIZE=$(docker inspect -f "{{ .Size }}" "$LOCAL_IMAGE_NAME" 2>/dev/null); then
	echo "Error: Local image '$LOCAL_IMAGE_NAME' not found."
	exit 1
fi

# Estimate compressed size as 50% of uncompressed size
# This avoids the slow 'docker save | gzip' step
LOCAL_SIZE=$(echo "$UNCOMPRESSED_SIZE / 2" | bc)

# Convert to MB
REMOTE_MB=$(echo "$REMOTE_SIZE / 1000000" | bc)
LOCAL_MB=$(echo "$LOCAL_SIZE / 1000000" | bc)

echo "Remote (Latest) Size: $REMOTE_SIZE bytes (~$REMOTE_MB MB)"
echo "Local (Est.) Size:    $LOCAL_SIZE bytes (~$LOCAL_MB MB)"

# 3. Compare
FAIL_THRESHOLD=${FAIL_THRESHOLD_PERCENT:-10}

if [ "$REMOTE_SIZE" -gt 0 ]; then
	DIFF=$((LOCAL_SIZE - REMOTE_SIZE))

	# Calculate percentage change
	PERCENT=$(echo "scale=2; ($DIFF * 100) / $REMOTE_SIZE" | bc)

	echo "Difference: $DIFF bytes"
	echo "Percentage Change: $PERCENT%"

	# Check for significant increase (> Threshold)
	IS_SIGNIFICANT=$(echo "$PERCENT > $FAIL_THRESHOLD" | bc -l)

	if [ "$IS_SIGNIFICANT" -eq 1 ]; then
		MESSAGE="⚠️ **Container Image Size Warning**
Image size estimated to increase by **$PERCENT%** (from ~$REMOTE_MB MB to ~$LOCAL_MB MB), which exceeds the **${FAIL_THRESHOLD}%** limit.

- Remote (latest): ~$REMOTE_MB MB
- Local (current): ~$LOCAL_MB MB
- Difference: $DIFF bytes"

		echo "$MESSAGE" >image-size-report.md
		echo "size_warning=true" >>"$GITHUB_OUTPUT"
		echo "::warning title=Image Size Increase::$MESSAGE"
	else
		echo "size_warning=false" >>"$GITHUB_OUTPUT"
	fi
fi

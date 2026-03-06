#!/bin/bash
set -eo pipefail

# Usage: ./log-registry-size.sh <image-tag>

IMAGE_TAG="$1"

if [ -z "$IMAGE_TAG" ]; then
	echo "Usage: $0 <image-tag>"
	exit 1
fi

echo "Fetching actual compressed size for: $IMAGE_TAG"

# Enable experimental CLI features for manifest inspect
export DOCKER_CLI_EXPERIMENTAL=enabled

# Capture output
if ! MANIFEST_JSON=$(docker manifest inspect -v "$IMAGE_TAG" 2>/dev/null); then
	echo "Error: Could not inspect manifest for $IMAGE_TAG"
	exit 1
fi

# Parse JSON to find linux/amd64 size
# Handle both Manifest List (Array) and single Manifest (Object)
SIZE=$(echo "$MANIFEST_JSON" | jq -r '
  [
    (if type=="array" then .[] else . end)
    | select(.Descriptor.platform.architecture == "amd64" and .Descriptor.platform.os == "linux")
    | (.SchemaV2Manifest // .OCIManifest).layers[].size
  ] | add
')

if [ -z "$SIZE" ] || [ "$SIZE" == "null" ]; then
	echo "Error: Could not parse size from manifest."
	exit 1
fi

# Convert to MB
SIZE_MB=$(echo "scale=2; $SIZE / 1000000" | bc)

echo "::notice::Actual Compressed Size: $SIZE bytes (~$SIZE_MB MB)"

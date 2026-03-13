#!/bin/bash
# validate-compose.sh - Validates all Docker Compose profiles
# This script is part of modern-resume-env

set -e

COMPOSE_FILE=${1:-docker-compose.yml}

if [ ! -f "$COMPOSE_FILE" ]; then
	echo "❌ Error: $COMPOSE_FILE not found" >&2
	exit 1
fi

echo "🔍 Validating Docker Compose profiles in $COMPOSE_FILE..."

# Extract all unique profiles using yq for robust YAML parsing
PROFILES=$(yq '.services[].profiles[]' "$COMPOSE_FILE" 2>/dev/null | sort | uniq | xargs)

if [ -z "$PROFILES" ]; then
	echo "ℹ️ No profiles found in $COMPOSE_FILE. Running standard validation..."
	docker compose config --quiet
	echo "✅ Standard validation passed."
	exit 0
fi

FAILED=0
for PROFILE in $PROFILES; do
	echo "  - Checking profile: $PROFILE"
	if ! docker compose --profile "$PROFILE" config --quiet; then
		echo "    ❌ Validation failed for profile: $PROFILE" >&2
		FAILED=1
	fi
done

if [ $FAILED -ne 0 ]; then
	echo "❌ Docker Compose validation failed for one or more profiles." >&2
	exit 1
fi

echo "✅ All profiles validated successfully."

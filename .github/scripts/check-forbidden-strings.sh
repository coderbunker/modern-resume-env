#!/bin/bash
set -eo pipefail

# Usage: ./check-forbidden-strings.sh <repo_name>

REPO_NAME=$1
FORBIDDEN_STRINGS=(
	"w90vyjm8.c1.bhs5.container-registry.ovh.net"
)

# Repositories allowed to have these strings
# (e.g. infra/env repos often need to define the defaults)
EXCLUDED_REPOS=(
	"modern-resume-infra"
	"modern-resume-env"
)

for excluded in "${EXCLUDED_REPOS[@]}"; do
	if [[ "$REPO_NAME" == *"$excluded"* ]]; then
		echo "ℹ️ Skipping forbidden string check for $REPO_NAME (excluded repo)"
		exit 0
	fi
done

HAS_ERROR=0

echo "🔍 Checking for forbidden hardcoded strings in $REPO_NAME..."

for forbidden in "${FORBIDDEN_STRINGS[@]}"; do
	echo "  - Checking: $forbidden"

	# We check all tracked files, excluding documentation (.md) and logs
	# grep -l returns the file names that match
	HARDCODED_FILES=$(git ls-files | grep -v '\.md$' | grep -v '^logs/' | xargs grep -l "$forbidden" || true)

	if [[ -n "$HARDCODED_FILES" ]]; then
		echo "❌ Found forbidden string '$forbidden' in the following files:"
		echo "$HARDCODED_FILES"
		for file in $HARDCODED_FILES; do
			echo "::error file=$file::Forbidden hardcoded string found. Please use centralized configuration."
		done
		HAS_ERROR=1
	fi
done

if [[ "$HAS_ERROR" -eq 1 ]]; then
	exit 1
else
	echo "✅ No forbidden strings found."
fi

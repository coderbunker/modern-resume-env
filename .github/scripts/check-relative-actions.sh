#!/usr/bin/env bash

# This script checks for relative action paths in GitHub workflows.
# Relative paths like `uses: ./.github/actions/...` fail when a reusable
# workflow is called from another repository.

set -e

HAS_ERROR=0

for file in "$@"; do
	if grep -E -n "^[[:space:]]+uses:[[:space:]]+\./\.github/actions" "$file"; then
		echo "::error file=$file::Relative action paths (uses: ./.github/actions/...) are not allowed."
		echo "Please use absolute paths instead: coderbunker/modern-resume-env/.github/actions/...@main"
		HAS_ERROR=1
	fi
done

if [[ "$HAS_ERROR" -eq 1 ]]; then
	exit 1
fi

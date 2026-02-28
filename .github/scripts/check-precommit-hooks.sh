#!/usr/bin/env bash

# This script verifies that the .pre-commit-config.yaml file exists
# and contains a required baseline of hooks. It does NOT execute the hooks.

set -e

CONFIG_FILE=".pre-commit-config.yaml"
REQUIRED_HOOKS=("shellcheck" "markdownlint" "yamllint" "nixpkgs-fmt")
HAS_ERROR=0

echo "🔍 Checking for required pre-commit hooks..."

if [[ ! -f "$CONFIG_FILE" ]]; then
	echo "::error file=$CONFIG_FILE::Missing $CONFIG_FILE in repository root."
	exit 1
fi

for hook in "${REQUIRED_HOOKS[@]}"; do
	if grep -q -E "id:[[:space:]]+$hook" "$CONFIG_FILE"; then
		echo "✅ Found required hook: $hook"
	else
		echo "::error file=$CONFIG_FILE::Missing required hook in .pre-commit-config.yaml: $hook"
		HAS_ERROR=1
	fi
done

if [[ "$HAS_ERROR" -eq 1 ]]; then
	echo "❌ Pre-commit configuration check failed."
	exit 1
else
	echo "🎉 All required hooks are present."
fi

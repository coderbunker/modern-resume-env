#!/usr/bin/env bash
set -e

# This script verifies GitHub repository settings via the API.
# It checks for:
# - Default branch is 'main'
# - 'Automatically delete head branches' is enabled
# - 'Always suggest updating pull request branches' is enabled

REPO=$1
if [ -z "$REPO" ]; then
	# Try to determine repo from git remote
	if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		REPO=$(git remote get-url origin | sed 's/.*github.com[:\/]\(.*\)\.git/\1/')
	fi
fi

if [ -z "$REPO" ]; then
	echo "::error::Repository name not provided and could not be determined from git remote."
	exit 1
fi

echo "🔍 Checking repository settings for $REPO..."

# Use GITHUB_TOKEN if available
AUTH_HEADER=()
if [ -n "$GITHUB_TOKEN" ]; then
	AUTH_HEADER=(-H "Authorization: token $GITHUB_TOKEN")
fi

RESPONSE=$(curl -s "${AUTH_HEADER[@]}" "https://api.github.com/repos/$REPO")

# Verify we got a valid response
if echo "$RESPONSE" | jq -e '.message' >/dev/null 2>&1; then
	MESSAGE=$(echo "$RESPONSE" | jq -r .message)
	echo "::error::Failed to fetch repository info: $MESSAGE"
	exit 1
fi

DEFAULT_BRANCH=$(echo "$RESPONSE" | jq -r .default_branch)
DELETE_BRANCH_ON_MERGE=$(echo "$RESPONSE" | jq -r .delete_branch_on_merge)
ALLOW_UPDATE_BRANCH=$(echo "$RESPONSE" | jq -r .allow_update_branch)

HAS_ERROR=0

if [ "$DEFAULT_BRANCH" != "main" ]; then
	echo "::error::Default branch is '$DEFAULT_BRANCH', expected 'main'."
	HAS_ERROR=1
else
	echo "✅ Default branch is 'main'."
fi

if [ "$DELETE_BRANCH_ON_MERGE" != "true" ]; then
	echo "::error::'Automatically delete head branches' is NOT enabled (delete_branch_on_merge=false)."
	HAS_ERROR=1
else
	echo "✅ 'Automatically delete head branches' is enabled."
fi

if [ "$ALLOW_UPDATE_BRANCH" != "true" ]; then
	echo "::error::'Always suggest updating pull request branches' is NOT enabled (allow_update_branch=false)."
	HAS_ERROR=1
else
	echo "✅ 'Always suggest updating pull request branches' is enabled."
fi

# Note: "Release Immutability" is not directly available in this specific API response
# for standard repos without extra scopes or newer API features.
# We focus on the requested settings for now.

if [ "$HAS_ERROR" -eq 1 ]; then
	echo "❌ Repository configuration check failed for $REPO."
	exit 1
else
	echo "🎉 Repository configuration is correct for $REPO."
fi

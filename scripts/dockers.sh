#!/bin/bash
# dockers - Docker Compose + SOPS wrapper
# This script is part of modern-resume-env
set -e

SOPS_FILE="local.enc.env"

# 1. Detect secrets
USE_SOPS=false
if [ -f "$SOPS_FILE" ]; then
	USE_SOPS=true
fi

# 2. Load secrets if necessary
if [ "$USE_SOPS" = true ]; then
	# Only attempt decryption if we have a way to decrypt
	if [ -n "$SOPS_AGE_KEY_FILE" ] || [ -n "$SOPS_AGE_KEY" ]; then
		# Use sops -d and eval to load secrets into the environment.
		echo "🔓 Decrypting secrets from $SOPS_FILE..." >&2
		if ! DECRYPTED_VARS=$(sops -d --output-type dotenv "$SOPS_FILE" 2>/tmp/sops-error); then
			echo "❌ Error: Failed to decrypt $SOPS_FILE" >&2
			cat /tmp/sops-error >&2
			exit 1
		fi
		# We only export lines that look like KEY=VALUE
		eval "$(echo "$DECRYPTED_VARS" | sed -n '/^[A-Za-z0-9_]\{1,\}=/p' | sed 's/^/export /')"
	else
		echo "⚠️ Warning: $SOPS_FILE found but no SOPS identities (SOPS_AGE_KEY_FILE or SOPS_AGE_KEY) are set. Skipping decryption." >&2
	fi
fi

# 3. Execute command
# If the first argument is "compose", shift it to avoid "docker compose compose"
DOCKER_CMD=("docker" "compose")
if [[ "$1" == "compose" ]]; then
	shift
fi

exec "${DOCKER_CMD[@]}" "$@"

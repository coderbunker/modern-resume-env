#!/bin/bash
# buns - Bun + SOPS + Validation wrapper
# This script is part of modern-resume-env
set -e

# Find the validation script - it should be in the same directory as this script
# or in a known location in the Nix store.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATE_SCRIPT="${VALIDATE_SCRIPT_PATH:-$SCRIPT_DIR/validate-env.ts}"

# 1. Detect secrets
SOPS_FILE="local.enc.env"
USE_SOPS=false
if [ -f "$SOPS_FILE" ]; then
	USE_SOPS=true
fi

# 2. Detect schema
SCHEMA_FILE="src/configSchema.ts"
USE_VALIDATION=false
if [ -f "$SCHEMA_FILE" ]; then
	USE_VALIDATION=true
fi

# 3. Load secrets if necessary
if [ "$USE_SOPS" = true ]; then
	# Only attempt decryption if we have a way to decrypt
	if [ -n "$SOPS_AGE_KEY_FILE" ] || [ -n "$SOPS_AGE_KEY" ]; then
		# Use sops -d and eval to load secrets into the environment.
		echo "🔓 Decrypting secrets from $SOPS_FILE..." >&2
		# We use sed to prefix 'export ' for the shell.
		# We capture the output first to detect decryption errors properly.
		if ! DECRYPTED_VARS=$(sops -d --output-type dotenv "$SOPS_FILE" 2>/tmp/sops-error); then
			echo "❌ Error: Failed to decrypt $SOPS_FILE" >&2
			cat /tmp/sops-error >&2
			exit 1
		fi
		# We only export lines that look like KEY=VALUE to avoid 'export ' (no args) which prints the environment.
		eval "$(echo "$DECRYPTED_VARS" | sed -n '/^[A-Za-z0-9_]\{1,\}=/p' | sed 's/^/export /')"
	else
		echo "⚠️ Warning: $SOPS_FILE found but no SOPS identities (SOPS_AGE_KEY_FILE or SOPS_AGE_KEY) are set. Skipping decryption." >&2
	fi
fi

# 4. Execute command
# We use 'exec' for the final command to properly handle signals (Ctrl+C, etc.)

if [ "$USE_VALIDATION" = true ]; then
	# Run validation and then the command
	bun "$VALIDATE_SCRIPT" && exec bun "$@"
else
	exec bun "$@"
fi

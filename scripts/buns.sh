#!/bin/bash
# buns - Bun + SOPS + Validation wrapper
# This script is part of modern-resume-env

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
    # Use sops -d and eval to load secrets into the environment.
    # We use sed to prefix 'export ' for the shell.
    # Note: We expect SOPS_AGE_KEY_FILE or similar to be set in the environment.
    eval "$(sops -d --output-type dotenv "$SOPS_FILE" | sed 's/^/export /')"
    if [ $? -ne 0 ]; then
        echo "❌ Error: Failed to decrypt $SOPS_FILE" >&2
        exit 1
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

#!/usr/bin/env bash
set -e

# Install hooks if not already installed
if [ -d ".git" ]; then
	pre-commit install >/dev/null 2>&1

	# Patch the hook to use direnv if available
	HOOK_FILE=".git/hooks/pre-commit"
	if [ -f "$HOOK_FILE" ]; then
		# Check if we already patched it
		if ! grep -q "direnv export bash" "$HOOK_FILE"; then
			# We want to insert the direnv loader after the shebang
			# but before the "start templated" block if possible, or just at the top.
			# actually, pre-commit hooks are often overwritten by `pre-commit install`.
			# however, `pre-commit` itself generates a script that calls the actual hook executable.

			# The issue is that the `pre-commit` executable (wrapper) in the hook
			# is called with the environment of the caller (git).
			# If git is called from a non-direnv shell, `tofu` etc are not in PATH.

			# We will interpret the hook execution.
			# Create a backup
			cp "$HOOK_FILE" "${HOOK_FILE}.bak"

			# Create a temporary file with our preamble
			cat >"${HOOK_FILE}.tmp" <<EOF
#!/usr/bin/env bash
# Managed by setup-hooks.sh - Auto-loading direnv environment
if command -v direnv >/dev/null 2>&1; then
    eval "\$(direnv export bash)"
fi
EOF

			# Append the original content, skipping the first line (shebang)
			tail -n +2 "${HOOK_FILE}" >>"${HOOK_FILE}.tmp"

			# Move back
			mv "${HOOK_FILE}.tmp" "$HOOK_FILE"
			chmod +x "$HOOK_FILE"

			echo "Patched .git/hooks/pre-commit to load direnv."
		fi
	fi
fi

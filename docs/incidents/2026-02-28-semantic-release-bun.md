# Incident Report: Semantic Release Failures in Bun Environment

**Date:** 2026-02-28
**Status:** Resolved
**Components Affected:** `.github/actions/unified-version` action, Release Pipeline

## Description

Build pipelines responsible for dynamically injecting and committing Git tags via `cycjimmy/semantic-release-action` began universally failing with the error `/bin/sh: 1: npm: not found`.

## Root Cause Analysis

Our standard CI/CD execution layer defines a strict runtime sandbox powered by Nix `flake.nix` which intentionally provisions only the `bun` Javascript runtime and package manager. Standard `npm` or `nodejs` executables are explicitly excluded.

The third-party GitHub Action `cycjimmy/semantic-release-action@v4` hardcodes `npm ci --only=prod` internally to dynamically bootstrap semantic-release plugins on the fly before executing the main command. Due to our sandboxed runner environment missing `npm`, this step fatally crashed.

## Attempted Fixes & Discoveries

### 1. The `bun add -d` Package Overrides

Our first remediation attempt replaced the GitHub Action with a simple bash script that programmatically invoked `bun add -d semantic-release` to install the tool via bun, followed by `bunx semantic-release`.

**Result:** Fatal `TypeError: Cannot read properties of undefined` in `@semantic-release/npm` plugin.

**Why:** Running `bun add -d` inside the repository root automatically generated a tracking `package.json` file. The `@semantic-release/npm` plugin (enabled by default) discovered this new `package.json` and assumed the pipeline was attempting to publish an NPM package. It subsequently crashed because the generated `package.json` lacked a required `name` property.

### 2. Upstream Version Breaches (v25)

During local testing, we discovered that `bun add -d semantic-release` implicitly installed the latest version (`v25`). Version 25 includes aggressive parser validations that immediately throw TypeErrors if a discovered `package.json` is missing metadata. The legacy cycjimmy wrapper utilized older v21/v22 architectures which gracefully bypassed NPM publishing if it encountered invalid workspaces.

### 3. CLI Plugin Configuration Parsing Errors

We engineered a standalone Bash wrapper leveraging `npm`-free global bun installations of `semantic-release`. While this successfully installed the tool, the semantic-release engine natively forces the `@semantic-release/npm` plugin into its configuration evaluation lifecycle. Attempting to bypass this via `--plugins` CLI arguments or dynamically generated `.releaserc` files proved exceedingly brittle and threw terminal parser errors.

## Final Resolution

We abandoned the standalone script approach due to the internal complexities and strict file discovery patterns of the semantic-release plugin engine. We reverted to utilizing `cycjimmy/semantic-release-action@v4`, which handles these configuration edge-cases natively.

To solve the foundational `npm` absence error within our strict Nix/Bun runner environments, we updated `.github/actions/unified-version/action.yml` to explicitly provision the `npm` binary natively via `bun` prior to execution:

```yaml
    - name: Provision NPM for Cycjimmy via Bun
      shell: bash
      run: bun install -g npm
```

By leveraging Bun to globally install the `npm` binary, we securely satisfy Cycjimmy's hardcoded `npm ci` initialization routines utilizing our native Nix-provided runtime, entirely bypassing the need to externally inject overlapping JS platforms via `actions/setup-node`. This preserves the strict `bun` constraints of the underlying repository tracking layers.

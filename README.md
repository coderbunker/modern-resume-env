# Modern Resume Shared Environment

This repository centralizes the development environment for both the frontend and backend of the Modern Resume project.

## Overview

By using a centralized `flake.nix`, we ensure:
- **Consistency**: The same versions of Node.js, Bun, Kubectl, and other tools are used across all repositories.
- **Maintainability**: Dependency updates only need to be managed in one place.
- **Portability**: Developers can load the environment via `direnv` or `nix develop` without worrying about local setup.

## Structure

- `flake.nix`: Defines the packages, shell, and helper scripts.
- `INFRA.md`: Documentation for infrastructure provisioning and management.
- `USAGE.md`: Instructions on how to integrate this environment into other repositories.

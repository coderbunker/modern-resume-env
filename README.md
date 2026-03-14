# Modern Resume Shared Environment

This repository centralizes the development environment for both the frontend and backend of the Modern Resume project using [`devenv`](https://devenv.sh/).

## Overview

By using a centralized `flake.nix` backed by `devenv` and `flake-parts`, we ensure:

- **Consistency**: The same versions of Node.js, Bun, Kubectl, and other tools are used across all repositories.
- **Maintainability**: Dependency updates only need to be managed in one place.
- **Portability**: Developers can load the environment via `direnv` or `nix develop` without worrying about local setup.
- **Performance**: `devenv` caches configurations and enables incredibly fast shell startup when integrated with `direnv`.
- **Developer Experience**: Standardized hooks, straightforward modular configuration, and powerful features provided by `devenv`.

## Structure

- `flake.nix`: Defines the `devenv` modules, packages, shell variables, and helper scripts using `flake-parts`.
- `INFRA.md`: Documentation for infrastructure provisioning and management.
- `USAGE.md`: Instructions on how to integrate this environment into other repositories, and how to utilize our binary caches.
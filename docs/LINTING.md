# 🛡️ CI Linting Strategy

We aim for consistent, fast, and unified linting across all repositories in the Modern Resume ecosystem.

## 核心理念 (Core Philosophy)

1. **Centralized Rules**: Base linting rules are defined in `modern-resume-env`.
2. **Local/CI Parity**: Linting runs identically on a developer's machine via `pre-commit` and in GitHub Actions via our reusable `lint-action`.
3. **Automatic Detection**: We rely on `pre-commit`'s built-in file type detection (`types`, `files`, `exclude`) to run only the relevant hooks.
4. **Smart Execution**: Only run relevant linters based on the files that changed.

## ⚙️ How it works: `lint-action`

The `lint-action` in `modern-resume-env` is a thin wrapper around `pre-commit` that ensures the environment is correctly set up with Nix before running.

### Usage in a repository

```yaml
- name: Lint
  uses: coderbunker/modern-resume-env/.github/actions/lint-action@main
```

### Hook Selection

The `.pre-commit-config.yaml` defines which hooks run for which file types. For example:

- **Shell scripts**: `shellcheck`, `shfmt`.
- **Dockerfiles**: `hadolint`.
- **Markdown**: `markdownlint`.
- **YAML/Kubernetes**: `yamllint`, `kubeconform`.
- **GitHub Actions**: `actionlint`.

If a repository does not contain a specific file type (e.g., no Dockerfiles), `pre-commit` will automatically skip the corresponding hooks. No manual "features" list is required.

## 🛠️ Local Setup

Developers should install `pre-commit` and use it locally to prevent CI failures.

```bash
# In any repo
nix develop # ensures pre-commit is available
pre-commit install
```

## 🧠 Implementation Detail

The `lint-action` will:

1. Setup the Nix environment via `setup-nix-env`.
2. Run `pre-commit run --all-files` (or `--from-ref` for PRs).
3. Fail the build if any hooks fail or modify files.

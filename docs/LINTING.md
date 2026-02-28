# 🛡️ CI Linting Strategy

We aim for consistent, fast, and unified linting across all repositories in the Modern Resume ecosystem.

## 核心理念 (Core Philosophy)

1. **Centralized Rules**: Base linting rules are defined in `modern-resume-env`.
2. **Local/CI Parity**: Linting runs identically on a developer's machine via `pre-commit` and in GitHub Actions via `setup-env`.
3. **Automatic Detection**: We rely on `pre-commit`'s built-in file type detection to run only the relevant hooks.
4. **Setup Once Pattern**: Environment initialization (Nix + Bun) is handled once per job via `setup-env`.

## ⚙️ How it works: `setup-env` + `pre-commit`

Instead of thin wrappers, we use the `setup-env` action to prepare the environment and then run `pre-commit` directly. This is more transparent and efficient for multi-step jobs.

### Usage in a repository

```yaml
jobs:
  lint:
    runs-on: self-hosted-nix
    steps:
      - uses: actions/checkout@v4
      - name: Setup Environment
        uses: coderbunker/modern-resume-env/.github/actions/setup-env@main
        with:
          install_deps: true # Only if you have local hooks like eslint
          github_access_token: ${{ secrets.GITHUB_TOKEN }}
      - name: Run pre-commit
        run: pre-commit run --all-files
```

## 🛠️ Local Setup

Developers should install `pre-commit` and use it locally to prevent CI failures.

```bash
# In any repo
nix develop # ensures pre-commit is available
pre-commit install
```

## 🧠 Implementation Detail

The `setup-env` action will:

1. Setup the Nix environment via `setup-nix-env`.
2. Configure `.npmrc` and run `bun install` (via `setup-bun-env`).
3. Handle authentication for private flakes/packages.

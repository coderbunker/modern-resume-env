# 🚀 Unified Release Process

All repositories in the Modern Resume project follow a standardized release and tagging policy to ensure predictable deployments and reliable GitOps automation.

## 🏷️ Tagging Policy Summary

Based on [2026-02-27-TAGGING-POLICY.md](file:///Users/rngadam/coderbunker/src/modern-resume-infra/docs/proposed/2026-02-27-TAGGING-POLICY.md).

- **Releases (main branch)**: `vX.Y.Z` (e.g., `v1.2.0`)
- **Integration (develop branch)**: `develop-build-<RUN_NUMBER>`
- **Features (PRs)**: `pr-<PR_NUMBER>-build-<RUN_NUMBER>`
- **Short SHA**: `sha-<SHORT_SHA>` (Used as a fallback/internal reference)

## 📦 Using Reusable Workflows

To enable automated semantic releases and Docker builds, add a `release.yml` to your repository:

```yaml
name: Release
on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  lint-test:
    name: Lint & Test
    # ... call reusable lint/test actions ...

  release:
    uses: coderbunker/modern-resume-env/.github/workflows/semantic-release.yml@main
    needs: lint-test
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    secrets: inherit

  docker:
    uses: coderbunker/modern-resume-env/.github/workflows/docker-ci.yml@main
    needs: [lint-test, release]
    with:
      image_path: cv.coderbunker.ca/your-repo-name
      version: ${{ needs.release.outputs.new_release_version || '0.0.0' }}
      is_new_release: ${{ needs.release.outputs.new_release_published == 'true' }}
    secrets: inherit

  notify:
    name: Notify
    needs: [lint-test, release, docker]
    if: always() && github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - name: Build Notification
        uses: coderbunker/modern-resume-env/.github/actions/post-build-notification@main
        with:
          build_result: ${{ needs.docker.result }}
          version: ${{ needs.release.outputs.new_release_version || 'N/A' }}
          github_token: ${{ secrets.GITHUB_TOKEN }}
```

## 🔄 Lifecycle of a Change

1. **PR Created**: `lint-test` runs. `docker` builds and tags as `pr-X-build-Y`.
2. **Merged to `develop`**: `lint-test` runs. `docker` builds and tags as `develop-build-Y`.
3. **Merged to `main`**:
    - `semantic-release` determines if a new version is needed.
    - If YES: Pushes GitHub Tag `v1.2.3`, creates Release. `docker` builds and tags as `v1.2.3`.
    - If NO: `docker` step is skipped (if configured) or builds with a fallback tag.

## 💬 Human-Readable Notifications

The standardized workflows automatically comment on PRs/Issues with the build status and links to the generated container images, making it easy for the team to see "what" is running where.

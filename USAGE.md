# How to Use This Environment

## 1. Integrate into an Application Repository

To use this shared environment in your project (e.g., `modern-resume` or `modern-resume-backend`), update your local `flake.nix` to point to this repository.

### Example `flake.nix`

```nix
{
  description = "Application Environment";

  inputs = {
    # Point to the shared environment repository
    modern-env.url = "github:coderbunker/modern-resume-env";
  };

  outputs = { self, modern-env }: {
    # Forward the shared devShell to your project
    devShells = modern-env.devShells;
  };
}
```

## 2. Binary Caching with GHCR or Harbor

Since Cachix is paid, you can use **GHCR.io** or a **Harbor** instance as a binary cache for your Nix builds.

### Using OCI Registries as a Cache (Nix 2.19+)

Nix has experimental support for OCI registries. To enable it, ensure your `nix.conf` contains:

```conf
experimental-features = nix-command flakes oci-store
```

#### Pushing to the Cache (in CI)

You can push your build results to GHCR:

```bash
nix copy --to "oci://ghcr.io/your-org/modern-resume-cache" .#devShells.x86_64-linux.default
```

#### Pulling from the Cache

When someone else runs `nix develop`, they can use your OCI registry as a substituter:

```bash
nix develop --substituters "https://ghcr.io/your-org/modern-resume-cache" --trusted-public-keys "..."
```

*(Note: Public registries are easier; for private Harbor, you'll need to handle authentication via `~/.config/nix/nix.conf` or netrc.)*

## 3. Local Development

Simply run:

```bash
nix develop
```

Or if you use `direnv`, create an `.envrc` file:

```bash
use flake github:coderbunker/modern-resume-env
```

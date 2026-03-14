# How to Use This Environment

## 1. Integrate into an Application Repository

To use this shared environment in your project (e.g., `modern-resume` or `modern-resume-backend`), update your local `flake.nix` to point to this repository and utilize its exported `devShell`. Because this environment is powered by [`devenv`](https://devenv.sh) and `flake-parts`, you get incredible developer experience and features for free.

### Example `flake.nix`

```nix
{
  description = "Application Environment";

  inputs = {
    # Point to the shared environment repository
    modern-env.url = "github:coderbunker/modern-resume-env";
  };

  outputs = { self, modern-env }: {
    # Forward the shared devShell to your project for immediate use
    devShells = modern-env.devShells;
  };
}
```

## 2. Binary Caching

We heavily utilize Nix binary caching to ensure fast loading times across devices and CI environments.

### Using Cachix (Recommended)

Our prebuilt packages are primarily cached at `rngadam.cachix.org`. `devenv` also uses its own binary caches (`devenv.cachix.org`) for its inner toolchains.

The `flake.nix` exposed by this repository comes preconfigured with the required `nixConfig` for these caches.

When you run `nix develop` or allow `direnv`, Nix will prompt you to accept these trusted substituters. Say **yes** to dramatically speed up your environment loading:

```nix
  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw= rngadam.cachix.org-1:1xP33wKk+G09q9H/Eih5f9b1c1Wn1Q3B8N4N+Wn/7pE=";
    extra-substituters = "https://devenv.cachix.org https://rngadam.cachix.org";
  };
```

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
# Evaluate the shell and its devenv setup
nix develop --impure
```
*(Depending on how devenv is configured downstream, `nix develop` alone works, but `--impure` may be required to access local user files like SOPS keys).*

### Automated Environment Loading (Direnv)

The best and most performant way to use this setup is through `direnv`.

Create an `.envrc` file in your root folder:

```bash
use flake github:coderbunker/modern-resume-env
```

Or if you imported it into your local `flake.nix`:

```bash
use flake
```

**Why Direnv?**
`devenv` caches its evaluation natively. When using `direnv`, your environment loading is cached. `devenv up` and subsequent shell startups are practically instant, eliminating wait times.
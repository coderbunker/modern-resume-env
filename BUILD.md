# Building and Caching Configuration

This repository uses OVH Cloud Object Storage (S3-compatible) as a **publicly readable** Nix binary cache. This allows CI and other developers to download pre-built packages without credentials, while ensuring security through **package signing**.

## 1. Prerequisites

- An OVH Object Storage bucket (configured for public-read access).
- Access Keys with Write permissions for CD/Push.
- A Nix signing key pair.

## 2. GitHub Secrets Configuration

To enable the push (caching) workflow, set the following Secrets in this GitHub repository:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `S3_ACCESS_KEY_ID` | OVH Access Key (Write access) | `abc123...` |
| `S3_SECRET_KEY` | OVH Secret Key (Write access) | `xyz789...` |
| `S3_ENDPOINT` | OVH S3 API Endpoint | `s3.bhs.io.cloud.ovh.net` |
| `S3_BUCKET` | The name of your bucket | `modern-resume-nix-cache` |
| `S3_REGION` | The region of your bucket | `bhs` |
| `CACHE_SIGNING_KEY` | The Private signing key | `cache-1:abc...` |

## 3. Using the Cache

### Automatic (GitHub Actions)

The custom action `./.github/actions/setup-nix-env` automatically configures the cache using the public bucket URL and the public signing key.

### Local Use

To benefit from the cache on your local machine, add the following to your `nix.conf` (usually `/etc/nix/nix.conf` or `~/.config/nix/nix.conf`):

```conf
substituters = https://cache.nixos.org https://modern-resume-nix-cache.s3.bhs.io.cloud.ovh.net
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= modern-resume-nix-cache-1:crKOVB7ABh6mDldfa2U9t+aUjQnx9AKeuRAE+/EkNkU=
```

## 4. Security Model

1. **Public Read**: Anyone can pull binaries. This saves build time for all contributors.
2. **Signed Write**: Only the GitHub workflow (holding the `CACHE_SIGNING_KEY`) can sign packages.
3. **Verification**: Even though the bucket is public, Nix will **reject** any package that isn't signed by our private key, preventing malicious injections.

## 5. Generating Keys (Reference)

If you need to rotate the signing keys:

```bash
nix-store --generate-binary-cache-key modern-resume-nix-cache-1 cache-priv-key cache-pub-key
```

1. Update `CACHE_SIGNING_KEY` secret with `cache-priv-key`.
2. Update the default `s3_public_key` in `.github/actions/setup-nix-env/action.yml` with `cache-pub-key`.

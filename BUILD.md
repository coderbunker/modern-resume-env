# Building and Caching Configuration

This repository uses OVH Cloud Object Storage (S3-compatible) as a Nix binary cache. This allows CI and other developers to download pre-built packages instead of compiling them from scratch.

## 1. Prerequisites

- An OVH Object Storage bucket.
- Access Keys with Read/Write permissions.
- Nix version with S3 support (standard in modern Nix).

## 2. GitHub Secrets Configuration

To enable the push workflow, you must set the following Secrets in this GitHub repository:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `S3_ACCESS_KEY_ID` | Your OVH Access Key | `abc123...` |
| `S3_SECRET_ACCESS_KEY` | Your OVH Secret Key | `xyz789...` |
| `S3_ENDPOINT` | OVH S3 API Endpoint | `s3.bhs.io.cloud.ovh.net` |
| `S3_BUCKET` | The name of your bucket | `modern-resume-cache` |
| `S3_REGION` | The region of your bucket | `bhs` |

## 3. Using the Cache Locally

To benefit from the cache on your local machine, you need to tell Nix to check the S3 bucket for binaries.

### Option A: Command Line
Add the `--substituters` and `--trusted-public-keys` flags to your commands:
```bash
nix develop --substituters "https://$S3_BUCKET.$S3_ENDPOINT"
```
*(Note: If the bucket is private, you will need to configure credentials in your local `nix.conf` or use a proxy.)*

### Option B: Permanent Configuration (`nix.conf`)
Add the following to `/etc/nix/nix.conf` or `~/.config/nix/nix.conf`:
```conf
substituters = https://cache.nixos.org https://$S3_BUCKET.$S3_ENDPOINT
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= your-key-1:...
```

## 4. Security (Public vs Private)

- **Public Cache**: Easiest to use. Anyone can pull binaries (saving them build time), but no one can write without your keys.
- **Private Cache**: Requires setting up `secret-key-files` or `netrc` locally so Nix can authenticate with OVH.

## 5. Signed Packages (Optional but Recommended)

For better security, you should sign your packages before pushing.
1. Generate a key: `nix-store --generate-binary-cache-key my-cache-key secret-key public-key`
2. Add the `secret-key` to GitHub Secrets.
3. Update the workflow to use `nix copy --sign-with-path ...`.

# SOPS and Age Key Configuration

This project uses [SOPS](https://github.com/getsops/sops) with [age](https://github.com/FiloSottile/age) to manage encrypted secrets.

To decrypt files in our repositories, you must have your private age key configured.

## 1. Setup Age Key File

SOPS looks for age keys in a specific text file. The standard location is:

`~/.config/sops/age/keys.txt`

### Format of `keys.txt`

The file should contain your private key in the following format:

```text
# created: 2024-01-01T00:00:00Z
# public key: age1...
AGE-SECRET-KEY-1...
```

## 2. Automatic Configuration

The `modern-resume-env` development environment (`flake.nix`) automatically exports the `SOPS_AGE_KEY_FILE` environment variable if it finds the file at `~/.config/sops/age/keys.txt`.

If the file is present, you can run SOPS commands directly:

```bash
sops -d path/to/encrypted/file.enc.yaml
```

## 3. Manual Configuration

If you prefer to store your keys in a different location, you must manually export the `SOPS_AGE_KEY_FILE` variable in your shell:

```bash
export SOPS_AGE_KEY_FILE="/path/to/your/custom/keys.txt"
```

## 4. Troubleshooting

If you see an error like:
`FAILED TO DECRYPT: No identity matched any of the recipients`

It means either:

1. Your `SOPS_AGE_KEY_FILE` variable is not set correctly.
2. The `keys.txt` file does not contain a private key that matches any of the public keys used to encrypt the file.
3. You haven't been added to the `.sops.yaml` configuration for that file.

In this case, please contact a repository administrator to receive the necessary keys or to have your public key added to the encryption rules.

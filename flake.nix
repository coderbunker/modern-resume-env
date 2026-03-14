{
  description = "Modern Resume Shared Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw= rngadam.cachix.org-1:1xP33wKk+G09q9H/Eih5f9b1c1Wn1Q3B8N4N+Wn/7pE=";
    extra-substituters = "https://devenv.cachix.org https://rngadam.cachix.org";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    let
      flake = flake-parts.lib.mkFlake { inherit inputs; } {
        imports = [
          inputs.devenv.flakeModule
        ];
        systems = nixpkgs.lib.systems.flakeExposed;

        perSystem = { config, self', inputs', system, ... }:
          let
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };

            # Infrastructure packages
            ovhcloud = pkgs.buildGoModule rec {
              pname = "ovhcloud-cli";
              version = "0.9.0";
              src = pkgs.fetchFromGitHub {
                owner = "ovh";
                repo = "ovhcloud-cli";
                rev = "v${version}";
                sha256 = "0kvd2r0ah6zjn0plz3nk7yzn5zmc1df5xfsjlz5f27fpaa62jzvx";
              };
              vendorHash = "sha256-WNONEceR/cDVloosQ/BMYjPTk9elQ1oTX89lgzENSAI=";
              ldflags = [ "-X github.com/ovh/ovhcloud-cli/internal/version.Version=${version}" ];
              doCheck = false;
            };

            # Standard Version Script (Public) - Now dynamic
            baseVersions = pkgs.writeShellScriptBin "versions" ''
              ${pkgs.bash}/bin/bash ${./scripts/versions.sh}
            '';

            checkNonWestern = pkgs.writeShellScriptBin "check-non-western" ''
              ${pkgs.python3}/bin/python3 ${./scripts/check-non-western.py} "$@"
            '';

            # Package Groups for mixing and matching
            pkgsGroup = {
              core = [
                pkgs.direnv
                pkgs.tree
                pkgs.jq
                pkgs.gettext
                pkgs.bc
                pkgs.openssl
              ];

              runtime = [
                pkgs.bun
                pkgs.nodejs_24
                pkgs.go
                pkgs.python3
              ];

              cicd = [
                pkgs.awscli2
                pkgs.gh
                pkgs.skopeo
                pkgs.cosign
                pkgs.pre-commit
                ovhcloud
                pkgs.regctl
                pkgs.kubeconform
                pkgs.sops
                pkgs.age
                pkgs.yq-go
                pkgs.rclone
              ];

              docker = [
                pkgs.docker
                pkgs.docker-compose
                pkgs.docker-buildx
              ];

              lint = [
                pkgs.yamllint
                pkgs.shellcheck
                pkgs.shfmt
                pkgs.markdownlint-cli
                pkgs.hadolint
                pkgs.actionlint
                pkgs.nixpkgs-fmt
                pkgs.eslint
                checkNonWestern
              ];

              db = [
                pkgs.postgresql
                pkgs.dnsutils
              ];
            };

            shellUtils = ''
              # Helper for interactive logging
              log_interactive() {
                if [ -t 1 ]; then echo -e "$@" >&2; fi
              }
            '';

            setupHooks = ''
              # Setup git hooks (only if pre-commit and git are available)
              if [ -d ".git" ] && command -v pre-commit >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
                ${pkgs.bash}/bin/bash ${./scripts/setup-hooks.sh}
              fi
            '';

            lib = {
              inherit pkgsGroup shellUtils setupHooks;
            };

          in
          {
            # Export lib as legacyPackages for extraction at top-level
            legacyPackages.lib = lib;

            packages = {
              versions = baseVersions;
              check-non-western = checkNonWestern;
              ovhcloud = ovhcloud;
            };

            devenv.shells.default = {
              # Enable devenv's language features for better DX
              languages.javascript = {
                enable = true;
                package = pkgs.nodejs_24;
                bun.enable = true;
              };
              languages.python.enable = true;
              languages.go.enable = true;

              # Enable postgresql service (developer DX)
              services.postgres = {
                enable = true;
                package = pkgs.postgresql;
                initialDatabases = [ { name = "modern_resume"; } ];
              };

              packages = [
                pkgs.direnv
                pkgs.tree
                pkgs.jq
                pkgs.gettext
                pkgs.bc
                pkgs.openssl

                pkgs.awscli2
                pkgs.gh
                pkgs.skopeo
                pkgs.cosign
                pkgs.pre-commit
                ovhcloud
                pkgs.regctl
                pkgs.kubeconform
                pkgs.sops
                pkgs.age
                pkgs.yq-go
                pkgs.rclone

                pkgs.docker
                pkgs.docker-compose
                pkgs.docker-buildx

                pkgs.yamllint
                pkgs.shellcheck
                pkgs.shfmt
                pkgs.markdownlint-cli
                pkgs.hadolint
                pkgs.actionlint
                pkgs.nixpkgs-fmt
                pkgs.eslint
                checkNonWestern

                pkgs.dnsutils

                baseVersions
              ] ++ (if system == "aarch64-darwin" || system == "x86_64-darwin" then [ ] else [
                pkgs.stdenv.cc.cc.lib
                pkgs.glibc
              ]);

              enterShell = shellUtils + ''
                # Setup docker-buildx plugin (only if binary is available)
                if command -v docker-buildx >/dev/null 2>&1; then
                  export DOCKER_CONFIG="$PWD/.docker-nix"
                  mkdir -p "$DOCKER_CONFIG/cli-plugins"
                  ln -sf "$(command -v docker-buildx)" "$DOCKER_CONFIG/cli-plugins/docker-buildx"
                fi

                # Automatic KUBECONFIG discovery (only if kubectl is available)
                if command -v kubectl >/dev/null 2>&1; then
                  if [ -z "$KUBECONFIG" ]; then
                    if [ -f "$PWD/kubeconfig.yaml" ]; then export KUBECONFIG="$PWD/kubeconfig.yaml"
                    elif [ -f "$PWD/kubeconfig.yml" ]; then export KUBECONFIG="$PWD/kubeconfig.yml"
                    fi
                  fi
                fi

                # SOPS Age Key discovery
                if [ -f "$HOME/.config/sops/age/keys.txt" ]; then
                  export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
                else
                  log_interactive "\033[1;33mWarning: SOPS age key not found at ~/.config/sops/age/keys.txt\033[0m"
                  log_interactive "To configure SOPS, see: \033[1;34mhttps://github.com/coderbunker/modern-resume-env/blob/main/docs/SOPS.md\033[0m"
                fi

                ${setupHooks}

                log_interactive "\033[1;32mModern Resume Shared Development Environment Loaded\033[0m"
              '';
            };
          };
      };
    in
    flake // {
      # Re-export lib at the top-level mapping system -> lib to maintain backwards compatibility
      lib = builtins.mapAttrs (system: legacyPackages: legacyPackages.lib) flake.legacyPackages;
    };
}

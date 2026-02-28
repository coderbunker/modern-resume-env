{
  description = "Modern Resume Shared Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      # system-specific outputs
      eachSystem = flake-utils.lib.eachDefaultSystem (system:
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
            ];

            db = [
              pkgs.postgresql
              pkgs.dnsutils
            ];
          };

          allPkgs = pkgsGroup.core
            ++ pkgsGroup.runtime
            ++ pkgsGroup.cicd
            ++ pkgsGroup.docker
            ++ pkgsGroup.lint
            ++ pkgsGroup.db;

          # Standard Version Script (Public) - Now dynamic
          baseVersions = pkgs.writeShellScriptBin "versions" ''
            ${pkgs.bash}/bin/bash ${./scripts/versions.sh}
          '';

        in
        {
          packages = {
            versions = baseVersions;
            ovhcloud = ovhcloud;
          };

          devShells.default = pkgs.mkShell {
            buildInputs = allPkgs ++ [
              self.packages.${system}.versions
            ] ++ (if system == "aarch64-darwin" || system == "x86_64-darwin" then [ ] else [
              pkgs.stdenv.cc.cc.lib
              pkgs.glibc
            ]);

            shellHook = ''
              # Helper for interactive logging
              log_interactive() {
                if [ -t 1 ]; then echo -e "$@" >&2; fi
              }

              # Setup docker-buildx plugin
              export DOCKER_CONFIG="$PWD/.docker-nix"
              mkdir -p "$DOCKER_CONFIG/cli-plugins"
              ln -sf "${pkgs.docker-buildx}/bin/docker-buildx" "$DOCKER_CONFIG/cli-plugins/docker-buildx"

              # Automatic KUBECONFIG discovery
              if [ -z "$KUBECONFIG" ]; then
                if [ -f "$PWD/kubeconfig.yaml" ]; then export KUBECONFIG="$PWD/kubeconfig.yaml"
                elif [ -f "$PWD/kubeconfig.yml" ]; then export KUBECONFIG="$PWD/kubeconfig.yml"
                fi
              fi

              # Setup git hooks
              ${builtins.toString ./scripts/setup-hooks.sh}

              log_interactive "\033[1;32mModern Resume Shared Environment Loaded\033[0m"
            '';
          };

          # Export lib inside each system too
          lib.pkgsGroup = pkgsGroup;
        }
      );
    in
    eachSystem // {
      # Top-level lib for easier access
      lib = eachSystem.lib;
    };
}

{
  description = "Modern Resume Shared Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Infrastructure packages
        ovh-cli = pkgs.buildGoModule rec {
          pname = "ovhcloud-cli";
          version = "0.9.0";
          src = pkgs.fetchFromGitHub {
            owner = "ovh";
            repo = "ovhcloud-cli";
            rev = "v${version}";
            sha256 = "0kvd2r0ah6zjn0plz3nk7yzn5zmc1df5xfsjlz5f27fpaa62jzvx";
          };
          vendorHash = "sha256-WNONEceR/cDVloosQ/BMYjPTk9elQ1oTX89lgzENSAI=";
          doCheck = false;
        };

        # Standard Version Script (Public)
        baseVersions = pkgs.writeShellScriptBin "versions" ''
          jq -n \
            --arg bun "$(bun --version)" \
            --arg node "$(node --version | sed 's/^v//')" \
            --arg go "$(go version | awk '{print $3}' | sed 's/^go//' 2>/dev/null || echo 'N/A')" \
            --arg postgres "$(psql --version | awk '{print $3}' 2>/dev/null || echo 'N/A')" \
            --arg docker "$(docker --version | awk '{print $3}' | sed 's/,//' 2>/dev/null || echo 'N/A')" \
            --arg compose "$(docker compose version --short 2>/dev/null || echo 'N/A')" \
            --arg kubectl "$(kubectl version --client --output=json 2>/dev/null | jq -r ".clientVersion.gitVersion" || echo 'N/A')" \
            --arg helm "$(helm version --short 2>/dev/null || echo 'N/A')" \
            --arg aws "$(aws --version 2>&1 | awk '{print $1}' | cut -d/ -f2 2>/dev/null || echo 'N/A')" \
            --arg gh "$(gh --version | head -n1 | awk '{print $3}')" \
            --arg skopeo "$(skopeo --version | awk '{print $3}')" \
            --arg precommit "$(pre-commit --version | awk '{print $2}')" \
            --arg ovh "$(${ovh-cli}/bin/ovhcloud version | awk '{print $3}' 2>/dev/null || echo 'N/A')" \
            --arg regctl "$(regctl version --format '{{.VCSTag}}' 2>/dev/null || echo 'N/A')" \
            --arg kubeconform "$(kubeconform -v | awk '{print $2}' 2>/dev/null || echo 'N/A')" \
            '{
              bun: $bun,
              node: $node,
              go: $go,
              postgres: $postgres,
              docker: $docker,
              compose: $compose,
              kubectl: $kubectl,
              helm: $helm,
              aws: $aws,
              gh: $gh,
              skopeo: $skopeo,
              precommit: $precommit,
              ovh: $ovh,
              regctl: $regctl,
              kubeconform: $kubeconform
            }'
        '';

      in
      {
        packages = {
          versions = baseVersions;
          ovhcloud-cli = ovh-cli;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Runtime
            bun
            nodejs_24
            go

            # CI/CD & Deployment Tools
            kubectl
            kubernetes-helm
            awscli2
            gh
            skopeo
            cosign
            pre-commit
            ovh-cli
            regctl
            kubeconform

            # Docker tools
            docker
            docker-compose
            docker-buildx

            # Linting & Formatting
            jq
            yamllint
            shellcheck
            shfmt
            markdownlint-cli
            nixpkgs-fmt

            # Database / Misc
            postgresql
            openssl
            gettext
            bc
            dnsutils

            # Shared Helpers
            self.packages.${system}.versions
          ] ++ (if system == "aarch64-darwin" || system == "x86_64-darwin" then [ ] else [
            stdenv.cc.cc.lib
            glibc
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
      }
    );
}

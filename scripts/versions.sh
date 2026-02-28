#!/usr/bin/env bash

# versions.sh - Dynamically detect and report tool versions in JSON format.

# Helper to get version safely
get_version() {
	local cmd=$1
	local version_args=$2
	local filter=$3

	if command -v "$cmd" >/dev/null 2>&1; then
		local version_output
		if version_output=$($cmd "$version_args" 2>&1); then
			echo "$version_output" | eval "$filter"
		else
			echo "N/A"
		fi
	else
		echo "N/A"
	fi
}

# Collect versions into a JSON object using jq
jq -n \
	--arg bun "$(get_version "bun" "--version" "cat")" \
	--arg node "$(get_version "node" "--version" "sed 's/^v//'")" \
	--arg go "$(get_version "go" "version" "awk '{print \$3}' | sed 's/^go//'")" \
	--arg python "$(get_version "python3" "--version" "awk '{print \$2}'")" \
	--arg psql "$(get_version "psql" "--version" "awk '{print \$3}'")" \
	--arg docker "$(get_version "docker" "--version" "awk '{print \$3}' | sed 's/,//'")" \
	--arg compose "$(get_version "docker" "compose version --short" "cat")" \
	--arg buildx "$(get_version "docker" "buildx version" "awk '{print \$2}'")" \
	--arg kubectl "$(get_version "kubectl" "version --client --output=json" "jq -r '.clientVersion.gitVersion'")" \
	--arg helm "$(get_version "helm" "version --short" "sed 's/^v//'")" \
	--arg aws "$(get_version "aws" "--version" "awk '{print \$1}' | cut -d/ -f2")" \
	--arg gh "$(get_version "gh" "--version" "head -n1 | awk '{print \$3}' | sed 's/^v//'")" \
	--arg skopeo "$(get_version "skopeo" "--version" "awk '{print \$3}'")" \
	--arg cosign "$(get_version "cosign" "version" "grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1")" \
	--arg precommit "$(get_version "pre-commit" "--version" "awk '{print \$2}'")" \
	--arg ovhcloud "$(get_version "ovhcloud" "version --json" "jq -r '.[0].version'")" \
	--arg regctl "$(get_version "regctl" "version --format '{{.VCSTag}}'" "sed \"s/'//g\" | sed 's/^v//'")" \
	--arg kubeconform "$(get_version "kubeconform" "-v" "awk '{print \$2}'")" \
	--arg sops "$(get_version "sops" "--version" "grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1")" \
	--arg age "$(get_version "age" "--version" "cat")" \
	--arg yq "$(get_version "yq" "--version" "awk '{print \$4}'")" \
	--arg rclone "$(get_version "rclone" "--version" "head -n1 | awk '{print \$2}'")" \
	--arg yamllint "$(get_version "yamllint" "--version" "awk '{print \$2}'")" \
	--arg shellcheck "$(get_version "shellcheck" "--version" "grep -oE '[0-9]+\.[0-9]+\.[0-9]+'")" \
	--arg shfmt "$(get_version "shfmt" "--version" "sed 's/^v//'")" \
	--arg markdownlint "$(get_version "markdownlint" "--version" "cat")" \
	--arg hadolint "$(get_version "hadolint" "--version" "awk '{print \$4}'")" \
	--arg actionlint "$(get_version "actionlint" "--version" "head -n1")" \
	--arg nixpkgsfmt "$(get_version "nixpkgs-fmt" "--version" "cat")" \
	--arg eslint "$(get_version "eslint" "--version" "sed 's/^v//'")" \
	--arg dig "$(get_version "dig" "-v" "awk '{print \$2}'")" \
	'{
        bun: $bun,
        node: $node,
        go: $go,
        python: $python,
        postgres: $psql,
        docker: $docker,
        compose: $compose,
        buildx: $buildx,
        kubectl: $kubectl,
        helm: $helm,
        aws: $aws,
        gh: $gh,
        skopeo: $skopeo,
        cosign: $cosign,
        precommit: $precommit,
        ovhcloud: $ovhcloud,
        regctl: $regctl,
        kubeconform: $kubeconform,
        sops: $sops,
        age: $age,
        yq: $yq,
        rclone: $rclone,
        yamllint: $yamllint,
        shellcheck: $shellcheck,
        shfmt: $shfmt,
        markdownlint: $markdownlint,
        hadolint: $hadolint,
        actionlint: $actionlint,
        nixpkgsfmt: $nixpkgsfmt,
        eslint: $eslint,
        dig: $dig
    }' | jq 'with_entries(select(.value != "N/A" and .value != ""))'

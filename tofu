#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="compose.yml"
SERVICE="tofu"
IMAGE_NAME="catena-tofu-test"
WORKDIR="/workspace/opentofu"
BUILDER_SERVICE="builder"
BUILDER_IMAGE="catena-builder"
# TF_VAR_workspace_dir="${PWD}"
TF_VAR_workspace_dir="/workspace"
dc() {
	docker compose -f "$COMPOSE_FILE" "$@"
}

load_tofu_env() {
	if [[ -f "$dirpath/tofu.env" ]]; then
		set -a
		. "$dirpath/tofu.env"
		set +a
	fi
}

ensure_built() {
	if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
		echo "[tofu] Building container image $IMAGE_NAME ..."
		dc build
	fi
}

ensure_builder_built() {
	if ! docker image inspect "$BUILDER_IMAGE" >/dev/null 2>&1; then
		echo "[tofu] Building builder image $BUILDER_IMAGE ..."
		dc build "$BUILDER_SERVICE"
	fi
}

run_in_container() {
	ensure_built
	# Load local secrets/config and map app secret to OpenTofu variable when present.
	load_tofu_env
	local env_args=( -e "TF_VAR_workspace_dir=$TF_VAR_workspace_dir" )
	if [[ -n "${OPENAI_API_KEY:-}" ]]; then
		export TF_VAR_openai_api_key="$OPENAI_API_KEY"
		env_args+=( -e "TF_VAR_openai_api_key=$TF_VAR_openai_api_key" )
	fi
	# Service config already sets working_dir; override if needed
	dc run --rm "${env_args[@]}" "$SERVICE" "$@"
}

usage() {
	cat <<USAGE
Usage:
	./tofu [plan|apply|destroy|init|version|...] [args...]

Project commands:
	./tofu build       Build provider binary inside container and docker image
	./tofu setup       Build image (if needed) and run 'tofu init'
	./tofu run         Apply current stack (tofu apply -auto-approve)
	./tofu stop        Destroy current stack (tofu destroy -auto-approve)

Dev utilities:
	./tofu --shell [bash|sh]   Start an interactive shell in the tofu container
	./tofu --it [bash|sh]       Alias for --shell
	./tofu --inject [bash|sh]  Alias for --shell

Examples:
	./tofu plan
	./tofu apply
	./tofu apply -destroy   # equivalent to ./tofu destroy
	./tofu init
USAGE
}
dirpath="$(dirname "$(readlink -f "$0")")"
cmd=${1:-}
case "$cmd" in
	build)
		shift || true
		echo "[tofu] Building provider binary inside container (Go+Make)..."
		ensure_builder_built
		# Conditionally generate protobuf stubs if missing
		if ! ls internal/genproto/*.pb.go >/dev/null 2>&1; then
			echo "[tofu] Protobuf stubs not found; running 'make proto-gen'..."
			dc run --rm "$BUILDER_SERVICE" make proto-gen
		else
			echo "[tofu] Protobuf stubs already present; skipping generation."
		fi
		dc run --rm "$BUILDER_SERVICE" make build
		
		echo "[tofu] Building runtime docker image..."
		dc build
		;;
	--shell |--inject |--it )
		shift || true
		ensure_built
		shell_bin=${1:-bash}
		if [[ $# -gt 0 ]]; then shift; fi
		echo "[tofu] Opening interactive shell ($shell_bin) in container..."
		dc run --rm -it --entrypoint "/bin/${shell_bin}" "$SERVICE" "$@"
		;;
	setup)
		shift || true
		echo "[tofu] Setting user environment variables from tofu.env..."
		load_tofu_env
		# echo "[tofu] Ensuring docker image is built, then running 'tofu init'..."
		# rm -f opentofu/.terraform.lock.hcl
		ensure_built
		run_in_container init "$@" -backend-config=username=$USERNAME -backend-config=password=$PASSWORD -reconfigure
		;;
	run|start)
		shift || true
		echo "[tofu] Running 'tofu apply -auto-approve'..."
		run_in_container apply -auto-approve "$@"
		;;
	end|stop)
		shift || true
		echo "[tofu] Running 'tofu destroy -auto-approve'..."
		run_in_container destroy -auto-approve "$@"
		# use docker to remove the /dev/shm/mxl content
		# dc run --rm "$BUILDER_SERVICE" rm -rf /dev/shm/mxl/* || true
		;;
	plan|apply|destroy|init|version|fmt|validate|state|providers|output|graph|workspace|taint|untaint|show)
		# Pass-through OpenTofu commands
		shift || true
		if [[ "$cmd" == "init" ]]; then
			rm -f opentofu/.terraform.lock.hcl
		fi
		# Special-case: support `./tofu apply -destroy` as destroy
		if [[ "$cmd" == "apply" && "${1:-}" == "-destroy" ]]; then
			shift
			run_in_container destroy "$@"
		else
			run_in_container "$cmd" "$@"
		fi
		;;
	-h|--help|help|"")
		usage
		;;
	*)
		# Default: pass through any other tofu subcommand
		run_in_container "$@"
		;;
esac
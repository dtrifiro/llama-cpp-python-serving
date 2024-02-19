#!/bin/bash
# Deploys the InferenceService/ServingRuntime and waits for it to be ready
set -euxo pipefail

ISVC_NAME="isvc/llama-cpp-python"

function usage() {
	echo "Usage: $(basename "$0") [cpu|gpu]"
}

if [[ -z $* ]]; then
	usage
	exit 1
fi

if ! [[ $1 = "cpu" || $1 = "gpu" ]]; then
	usage
	exit 1
fi

kubectl kustomize "manifests/$1" | kubectl apply -f -

# wait for the isvc to be up
max_retries=10
until kubectl wait --for=condition=Ready $ISVC_NAME --timeout 60s; do
	echo "- Waiting for InferenceService to be up"
	kubectl describe $ISVC_NAME
	max_retries=$((max_retries - 1))
	if [[ ${max_retries} -le 0 ]]; then
		echo "- Timeout waiting for InferenceService"
		exit 1
	fi
done

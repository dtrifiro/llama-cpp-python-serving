#!/bin/bash
# Set ups a PV with a model and waits for it to be ready
#
# Usage:
#   bash scripts/setup_model.sh
# or
#   bash scripts/setup_model manifests/models/mixtral-8x7b-instruct

if [[ -n $1 ]]; then
	kustomize_path="$1"
else
	kustomize_path="manifests/models/mistral-7b-q2k-extra-small"
fi

set -eux -o pipefail

pod="pod/setup-model"
# Create a PVC and schedule a pod to download the model
kubectl kustomize "${kustomize_path}" | kubectl apply -f -

# Wait for the model to be downloaded:
max_retries=20
until kubectl wait --for=jsonpath='{.status.phase}'=Succeeded $pod --timeout 60s; do
	echo "- Waiting for model to be set up"
	kubectl describe $pod
	kubectl logs $pod
	max_retries=$((max_retries - 1))
	if [[ ${max_retries} -le 0 ]]; then
		echo "- Timeout waiting for model"
		exit 1
	fi
done

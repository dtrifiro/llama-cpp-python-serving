#!/bin/bash
# Set ups a PV with a model and waits for it to be ready

set -eux -o pipefail

pod="pod/setup-mistral-7b-q2k-extra-small"
# Create a PVC and schedule a pod to download the model
kubectl apply -f manifests/setup-model.yaml

# Wait for the model to be downloaded:
max_retries=10
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

#!/bin/bash
set -eux -o pipefail

# Create a PVC and schedule a pod to download the model
kubectl apply -f setup-model.yaml
# Wait for the model to be downloaded:
kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/setup-mistral-7b-q2k-extra-small --timeout 300s

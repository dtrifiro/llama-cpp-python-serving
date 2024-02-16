#!/bin/bash
set -euxo pipefail

ISVC_URL=$(kubectl get isvc llama-cpp-python -o jsonpath='{.status.components.predictor.url}')

curl -k \
	-H 'Content-type: application/json' \
	-d '{"text": "The quick brown fox"}' \
	"${ISVC_URL}/v1/completions"

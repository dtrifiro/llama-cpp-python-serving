#!/bin/bash
if [[ -n $* ]]; then
	text="$*"
else
	text="The quick brown fox"
fi

set -euxo pipefail

ISVC_URL=$(kubectl get isvc llama-cpp-python -o jsonpath='{.status.components.predictor.url}')

curl -k \
	-H 'Content-type: application/json' \
	-d '{"text": "'"${text}"'"}' \
	"${ISVC_URL}/v1/completions"

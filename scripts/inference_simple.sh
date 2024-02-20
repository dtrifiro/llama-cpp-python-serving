#!/bin/bash
if [[ -n $* ]]; then
	text="$*"
else
	text="The quick brown fox"
fi

set -euxo pipefail

ISVC_URL=$(kubectl get isvc llama-cpp-python -o jsonpath='{.status.components.predictor.url}')

curl -sk \
	-H 'Content-type: application/json' \
	-d '{
        "prompt": "'"${text}"'",
        "stop": "\n"
    }' \
	"${ISVC_URL}/v1/completions"

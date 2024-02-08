import sys

import os
from openai import OpenAI

inference_service_url = os.getenv("ISVC_URL")


if not inference_service_url:
    print(
        "Set ISVC_URL by running: `export ISVC_URL=$(oc get isvc llama-cpp-python -o jsonpath='{.status.components.predictor.url}')`",
        file=sys.stderr,
    )
    sys.exit(1)


client = OpenAI(
    base_url=f"{inference_service_url}/v1/",
    api_key="dummy",
)
response = client.completions.create(
    model="mistral-7b-q2k-extra-small",  # currently can be anything
    prompt="The quick brown fox jumps",
)
print(response.json())

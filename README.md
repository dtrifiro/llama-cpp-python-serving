# llama-cpp-python serving

Serving Large Language Models model using [kserve](https://kserve.github.io/website/latest/) and [llama-cpp-python](https://github.com/abetlet/llama-cpp-python).

See llama.cpp's [docs](https://github.com/ggerganov/llama.cpp?tab=readme-ov-file#description) for a list of supported models

[![Docker Repository on Quay](https://quay.io/repository/dtrifiro/llama-cpp-python-serving/status "Docker Repository on Quay")](https://quay.io/repository/dtrifiro/llama-cpp-python-serving)

## Requirements

- `kserve` See the [getting started guide](https://kserve.github.io/website/latest/get_started/)

## Getting Started

`llama.cpp` uses [ggml](https://github.com/ggerganov/ggml) as model format (`.gguf` extensions). So models will have to be converted to this format, see the [guide](https://github.com/ggerganov/llama.cpp?tab=readme-ov-file#prepare-and-quantize) or use pre-converted models.

This example uses `mistral-7b-q2k-extra-small.gguf` from [ikawrakow/mistral-7b-quantized-gguf](https://huggingface.co/ikawrakow/mistral-7b-quantized-gguf]).

```bash
# Create a PVC and schedule a pod to download the model
kubectl apply -f setup-model.yaml
# Wait for the model to be downloaded:
kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/setup-mistral-7b-q2k-extra-small  --timeout 300s
# Create the ServingRuntime/InferenceService
kubectl apply -f llama-cpp-isvc.yaml -f llama-cpp-servingruntime.yaml

# wait for the InferenceService to come up
oc wait --for=condition=Ready isvc/llama-cpp-python --timeout 300s

# Check that the model is available:
curl -k ${ISVC_URL}/v1/models

# perform inference
curl -k ${ISVC_URL}/v1/completions text="The quick brown fox"
```

Note that since the llama-cpp-python application uses [fastapi](https://github.com/tiangolo/fastapi) and [swagger](https://swagger.io/), the server exposes a `/docs` endpoint with exposed endpoints as well
as an OpenAPI spec at `/openapi.json`:

```bash
xdg-open ${ISVC_URL}/docs # linux
open ${ISVC_URL}/docs # MacOS
```

### Using the OpenAI python api

**Note:** OpenAI uses [httpx](https://pypi.org/project/httpx/) and [certifi](https://pypi.org/project/certifi/) to perform requests. It seems like it's not currently possible to perform queries disabling TLS verification.

```bash
# (Optional) Set up a virtualenv for inference
python -m venv .venv
source .venv/bin/activate

pip install openai

# perform inference
export ISVC_URL=$(oc get isvc llama-cpp-python -o jsonpath='{.status.components.predictor.url}')
python examples/inference.py
```

#### Hack

This makes it possible to use a self signed certificate with the OpenAI API:

```bash
python utils/server_cert.py ${ISVC_URL}
cat *pem >> .venv/lib/*/site-packages/certifi/cacert.pem

python examples/inference.py
```

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest as builder

RUN microdnf -y update && \
    microdnf -y install \
        git gcc-toolset-12-gcc-c++ gcc-toolset-12 cmake shadow-utils python3.11-pip && \
    pip3.11 install --no-cache-dir --upgrade pip wheel && \
    microdnf clean all

ENV POETRY_VIRTUALENVS_IN_PROJECT=1


WORKDIR /llama-cpp-python
COPY pyproject.toml .
COPY poetry.lock .

ENV CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS"
RUN pip3.11 install poetry && \
    scl enable gcc-toolset-12 -- poetry install


FROM registry.access.redhat.com/ubi9/ubi-minimal:latest as deploy

RUN microdnf -y update && \
    microdnf -y install \
        shadow-utils python3.11 && \
    microdnf clean all

WORKDIR /llama-cpp-python

COPY --from=builder /llama-cpp-python/.venv /llama-cpp-python/.venv

ENV VIRTUAL_ENV=/llama-cpp-python/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN groupadd --system llama --gid 1001 && \
    adduser --system --uid 1001 --gid 0 --groups llama \
    --create-home --home-dir /llama-cpp-python --shell /sbin/nologin \
    --comment "Llama user" llama

USER llama

# TODO: configuration
ENTRYPOINT ["python", "-m", "llama_cpp.server"]

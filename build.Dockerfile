ARG ELIXIR_VERSION=1.14.3
ARG OTP_VERSION=25.2.3
ARG RUST_VERSION=1.67.1
ARG DEBIAN_VERSION=bullseye-20230202-slim

ARG BUILDER_IMAGE="docker.io/hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE}

RUN apt-get update -y && \
  apt-get install -y --no-install-recommends \
    build-essential \
    git \
    ca-certificates \
    curl \
    unzip \
    && \
  apt-get clean && \
  rm -f /var/lib/apt/lists/*_*

ARG RUST_VERSION

ENV RUSTUP_HOME=/root/.rustup \
    CARGO_HOME=/root/.cargo \
    PATH=$PATH:/root/.cargo/bin

RUN curl https://sh.rustup.rs -sSf | sh -s -- --profile minimal --default-toolchain ${RUST_VERSION} --no-modify-path -y

ENV PATH=$PATH:/root/.dprint/bin

RUN curl -fsSL https://dprint.dev/install.sh | sh

CMD ["iex"]

ARG ELIXIR_VERSION=1.14.3
ARG OTP_VERSION=25.0.4
ARG DEBIAN_VERSION=bullseye-20220801-slim

ARG BUILDER_IMAGE="docker.io/hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"

ARG DPRINT_VERSION=0.34.1
ARG DPRINT_SHA256=43dd4bab71f3a70738670ef51f1e54c84b89405d9dfe5bec6ae5199ca20c93fe

FROM ${BUILDER_IMAGE}

# install build dependencies
RUN apt-get update -y && \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    build-essential \
    unzip \
    pkg-config \
    libvips-dev \
    && \
  apt-get clean && \
  rm -f /var/lib/apt/lists/*_*

ARG DPRINT_VERSION
ARG DPRINT_SHA256

# Install https://github.com/dprint/dprint
ADD "https://github.com/dprint/dprint/releases/download/${DPRINT_VERSION}/dprint-x86_64-unknown-linux-gnu.zip" /tmp/dprint.zip
RUN echo "${DPRINT_SHA256} /tmp/dprint.zip" | sha256sum --check --status && \
    unzip /tmp/dprint.zip -d /usr/bin && \
    chmod +x /usr/bin/dprint && \
    rm /tmp/dprint.zip

CMD ["iex"]

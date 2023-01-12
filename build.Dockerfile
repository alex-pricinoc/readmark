ARG ELIXIR_VERSION=1.14.2
ARG OTP_VERSION=25.0.4
ARG ALPINE_VERSION=3.16.1

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-alpine-${ALPINE_VERSION}"

ARG DPRINT_VERSION=0.34.1
ARG DPRINT_SHA256=dd5833178a7986acaeea8abbac687754f3ee7ce39371ac55c3e17113938027c9

FROM ${BUILDER_IMAGE}

ARG DPRINT_VERSION
ARG DPRINT_SHA256

# Install https://github.com/dprint/dprint
ADD "https://github.com/dprint/dprint/releases/download/${DPRINT_VERSION}/dprint-x86_64-unknown-linux-musl.zip" /tmp/dprint.zip
RUN echo "${DPRINT_SHA256}  /tmp/dprint.zip" | sha256sum -c -s && \
    unzip /tmp/dprint.zip -d /usr/bin && \
    chmod +x /usr/bin/dprint && \
    rm /tmp/dprint.zip

RUN apk update && \
  apk add git gcc musl-dev make tar vips-dev && \
  rm -rf /var/cache/apk/*

CMD ["iex"]

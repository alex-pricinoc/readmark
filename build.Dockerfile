ARG ELIXIR_VERSION=1.14.2
ARG OTP_VERSION=25.0.4
ARG DEBIAN_VERSION=bullseye-20220801-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE}

# install build dependencies
RUN apt-get update -y
RUN apt-get install -y build-essential git curl unzip
RUN apt-get install -y --no-install-recommends libvips-dev pkg-config
RUN apt-get clean && rm -f /var/lib/apt/lists/*_*

# install dprint code formatter
RUN curl -fsSL https://dprint.dev/install.sh | sh
ENV DPRINT_INSTALL="/root/.dprint"
ENV PATH="$DPRINT_INSTALL/bin:$PATH"

# install hex + rebar
RUN mix local.hex --force && mix local.rebar --force

CMD ["iex"]

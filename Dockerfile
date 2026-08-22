# syntax=docker/dockerfile:1
#
# Builds a Pan (Panoptikum) release for the QA environment.
# Intended to be built ON the target QA server, where a real
# config/qa.secret.exs already exists (see config/qa.secret.exs.example) —
# it gets baked into the release at build time, same convention as the
# existing bare-metal prod deploy.

ARG ELIXIR_VERSION=1.19.5
ARG OTP_VERSION=28.4.2
ARG DEBIAN_VERSION=bookworm-20250520-slim
# Check https://hub.docker.com/r/hexpm/elixir/tags for a matching
# elixir/otp/debian combination if this tag doesn't exist (hexpm only
# keeps recent Debian snapshot dates around).
ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"
ARG MIX_ENV=qa

# ---- Build stage ----
FROM ${BUILDER_IMAGE} AS builder
ARG MIX_ENV

RUN apt-get update -y && apt-get install -y --no-install-recommends \
      build-essential git curl ca-certificates nodejs npm \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV MIX_ENV=${MIX_ENV}

RUN mix local.hex --force && mix local.rebar --force

# Deps first, so this layer is cached unless mix.exs/mix.lock change
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

# JS deps + asset build (tailwind CLI comes from npm, see config/config.exs)
COPY assets assets
RUN npm install --prefix assets

COPY priv priv
COPY lib lib
RUN mix assets.deploy

RUN mix compile
RUN mix release

# ---- Runtime stage ----
FROM ${RUNNER_IMAGE} AS runner
ARG MIX_ENV

RUN apt-get update -y && apt-get install -y --no-install-recommends \
      libstdc++6 openssl libncurses6 locales ca-certificates tzdata \
      imagemagick \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV MIX_ENV=${MIX_ENV}

RUN useradd --create-home --shell /bin/bash pan
WORKDIR /app

# Matches the hardcoded upload path in lib/pan_web/**/opml_controller.ex —
# created here (with the right owner) so the named volume mounted over it
# inherits these permissions on first run.
RUN mkdir -p /var/phoenix/pan-uploads && chown pan:pan /var/phoenix/pan-uploads

COPY --from=builder --chown=pan:pan /app/_build/${MIX_ENV}/rel/pan ./
COPY --chown=pan:pan docker/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

USER pan
EXPOSE 4000
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["start"]

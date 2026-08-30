# syntax=docker/dockerfile:1
#
# Builds a Pan (Panoptikum) release for the QA environment. Secrets are
# read at container start (config/runtime.exs, via docker-compose.yml's
# `environment:` — see .env.example), not baked into this image at build
# time — the build itself needs no secrets at all.

ARG ELIXIR_VERSION=1.19.5
ARG OTP_VERSION=28.4.2
# Matches the QA server's host OS (Ubuntu 24.04 "noble"). Check
# https://hub.docker.com/r/hexpm/elixir/tags for a current tag for this
# elixir/otp/ubuntu combination if this one no longer exists.
ARG UBUNTU_TAG=noble-20260509.1
ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-ubuntu-${UBUNTU_TAG}"
ARG RUNNER_IMAGE="ubuntu:24.04"
ARG MIX_ENV=qa

# ---- Build stage ----
FROM ${BUILDER_IMAGE} AS builder
ARG MIX_ENV

RUN apt-get update -y && apt-get install -y --no-install-recommends \
      build-essential git curl ca-certificates gnupg \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ubuntu's apt-packaged nodejs/npm is old enough (npm ~9.x) to hit a known
# npm optional-dependencies bug (npm/cli#4828) that drops platform-specific
# native packages like @tailwindcss/oxide-linux-x64-gnu. Install a current
# Node LTS from NodeSource instead.
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV MIX_ENV=${MIX_ENV}

RUN mix local.hex --force && mix local.rebar --force

# Deps first, so this layer is cached unless mix.exs/mix.lock change
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

# JS deps + asset build (tailwind CLI comes from npm, see config/config.exs).
# `npm ci` (not `npm install`) installs strictly from the lockfile, which
# also sidesteps the optional-dependency bug above.
COPY assets assets
RUN npm ci --prefix assets

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

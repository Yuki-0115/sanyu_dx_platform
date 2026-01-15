# syntax=docker/dockerfile:1

# ベースイメージ
ARG RUBY_VERSION=3.3.0
FROM ruby:${RUBY_VERSION}-slim AS base

# システムパッケージインストール
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
        build-essential \
        git \
        libyaml-dev \
        libpq-dev \
        postgresql-client \
        shared-mime-info \
        libvips42 \
        ca-certificates \
        curl \
        gnupg \
        less \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Node.js インストール
ARG NODE_VERSION=20
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g yarn

# 開発環境イメージ
FROM base AS development

# Railsインストール
ARG RAILS_VERSION=8.0.1
RUN gem install rails -v ${RAILS_VERSION} --no-document

# 作業ディレクトリ
WORKDIR /app

# デフォルトコマンド
CMD ["bash"]

# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.3.7
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment as default
ENV RAILS_ENV="production"
ARG BUNDLE_PATH_ARG=/usr/local/bundle
ENV BUNDLE_PATH=$BUNDLE_PATH_ARG
ENV BUNDLE_WITHOUT="development"
ENV BUNDLE_DEPLOYMENT="1"

# ───── Build stage ─────
FROM base AS build

# Install build dependencies (removed libpq-dev since we're using Firestore)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install gems
COPY Gemfile ./
COPY Gemfile.lock* ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application
COPY . .

# Precompile bootsnap code
RUN bundle exec bootsnap precompile app/ lib/

# Make binstubs executable
RUN chmod +x bin/* && \
    sed -i "s/\r$//g" bin/* && \
    sed -i 's/ruby\.exe$/ruby/' bin/*

# Skip asset precompilation for API-only server
# RUN SECRET_KEY_BASE_DUMMY=1 \
#     GOOGLE_CLOUD_PROJECT_ID=bandbrother2-dev \
#     RAILS_ENV=production \
#     DATABASE_URL=nulldb://user:pass@localhost/db \
#     ./bin/rails assets:precompile

# ───── Final runtime stage ─────
FROM base

# Firestore用の依存関係は既にGemでインストール済み
# PostgreSQL依存を削除

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Create non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp /usr/local/bundle
USER 1000:1000

# ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 8080
CMD ["sh", "-c", "./bin/thrust ./bin/rails server -b 0.0.0.0 -p ${PORT:-8080}"]

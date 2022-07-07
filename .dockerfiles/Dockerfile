ARG UBUNTU_VERSION

FROM ubuntu:$UBUNTU_VERSION AS base

ARG RUBY_VERSION
ARG PG_MAJOR
ARG NODE_MAJOR
ARG BUNDLER_VERSION
ARG YARN_VERSION
ARG PYTHON_VERSION
ARG USER

# install packages
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    build-essential \
    software-properties-common \
    postgresql-client-$PG_MAJOR \
    tzdata \
    libpq-dev \
    libv8-dev \
    ruby-svn \
    ghostscript \
    imagemagick \
    libmagickwand-dev \
    cmake \
    libaprutil1-dev \
    libssl-dev \
    swig \
    graphviz \
    git \
    python3-venv \
    python3-dev \
    pandoc \
    libgl1

# Install node
ADD https://deb.nodesource.com/setup_$NODE_MAJOR.x /tmp/setup_node.sh
RUN bash /tmp/setup_node.sh && DEBIAN_FRONTEND=noninteractive apt-get install -yq nodejs && rm /tmp/setup_node.sh

# Install yarn (see https://yarnpkg.com/getting-started/install)
RUN corepack enable && yarn set version $YARN_VERSION && yarn config set --home enableTelemetry 0

# Add ppa so that we can select different ruby versions and install ruby
RUN apt-add-repository -y ppa:brightbox/ruby-ng && \
    apt-get update -qq && \
    apt-get install -yq ruby$RUBY_VERSION ruby${RUBY_VERSION}-dev rubygems-integration && \
    apt-add-repository -y --remove ppa:brightbox/ruby-ng

# Add ppa so that we can get the right python version and install python
RUN apt-add-repository -y ppa:deadsnakes/ppa && \
    apt-get update -qq && apt-get install -yq --no-install-recommends python${PYTHON_VERSION} \
                                                python${PYTHON_VERSION}-venv \
                                                python${PYTHON_VERSION}-dev && \
    apt-add-repository -y --remove ppa:deadsnakes/ppa

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate -s 0 /var/log/*log

# Enable reading of PDF files with imagemagick
RUN sed -ri 's/(rights=")none("\s+pattern="PDF")/\1read\2/' /etc/ImageMagick-6/policy.xml

RUN useradd -m -s /bin/bash $USER

RUN ln -fs $(which python${PYTHON_VERSION}) /usr/bin/python3

ENV GEM_HOME="/bundle"
ENV PATH="$GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH"

WORKDIR /app

FROM base AS dev

ARG USER
ARG BUNDLER_VERSION
ARG RUBY_VERSION

# pre-create mount-points for volumes and set ownership of these mountpoints
RUN mkdir -p /bundle \
             /app/data/dev/repos \
             /app/tmp \
             /app/node_modules \
             /app/public/packs \
             /app/public/packs-test \
             /app/log \
             /app/venv && \
             chown -R $USER /bundle /app

USER $USER

# install bundler
RUN gem$RUBY_VERSION install bundler -v $BUNDLER_VERSION

FROM base AS prod

ARG USER
ARG BUNDLER_VERSION
ARG RUBY_VERSION

RUN mkdir -p /bundle /app /app/public && chown -R $USER /bundle /app

USER $USER

COPY --chown=${USER}:${USER} . /app
COPY --chown=${USER}:${USER} .dockerfiles/database.yml.postgresql /app/config/database.yml

# install python packages
RUN python${PYTHON_VERSION} -m venv /app/venv && \
    /app/venv/bin/pip install nbconvert==6.1.0

ENV RAILS_ENV=production
ENV NODE_ENV=production

# install bundler
RUN gem$RUBY_VERSION install bundler -v $BUNDLER_VERSION

RUN SECRET_KEY_BASE=1 bundle install --deployment --path $GEM_HOME --without development test offline mysql sqlite

RUN SECRET_KEY_BASE=1 NO_SCHEMA_VALIDATE=true PGDATABASE=dummy bundle exec rails i18n:js:export && \
    SECRET_KEY_BASE=1 NO_SCHEMA_VALIDATE=true PGDATABASE=dummy bundle exec rails assets:precompile

ARG UBUNTU_VERSION

FROM ubuntu:$UBUNTU_VERSION AS base

ARG RUBY_VERSION
ARG PG_MAJOR
ARG NODE_MAJOR
ARG BUNDLER_VERSION
ARG YARN_VERSION
ARG PYTHON_VERSION
ARG USER

RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends curl \
                                                                               ca-certificates \
                                                                               gnupg2 \
                                                                               software-properties-common

# Add NodeJS to sources list
RUN APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 \
    curl -vsL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -

# Remove cmdtest which come pre-installed and has a package called yarn. This prevents us from installing
# the yarn package we want otherwise.
RUN DEBIAN_FRONTEND=noninteractive apt-get remove -yq cmdtest

# Add Yarn to the sources list
RUN APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 \
  curl -vsL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo 'deb https://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list

# Add ppa so that we can select different ruby versions
RUN DEBIAN_FRONTEND=noninteractive apt-add-repository -y ppa:brightbox/ruby-ng

# Add ppa so that we can get the right python version
RUN DEBIAN_FRONTEND=noninteractive apt-add-repository -y ppa:deadsnakes/ppa

# install packages
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    build-essential \
    postgresql-client-$PG_MAJOR \
    tzdata \
    libpq-dev \
    nodejs \
    yarn \
    libv8-dev \
    ruby$RUBY_VERSION \
    ruby${RUBY_VERSION}-dev \
    ruby-svn \
    ghostscript \
    imagemagick \
    libmagickwand-dev \
    cmake \
    libssh2-1-dev \
    openssh-client \
    libaprutil1-dev \
    libssl-dev \
    swig \
    graphviz \
    yarn \
    rsync \
    git \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-venv \
    python${PYTHON_VERSION}-dev \
    pandoc && \
    apt-get clean && \
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
             /ssh_pub_key \
             /app/data/dev/repos \
             /app/tmp \
             /app/node_modules \
             /app/public/packs \
             /app/public/packs-test \
             /app/log \
             /app/venv && \
             chown -R $USER /bundle /ssh_pub_key /app

USER $USER

# install bundler
RUN gem$RUBY_VERSION install bundler -v $BUNDLER_VERSION

# Create key for ssh-ing to the autotester
RUN ssh-keygen -q -N "" -f /home/$USER/.ssh/id_rsa && \
    cp /home/$USER/.ssh/id_rsa.pub /ssh_pub_key/authorized_keys

FROM base AS prod

ARG USER
ARG BUNDLER_VERSION
ARG RUBY_VERSION

RUN mkdir -p /bundle /app /app/public && chown -R $USER /bundle /app

USER $USER

# install python packages
RUN python${PYTHON_VERSION} -m venv /app/venv && \
    /app/venv/bin/pip install -r /app/requirements.txt

COPY --chown=${USER}:${USER} . /app
COPY --chown=${USER}:${USER} .dockerfiles/database.yml.postgresql /app/config/database.yml

ENV RAILS_ENV=production
ENV NODE_ENV=production

# install bundler
RUN gem$RUBY_VERSION install bundler -v $BUNDLER_VERSION

RUN SECRET_KEY_BASE=1 bundle install --deployment --path $GEM_HOME --without development test offline mysql sqlite && \
    SECRET_KEY_BASE=1 PGDATABASE=dummy bundle exec rails i18n:js:export && \
    SECRET_KEY_BASE=1 PGDATABASE=dummy bundle exec rails assets:precompile

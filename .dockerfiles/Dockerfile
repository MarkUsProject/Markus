FROM ubuntu:jammy AS base

ARG NODE_MAJOR=20
ARG BUNDLER_VERSION='2.4.13'
ARG RUBY_VERSION='3.3.4'
ARG USER=markus

# Required in order to ensure bind-mounts are owned by the correct user inside the container
# this is NOT required when using docker-desktop since that handles uid mappings differently.
# Set this to the same UID as the user that owns the Markus files on the host machine.
ARG UID=1001

# Create the user that runs the app
RUN useradd -m -u $UID -s /bin/bash $USER

# Set up the correct node version for later installation
ADD https://deb.nodesource.com/setup_$NODE_MAJOR.x /tmp/setup_node.sh
RUN sh /tmp/setup_node.sh

# Copy the debian package containing system dependencies
COPY markus_1.0_all.deb /

# Install basic system dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends /markus_1.0_all.deb && \
    rm /tmp/setup_node.sh /markus_1.0_all.deb

# Install Ruby (we use ruby-install to configure the installed ruby version).
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends wget ca-certificates sudo && \
    wget https://github.com/postmodern/ruby-install/releases/download/v0.9.3/ruby-install-0.9.3.tar.gz && \
    tar -xzvf ruby-install-0.9.3.tar.gz && \
    cd ruby-install-0.9.3/ && \
    make install && \
    ruby-install --update && \
    ruby-install --system ruby $RUBY_VERSION

# Enable reading of PDF files with imagemagick
RUN sed -ri 's/(rights=")none("\s+pattern="PDF")/\1read\2/' /etc/ImageMagick-6/policy.xml

## This ssh setup is so that if git over ssh is enabled later on, by installing the openssh-server package (or similar)
## Then everything will just work out of the box

# Setup ssh configuration
RUN mkdir -p /home/${USER}/.ssh && \
    chmod 700 /home/${USER}/.ssh && \
    chown "${USER}:${USER}" /home/${USER}/.ssh

# Make temporary dir for ssh server (should not be necessary)
RUN mkdir -p -m0755 /var/run/sshd

# Add scripts used by git-over-ssh
RUN ln -s /app/lib/repo/markus-git-shell.sh /usr/local/bin/markus-git-shell.sh
COPY ./lib/repo/authorized_key_command.sh /usr/local/bin/authorized_key_command.sh

# Update the sshd configuration to restrict access by the $USER user
# NOTE: This block can follow "Match User #{USER}" if using openssh version 8.4+ (ubuntu 22.04+)
#       in order to make these settings specific to the $USER user. (The Match User
#       syntax is not supported in Included files prior to this version).
RUN mkdir -p /etc/ssh/sshd_config.d/ && printf "PermitRootLogin no\n\
AuthorizedKeysFile none\n\
AuthorizedKeysCommand /usr/local/bin/authorized_key_command.sh %%h\n\
AuthorizedKeysCommandUser ${USER}\n"\
> /etc/ssh/sshd_config.d/markus.conf

WORKDIR /app

FROM base AS dev

ARG USER
ARG BUNDLER_VERSION

# Set GEM_HOME so that gems are installed in the /bundle directory
ENV GEM_HOME="/bundle"

# Set PATH so that executables provided by gems are available on the PATH
ENV PATH="$GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH"

# install optional system dependencies
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install software-properties-common && \
    DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:deadsnakes/ppa && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends openssh-server \
                                                                               python3.13 \
                                                                               python3.13-venv \
                                                                               equivs \
                                                                               libjemalloc2

# pre-create mount-points for volumes and set ownership of these mountpoints
RUN mkdir -p /bundle \
             /app/data/development \
             /app/data/development/repos \
             /app/tmp \
             /app/node_modules \
             /app/log \
             /app/venv && \
             chown -R ${USER}:${USER} /bundle /app

USER $USER

# install bundler
RUN gem install bundler -v $BUNDLER_VERSION && bundle config set --local without 'unicorn'

# symlink files for git-over-ssh
RUN ln -s /app/.dockerfiles/git-ssh.rc /home/${USER}/.ssh/rc && \
    ln -s /app/.dockerfiles/ssh.pg_service.conf /home/${USER}/.pg_service.conf

# declare all mount-points and parent directories as volumes so that ownership is preserved in containers
VOLUME ["/app", "/bundle", "/app/data", "/app/data/development", "/app/data/development/repos", \
        "/app/node_modules", "/app/log", "/app/venv", "/app/tmp"]

FROM base AS prod

ARG USER
ARG BUNDLER_VERSION

# pre-create mount-points for volumes and set ownership of these mountpoints
RUN mkdir -p /app/public /app/log /app/data/production/repos && chown -R ${USER}:${USER} /app

# Copy over all app files
COPY --chown=${USER}:${USER} . /app
COPY --chown=${USER}:${USER} .dockerfiles/database.yml.postgresql /app/config/database.yml
COPY --chown=${USER}:${USER} .dockerfiles/git-ssh.rc /home/${USER}/.ssh/rc

# Install bundler
RUN gem install bundler -v $BUNDLER_VERSION && bundle config set --local without 'development test offline production_test'

USER $USER

# Ensure that the $USER is referenced in .ssh/rc
RUN sed "s:/markus/:/${USER}/:g" /home/${USER}/.ssh/rc

ENV RAILS_ENV=production
ENV NODE_ENV=production

# Install gems
RUN SECRET_KEY_BASE=1 bundle install --deployment

# Precompile assets
RUN SECRET_KEY_BASE=1 NO_SCHEMA_VALIDATE=true NO_INIT_SCHEDULER=true PGDATABASE=dummy bundle exec rails assets:precompile

# declare all mount-points and parent directories as volumes so that ownership and content is preserved in containers
VOLUME ["/app/public", "/app/log", "/app", "/app/data", "/app/data/production", "/app/data/production/repos"]

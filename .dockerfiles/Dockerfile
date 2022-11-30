FROM ubuntu:focal AS base

ARG NODE_MAJOR=18
ARG BUNDLER_VERSION='2.3.17'
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
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends /markus_1.0_all.deb && \
    rm /tmp/setup_node.sh /markus_1.0_all.deb

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
RUN mkdir -p /etc/ssh/sshd_config.d/ && printf "Match User ${USER}\n\
 PermitRootLogin no\n\
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
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends openssh-server \
                                                                               python3 \
                                                                               python3-venv \
                                                                               equivs

# pre-create mount-points for volumes and set ownership of these mountpoints
RUN mkdir -p /bundle \
             /app/data/development \
             /app/data/development/repos \
             /app/tmp \
             /app/node_modules \
             /app/public/packs \
             /app/public/packs-test \
             /app/log \
             /app/venv && \
             chown -R $USER /bundle /app

USER $USER

# install bundler
RUN gem install bundler -v $BUNDLER_VERSION && bundle config set --local without 'unicorn'

# symlink files for git-over-ssh
RUN ln -s /app/.dockerfiles/git-ssh.rc /home/${USER}/.ssh/rc && \
    ln -s /app/.dockerfiles/ssh.pg_service.conf /home/${USER}/.pg_service.conf

FROM base AS prod

ARG USER
ARG BUNDLER_VERSION

# pre-create mount-points for volumes and set ownership of these mountpoints
RUN mkdir -p /app/public /app/log /app/data/production/repos && chown -R $USER /app

# Copy over all app files
COPY --chown=${USER}:${USER} . /app
COPY --chown=${USER}:${USER} .dockerfiles/database.yml.postgresql /app/config/database.yml
COPY --chown=${USER}:${USER} .dockerfiles/git-ssh.rc /home/${USER}/.ssh/rc

# Install bundler
RUN gem install bundler -v $BUNDLER_VERSION

USER $USER

# Ensure that the $USER is referenced in .ssh/rc
RUN sed "s:/markus/:/${USER}/:g" /home/${USER}/.ssh/rc

ENV RAILS_ENV=production
ENV NODE_ENV=production

# Install gems
RUN SECRET_KEY_BASE=1 bundle install --deployment --without development test offline production_test

# Precompile assets
RUN SECRET_KEY_BASE=1 NO_SCHEMA_VALIDATE=true NO_INIT_SCHEDULER=true PGDATABASE=dummy bundle exec rails assets:precompile

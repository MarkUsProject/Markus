ARG UBUNTU_VERSION

FROM ubuntu:$UBUNTU_VERSION

ARG RUBY_VERSION
ARG PG_MAJOR
ARG NODE_MAJOR
ARG BUNDLER_VERSION
ARG YARN_VERSION

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
    python3 \
    python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate -s 0 /var/log/*log

# Enable reading of PDF files with imagemagick
RUN sed -ri 's/(rights=")none("\s+pattern="PDF")/\1read\2/' /etc/ImageMagick-6/policy.xml

# install bundler
RUN gem$RUBY_VERSION install bundler -v $BUNDLER_VERSION

ENV GEM_HOME="/bundle"
ENV PATH="$GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH"

# Create key for ssh-ing to the autotester
RUN ssh-keygen -q -N "" -f /root/.ssh/id_rsa && \
    mkdir -p /ssh_pub_key && \
    cp /root/.ssh/id_rsa.pub /ssh_pub_key/authorized_keys

# Create a directory for the app code (keep the name generic)
RUN mkdir -p /app

WORKDIR /app


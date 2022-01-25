The following are instructions to set up a production server for MarkUs. Note that these instructions assuming that you are setting up MarkUs on a new server without any dependencies pre-installed.

The following steps are for installation on a machine running Ubuntu 18.04, some changes may be required if installing on other operating systems.

## Server Setup Steps (should be run as superuser):

```bash
sudo su
```

##### 1. create a user to run the MarkUs server and setup .ssh files

```bash
adduser markusserver
```

- in this installation script we have chosen to create a user named `markusserver` but you can choose any name you wish.

##### 2. install (most) package dependencies

```bash
apt-get update
apt-get install build-essential \
				libv8-dev \
				ruby-svn \
				ghostscript \
				imagemagick \
				libmagickwand-dev \
				redis-server \
				cmake \
				libssh2-1-dev \
				libaprutil1-dev \
				swig \
				graphviz \
				git \
				postgresql \
				postgresql-client \
				postgresql-contrib \
				libpq-dev \
				apache2 \
				ruby2.5 \
				ruby2.5-dev
```

##### 3. install bundler

```bash
gem update --system
update-alternatives --config ruby
update-alternatives --config gem
gem install bundler
```

##### 4. install [node](https://nodejs.org)

```bash
curl -sL https://deb.nodesource.com/setup_9.x | bash -
apt-get install nodejs
```

##### 5. install [yarn](https://yarnpkg.com)

```bash
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt-get update && apt-get install yarn
```

##### 6. install [python3.7](https://www.python.org)

```bash
add-apt-repository ppa:deadsnakes/ppa
apt-get update
apt-get install python3.7 python3-pip python3.7-venv
```

##### 7. configure imagemagick policy file to read PDFs

```bash
sed -ri 's/(rights=")none("\s+pattern="PDF")/\1read\2/' /etc/ImageMagick-6/policy.xml
```

##### 8. configure local timezone settings (replace with your timezone as needed)

```bash
rm -f /etc/localtime
ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime
```

##### 9. setup the postgres database

- open the file at `/etc/postgresql/10/main/pg_hba.conf` and replace the line:

```
local 	all		all		peer
```

with

```
local 	all		all		md5
```

- choose a strong password for your server user and remember it for later
- as the `postgres` user run the following (replace `'password'` with your chosen password):

```bash
sudo -u postgres psql -U postgres -d postgres -c "create role markus createdb login password 'password';"
```

- restart the postgres service

```bash
/etc/init.d/postgresql restart
```

## MarkUs Instance Installation Steps (should be run as the markusserver user)

```bash
sudo su markusserver
```

The steps below describe how to install a single MarkUs instance (for one course). If installing multiple instance, please note that each instance will require it's own database and own relative url root (see steps below for details).

##### 1. download MarkUs source code from git

Right now, the current production branch is 1.10.0:

```bash
git clone --single-branch --branch 1.10.0 https://github.com/MarkUsProject/Markus.git
```

##### 2. change directory to the Markus code root directory

```bash
cd Markus
```

##### 3. create python virtual environment and download required packages

MarkUs uses python3 to display jupyter notebooks as well as to perform optical character recognition (OCR) on scanned exams. To install these python dependencies, create a python3.X virtual environment (we recommend using at least python 3.6) and then use `pip` to install all packages specified in the `requirements.txt` file. This virtual environment can be installed anywhere, in this example it is created at `/some/dir/venv`

```sh
python3 -m venv /some/dir/venv
/some/dir/venv/bin/pip install -r requirements.txt
```

Then update the settings to tell MarkUs the location of the `bin` subdirectory of your virtual environment by updating the [settings](https://github.com/MarkUsProject/Markus/wiki/Configuration#settings)

```yaml
python:
  bin: /some/dir/venv/bin
```

##### 4. store postgres password in database.yml file

```bash
cp config/database.yml.postgresql config/database.yml

```

- edit the config/database.yml file so that the `production` block looks like the example below except with `[password]` replaced with the password for the markus postgres user you set in the [postgres step above](#9-setup-the-postgres-database) and that `[database_name]` is replaced with a unique database name.

```yml
production:
  adapter: postgresql
  encoding: unicode
  database: [database_name]
  username: markus
  password: [password]
```

- since this file now contains a password it is highly recommended that you change the permissions on this file to:

```bash
chmod u=rw,g=,o= config/database.yml
```

##### 5. Install gems and yarn packages

```bash
bundle config libv8 -- --with-system-v8
bundle config github.https true
bundle install --deployment --without development test offline mysql sqlite
yarn install
```

##### 6. Precompile the rails static assets

In this example, we will use the relative url root `/csc108` as an example

```bash
mkdir public/javascripts
RAILS_RELATIVE_URL_ROOT=/csc108 RAILS_ENV=production bundle exec rails i18n:js:export
RAILS_RELATIVE_URL_ROOT=/csc108 RAILS_ENV=production bundle exec rails assets:precompile
```

##### 7. Set up Apache server

MarkUs shouldn't require any special Apache server setup and how to set up an Apache server is beyond the scope of these instructions.

Here is an example of how you might want to set the `ProxyPass` and `ProxyPassReverse` settings for a MarkUs instance running with a relative url root of `/csc108` and on port `5000`:

```
ProxyPass /csc108 http://localhost:5000/csc108
ProxyPassReverse /csc108 http://localhost:5000/csc108
```

##### 8. Start the resque workers

Here is an example of how you might want to start the resque workers for a MarkUs instance running with a relative url root of `/csc108`

```sh
RAILS_RELATIVE_URL_ROOT=/csc108 BACKGROUND=true QUEUES=* bundle exec rake environment resque:work
RAILS_RELATIVE_URL_ROOT=/csc108 BACKGROUND=true bundle exec rails resque:scheduler
```

## Autotester Installation Steps

See the [autotester README](https://github.com/MarkUsProject/markus-autotesting) for installation instruction.

Once the autotester is set up, connect MarkUs to the autotester by updating MarkUs' [configuration](./Configuration#settings) setting to point to the url that the autotester API is running at. For example, if the autotester API runs at `http://autotest.example.com`.

```yaml
autotest:
   url: 'http://autotest.example.com'
```

Then, register this MarkUs instance with the autotester by running the `markus:markus:setup_autotest` rake task:

```sh
RAILS_RELATIVE_URL_ROOT=/csc108 RAILS_ENV=production bundle exec rails markus:setup_autotest
```

It is very important that the RAILS_RELATIVE_URL_ROOT is set when running this rake task (if you are using a URL root). Each MarkUs instance uses its own relative url root to identify itself to the autotester. If the relative url root is not set when it is registered, the autotester will NOT be able to run tests for this MarkUs instance.

## setting up MarkUs as a git ssh server

_as of version 1.12.0_ [Previous Settings](./Deprecated-wiki-pages#setting-up-MarkUs-as-a-git-ssh-server)

To enable key pair uploads and to allow the server running MarkUs to handle git requests over ssh:

Set the following setting:

```yaml
enable_key_storage: true
```

For the rest of the setup we will assume the following settings:

```yaml
repository:
  storage: /MarkUs/data/prod/repos
```

and that you're running MarkUs on a server named `markus.example.edu`.

1. Make sure the required packages are installed:

```sh
$ apt-get install openssh-server git
```

2. Create a user to serve the repositories (typically this user is named `git`).

```sh
$ useradd -m -s /bin/bash git
```

This user should have read/write access to all git repositories stored in `/MarkUs/data/prod/repos` and read access to the `.authorized_keys` and `.access` files stored in the same folder. You can skip this step if you want to use the same user that runs the MarkUs web server since that user will be the owner of all repositories created by MarkUs.

3. Update the config settings so that MarkUs knows where to find the `markus-git-shell.sh` wrapper script. By default, this script is located in the `lib/repos` subdirectory but if you move it elsewhere make sure that the config file is updated accordingly.

```sh
repository:
  markus_git_shell: /Markus/lib/repos/markus-git-shell.sh
```

See the documentation in the `markus-git-shell.sh` script for more details on what this script is used for.

Note: if you have multiple MarkUs instances running on a single server, they can all use the same `markus-git-shell.sh` script.

4. Update the sshd configuration file (usually `/etc/ssh/sshd_config`) by appending the following:

```sh
Match User git
 PermitRootLogin no
 AuthorizedKeysFile none
 AuthorizedKeysCommand /MarkUs/lib/repos/authorized_key_command.sh
 AuthorizedKeysCommandUser git
```

This will create a special set of rules for your new user (in this case `git`). The important field here is:

`AuthorizedKeysCommand`: the path to the `authorized_key_command.sh` file. By default, this script is located in the `lib/repos` subdirectory but if you move it elsewhere make sure that the sshd config file is updated accordingly.

The other fields are recommended for security reasons but not strictly necessary.

See the documentation in the `authorized_key_command.sh` script for more details on what this script is used for.
Note: if you have multiple MarkUs instances running on a single server, they must all use the same `authorized_key_command.sh` script.

Note that you may have to change the ownership of the `authorized_key_command.sh` file to the user that runs sshd (usually root) and the permissions as follows:

```sh
$ chown root:root /MarkUs/lib/repos/authorized_key_command.sh
$ chmod 655 /MarkUs/lib/repos/authorized_key_command.sh
```

5. Set environment variables in `/home/git/.ssh/rc`

Both the `authorized_key_command.sh` and `markus-git-shell.sh` files require certain environment variables to be set when run. To ensure that these variables are set properly when logging in over ssh, both scripts source a file located in the home directory of the new user you created in `.ssh/rc` (see the documentation in either `authorized_key_command.sh` or `markus-git-shell.sh` for more details). If you want these scripts to source a different file, you must edit those two scripts directly.

The following environment variables should be set by sourcing the `.ssh/rc` file:

`MARKUS_LOG_FILE`: a path to a file on disk to write log output to. This variable is optional and if not set, no logs will be written

`GIT_SHELL`: a path to the `git-shell` executable that comes with the `git` package. Usually this is `/usr/bin/git-shell` but that might vary depending on your installation of `git`. This variable is required.

`MARKUS_REPO_LOC_PATTERN`: a string that is used to specify where to find a given repository on disk. If this string contains `'(instance)'`, then the `'(instance)'` will be replaced with the relative url root for a given MarkUs instance. This variable is required.
For example, if you have multiple MarkUs instances on a server and their git repositories are stored in:

```
/Markus/csc108/data/prod/repos
/Markus/csc209/data/prod/repos
```

Then you should set the `MARKUS_REPO_LOC_PATTERN` to `'/Markus/(instance)/data/prod/repos'` so that if a user requests the `group_123.git` repository for the `csc108` instance, then these scripts will know to actually look for it at `/Markus/csc108/data/prod/repos/group_123.git`

6. Start the sshd service:

```sh
$ /usr/sbin/sshd
```

7. Set remaining config option:

```yaml
repository:
  ssh_url: git@markus.example.edu
```

OR if you're using a relative url root make sure to include it:

```yaml
repository:
  ssh_url: git@markus.example.edu/csc108
```

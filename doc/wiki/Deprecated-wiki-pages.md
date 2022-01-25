


## Installation: setting up MarkUs as a git ssh server

_before version 1.12.0_

To enable key pair uploads and to allow the server running MarkUs to handle git requests over ssh:

In `config/environments/production.rb` set:

```
config.enable_key_storage = true
```

For the rest of the setup we will assume that:

```
config.key_storage = "/MarkUs/data/prod/keys"
config.x.repository.storage = "/MarkUs/data/prod/repos"
```

and that you're running MarkUs on a server named `markus.example.edu`.

1. Make sure the required packages are installed:

```sh
$ apt-get install openssh-server git
```

2. Create a user to serve the repositories (typically this user is named `git`)

```sh
$ useradd -m -s /bin/bash git
```

3. Put the `markus-git-shell.sh` script on the the new user's PATH and make it executable:

```sh
$ cp .dockerfiles/markus-git-shell.sh /usr/local/bin/markus-git-shell.sh
$ chown git:git /usr/local/bin/markus-git-shell.sh
$ chmod 700 /usr/local/bin/markus-git-shell.sh
```

4. The `markus-git-shell.sh` calls `git-shell` which the git user needs to run with super-user permissions:

```sh
$ echo "git ALL=(root) NOPASSWD:/usr/bin/git-shell" | sudo EDITOR="tee -a" visudo
```

5. Make symlinks of all relevant files:

If your MarkUs instance does not use a relative url root:

```sh
$ ln -s /MarkUs/data/prod/keys/ /home/git/.ssh/
$ ln -s /Markus/data/prod/repos/bare/ /home/git/
```

OR if your instance uses a relative url root (ex: csc108/)

```sh
$ ln -s /MarkUs/data/prod/keys/ /home/git/.ssh/csc108/
$ ln -s /Markus/data/prod/repos/bare/ /home/git/csc108/
$ sed -i "s@#*AuthorizedKeysFile.*@AuthorizedKeysFile /home/git/.ssh/csc108/authorized_keys@g" /etc/ssh/sshd_config
```

6. Start the sshd service:

```sh
$ /usr/sbin/sshd
```

7. Set remaining config option:

```
config.x.repository.ssh_url = git@markus.example.edu
```

OR if you're using a relative url root make sure to include it:

```
config.x.repository.ssh_url = git@markus.example.edu/csc108
```

## Installation: Set up nbconvert virtual environment

_before version 1.13.0_

MarkUs uses python's nbconvert package to convert jupyter notebooks to html so it can be displayed in the browser. Install a python virtual environment with nbconvert installed. This virtual environment can be installed anywhere, in this example it is created at `/some/dir/venv`

```bash
python3 -m venv /some/dir/venv
/some/dir/venv/bin/pip install wheel nbconvert
```

Let MarkUs know where the virtual environment is installed. Set `config.nbconvert` in `production.rb`:

```ruby
config.nbconvert = '/some/dir/venv/bin/jupyter-nbconvert'
```

## Installation: create python virtual environment and download required packages

_before version 1.13.0_

```bash
python3.7 -m venv lib/scanner/venv
source lib/scanner/venv/bin/activate
pip install -r lib/scanner/requirements.txt
deactivate
```

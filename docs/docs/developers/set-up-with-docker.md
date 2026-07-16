---
permalink: /developers/set-up-with-docker/
title: Set Up With Docker
parent: Developers
nav_order: 3
---
# Developer Guide: Set Up with Docker
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

- TOC
{:toc}

If you want to get started on working on MarkUs quickly and painlessly, this is the way to do it.

## Downloading and Installing

1. If you are using **Windows**, you will need to install Windows Subsystem for Linux (WSL) by following the instructions on [this page](https://docs.microsoft.com/en-us/windows/wsl/install-win10). (The "Simplified Installation" section is probably easiest, but you need to join the Windows Insiders Program with a Microsoft account.)

    - If you are given a choice of which operating system to use, select *Ubuntu 22.04*.

2. If you are using **Windows** or **MacOS** you will need to install Docker by following the instructions on [this page](https://docs.docker.com/get-docker/). If you are using **Linux**, you will need to install [Docker Engine](https://docs.docker.com/engine/install/). (On Linux, Docker Desktop is known to cause issues with MarkUs, so it is important that you install Docker Engine and not Docker Desktop. If you already have Docker Desktop installed, see Q6.)

    - On Windows, make sure you've selected the "WSL 2 backend" tab under "System Requirements" and follow those instructions.
    - On Linux, also follow the instructions on "Manage Docker as a non-root user" [here](https://docs.docker.com/install/linux/linux-postinstall/).

3. If you are using **Windows**, you'll need to open a terminal into the WSL system you installed. *This is the terminal where you'll type in the rest of the commands in this section.*

    1. To start the WSL terminal, open the start menu and type in "ubuntu". Click on the "Ubuntu 22.04" application. (We recommend pinning this to your taskbar to make it easier to find in the future.)
    2. Type in the command `pwd`, which shows what folder you're currently in. You should see `/home/<your user name>` printed. If it isn't, switch to your home directory using the command `cd ~`.

4. Clone the Markus repository.

5. Change into the repository that you just cloned: `cd Markus`.

6. If you are on **Windows (WSL)** or **Linux**, you will need to configure Docker to make sure the application files are owned by a user with the same UID on your host machine as in the containers:

    1. Run the command `id -u`. If the output is `1001` you can skip this the rest of this step and move onto Step 7 below. Otherwise, keep going.
    2. Follow the first two steps in the [Installing and Configuring RubyMine](#installing-and-configuring-rubymine) section below to open the MarkUs repository in RubyMine.
    3. In the MarkUs repository, create a new top-level file named `compose.override.yaml`.
    4. Copy and paste the following text into the `compose.override.yaml` file, replacing `<UID>` with the number returned by `id -u` earlier.

        ```yml
        services:
            app:
                build:
                    args:
                        UID: <UID>
            deps-updater:
                build:
                    args:
                        UID: <UID>
            rails:
                build:
                    args:
                        UID: <UID>
            ssh:
                build:
                    args:
                        UID: <UID>
            resque:
                build:
                    args:
                        UID: <UID>
            resque-scheduler:
                build:
                    args:
                        UID: <UID>
            webpack:
                build:
                    args:
                        UID: <UID>
        ```

7. Run `docker compose build`.

8. Run `docker compose run --rm deps-updater`.
   This will install all of MarkUs' dependencies.

    > 🗒️ **Note**: you don't need to run this command each time you want to run MarkUs, only during the initial setup and whenever the dependencies change.

9. Run `docker compose up rails`. The first time you run this it will take a long time because it'll seed the MarkUs application with sample data before actually running the server. When the server actually starts, you'll see some terminal output that looks like:

    ```text
    => Booting Puma
    => Rails 7.1.3.2 application starting in development
    => Run `bin/rails server --help` for more startup options
    [1] Puma starting in cluster mode...
    [1] * Puma version: 6.4.2 (ruby 3.0.2-p107) ("The Eagle of Durango")
    [1] *  Min threads: 0
    [1] *  Max threads: 5
    [1] *  Environment: development
    [1] *   Master PID: 1
    [1] *      Workers: 3
    [1] *     Restarts: (✔) hot (✖) phased
    [1] * Preloading application
    [1] * Listening on http://0.0.0.0:3000
    [1] Use Ctrl-C to stop
    [1] - Worker 0 (PID: 71) booted in 0.01s, phase: 0
    [1] - Worker 1 (PID: 75) booted in 0.01s, phase: 0
    [1] - Worker 2 (PID: 77) booted in 0.01s, phase: 0
    ```

10. Open your web browser and type in the URL `localhost:3000/csc108`. The initial page load might be slow, but eventually you should see a login page.
    - To login as an instructor, use the username `instructor` and any non-empty password.
    - To login as an admin user, use the username `.admin` and any non-empty password.
    - To login as a student, use a student username from the seed data (e.g., `c5anthei`) and any non-empty password.

    *Tip*: to terminate the Rails server, go to the terminal window where the server is running and press `Ctrl + C`/`⌘ + C`.

    - On Windows Home Edition, you'll need to use the Docker container's IP address instead: `192.168.99.100:3000/csc108`.

11. In a new terminal window, go into the Markus directory again and run `docker compose run --rm rails rspec` to run the MarkUs test suite. This will take several minutes to run, but all tests should pass.

Hooray! You have MarkUs up and running. Please keep reading for our recommended developer setup.

## Installing and Configuring RubyMine

We strongly recommend RubyMine (a JetBrains IDE) for all MarkUs development. If you prefer to use VSCode, please follow the guide outlined [here](https://github.com/MarkUsProject/Wiki/blob/master/Developer-Guide--Configure-Environment-to-use-VSCode.md).

1. First, install RubyMine from [here](https://www.jetbrains.com/ruby/download). Note that if you are a current university student, you can obtain a [free license](https://www.jetbrains.com/student/) for all JetBrains software.

2. Open the MarkUs repository in RubyMine.

    - On Windows, your repository will be located at `\\wsl$\Ubuntu-22.04\home\<your user name>\Markus`.

3. Complete the setup steps under [Docker: Enable Docker Support JetBrains guide](https://www.jetbrains.com/help/ruby/docker.html#enable_docker).

4. To configure RubyMine to use a remote Ruby interpreter from the Docker image: [JetBrains guide](https://www.jetbrains.com/help/ruby/configuring-language-interpreter.html#add_remote_ruby_interpreter). Use `rails` as the service. After you've selected this interpreter, RubyMine will take some time to index all of the Ruby gems (libraries); you'll see "Indexing"... at the bottom of the RubyMine window.

    If this doesn't work, please make sure you're using the latest version of RubyMine (Help -> Check for Updates...).

5. To configure RubyMine to connect to the PostgreSQL database that MarkUs uses for development, first make sure the MarkUs server is running (by doing a `docker compose run...` as above). Then follow [these instructions](https://www.jetbrains.com/help/idea/running-a-dbms-image.html#6aa07130) in RubyMine to connect to the PostgreSQL server running as the 'postgres' docker-compose service. Note that you do not need to create a new container so you should only need to follow the instructions under "Connect to the PostgreSQL server".

    - hostname: `localhost`
    - port: `35432`
    - user: `postgres`
    - password: `docker`
    - database: `markus_development`

## Installing Pre-Commit Hooks

We use [pre-commit](https://pre-commit.com/) to run automated checks on code before each commit. To set this up on your local computer (*not* in a Docker container):

1. First, install Python 3.
2. Then, install the pre-commit library: `$ python3 -m pip install pre-commit` (or just `python` instead of `python3`, depending on your Python executable. Homebrew Python might [block](https://peps.python.org/pep-0668/) the above command. If this fails, run `brew install pipx` -> `pipx install pre-commit`.
3. Finally, in the `Markus` folder run `$ pre-commit install`. This will install all of the Markus pre-commit hooks.

After this, these checks will run every time you make a commit. If all checks pass, the commit will proceed as normal. If a check fails, the commit *does not* occur, and there are two possibilities:

- Some checks will automatically fix issues (e.g., most style checks). *These changes still need to be manually git added and committed!*
- Some checks will just report problems that you'll need to fix manually. After fixing them, you'll need to add and commit those changes.

## Running Commands in Docker

Here's a summary of the few most common tasks you'll use in your development.

- Start the MarkUs server: `docker compose start rails`
- Update dependencies: `docker compose run --rm deps-updater`. Run this whenever you see changes to `Gemfile`/`Gemfile.lock`, `package.json`/`package-lock.json`, and any of the `requirements-*.txt` files.
- Run the MarkUs rspec test suite: `docker compose run --rm rails rspec`
- Run the MarkUs rspec test suite with the test coverage shown: `docker compose run --rm -e COVERAGE=true rails rspec`
- Run a specific rspec test file: `docker compose run  --rm rails rspec FILE`
- Run the Markus Jest test suite:  `docker compose run  --rm rails npm run test`
- Run the Markus Jest test suite with the test coverage shown:  `docker compose run --rm rails npm run test-cov`
- Run a specific Jest test file: `docker compose run  --rm rails npm run test FILE`
- Start a shell within the Docker Rails environment: `docker compose exec rails bash`. This requires the `rails` service to be started, as described in "Start the MarkUs server" above.
  Within this shell, you can:
    - Install new dependencies: `bundle install`, `npm install`
    - Reset the MarkUs database: `rails db:reset`
    - Run a database migration: `rails db:migrate`
    - Start the interactive Rails console: `rails c`

Here's a summary of a few commands that are helpful for managing containers.

- Stop the MarkUs server: `docker compose stop rails`
- Start the MarkUs server up again (after stopping it): `docker compose start rails`
- Remove all containers started by MarkUs: `docker compose down`
- Remove all containers and all volumes started by MarkUs: `docker compose down -v`
    - Note that removing volumes will mean that you will lose all changes made in the database

If you need to rebuild the MarkUs docker image:

- Stop and remove the existing containers and remove all volumes: `docker compose down -v`
- Do steps 5 and 6 from the Downloading and Installing section [above](#downloading-and-installing)

## Viewing the Documentation

The MarkUs documentation site can be served locally using the `docs` Docker Compose service:

```bash
docker compose --profile docs up docs
```

Once the container has started, open your browser and navigate to `http://localhost:4000`. The server supports live reload: changes to documentation source files will automatically refresh the browser.

To stop the documentation server, press `Ctrl + C`/`⌘ + C` in the terminal.

## Setting up the autotester

**Note**: you only need to consult this section if you'll be working with the MarkUs autotester.

1. Clone the [markus-autotesting repo](https://github.com/MarkUsProject/markus-autotesting). Don't clone it into your `Markus` folder; we recommend cloning it into the same parent folder as your `Markus` folder.
2. `cd` into the `markus-autotesting` folder.
3. Run `docker compose build` to build a new Docker images for the MarkUs autotester.
4. Run the following commands to install the autotester's dependencies.

    ```bash
    docker compose run --rm server-deps-updater
    docker compose run --rm client-deps-updater
    ```

5. Run `docker compose up` to create the new containers.
6. Stop the containers by pressing Ctrl + C (Windows/Linux) or Cmd + C (macOS). Then, restart the containers by running the command `docker compose start`.
7. In a separate terminal, start the MarkUs server: `docker compose up rails`.
8. In a web browser, visit the running server, but using a different domain than `localhost`:
    - For Windows and macOS, visit `host.docker.internal:3000/csc108`. If that doesn't work:
        - Windows: first open a WSL terminal and enter the command `ip addr show eth0 | grep inet`. Use the IP address found after `inet`, which is a sequence of 4 numbers separated by `.`, e.g. `100.20.200.2`. Try visiting `<IP address>:3000/csc108` instead.
        - For macOS, visit `docker.for.mac.localhost:3000/csc108` instead.
    - For Linux, visit `172.17.0.1:3000/csc108`.
9. Now, open a shell in the MarkUs docker container: `docker compose run --rm rails bash`.
10. Execute the following commands in the MarkUs container.
    1. Create sample autotesting assignments: `rails db:autotest`.
    2. (*The MarkUs server and autotest containers be running when you run these commands.*) Run tests for every sample autotesting asignment: `MARKUS_URL=<URL> rails db:autotest_run`, where `<URL>` is in the form `http://<DOMAIN>:3000`, and `<DOMAIN>` is the domain you used in Step 7 (e.g., `host.docker.internal`).

        If you get an error when running this command, see "Running tests manually" below.

Now when you visit MarkUs in the web browser, you should see the new assignments that were created, the autotest settings (under Settings -> Automated Testing), and a sample submission with autotest results.

### Running tests manually

If the `rails db:autotest_run` fails, you can still run the tests manually in your web browser by doing the following:

1. Go to MarkUs in your web browser (using the same URL as Step 7 above).
2. Navigate to the `autotest_custom` assignment (under the Assignments tab), and go to Settings -> Automated Testing. This will take you to the settings page for the automated tests.
3. On that page, change the "Timeout" field from 30 to 60, and press "Save" at the bottom of the page. You should see a message at the top of the page that shows the status of updating the settings; wait until this message changes to "Completed".
4. Now go to the "Submissions" tab to view a table of all submissions---in this case, there will be just one. Click on the link in the leftmost column of the table. This takes you to the grading view for the submission.
5. Go to the Test Results tab and click on "Run Tests".
6. Wait a minute, and then refresh the page. Go back to the Test Results tab. You should see that two tests have been run, and that both have passed.
7. Repeat for the other assignments that you want to run tests for.

## Setting up ActionMailer

If you plan on doing work that involves sending/receiving emails from MarkUs, you will need to [configure ActionMailer](https://guides.rubyonrails.org/action_mailer_basics.html). To get you started quickly on setting up ActionMailer and understanding what it is used for in MarkUs, follow the instructions outlined in [Enabling ActionMailer In Development](tips-and-tricks/enabling-actionmailer.md).

## Troubleshooting

**Note: This is an archive of problems related to Docker that are encountered by students, and their solutions.**

### Q1

I'm writing frontend code. The files I've changed should according to the Webpack config files trigger Webpack rebuild, but that's not happening. I've verified that

1. My changes are valid and should be displayed from the URL I'm accessing.
2. There are no errors in the webpack container's logs.
3. If I run `npm run build-dev` in the webpack container's console directly, it succeeds and I'm able to see my changes afterwards.

### A1

*This solution is experimental and could lead to problems such as higher CPU usage.* This is likely due to Webpack's `watch` option not working properly. According to the official Webpack [docs](https://webpack.js.org/configuration/watch/#watchoptionspoll), one suggestion when `watch` is not working in environments such as Docker, is to add `poll: true` to `watchOptions` inside the Webpack config file, which in our case, is `webpack.development.js`. This should help resolve the problem.

### Q2

When I run `docker compose up rails`, or when I restart my previously created `rails` container, I get a warning/error along the lines of

```MARKDOWN
system temporary path is world-writable: /tmp
/tmp is world-writable: /tmp
. is not writable: /app
Exiting
/usr/lib/ruby/3.0.0/tmpdir.rb:39:in `tmpdir': could not find a temporary directory (ArgumentError)
[...stacktrace]
```

after following the setup guide step by step. I've looked into my host setup and confirmed that my `/tmp`'s permissions are correct (i.e. on Linux you can expect a 1777, on mac it might be a symbolic link to `/private/tmp`, latter of which would also be a 1777). For the second warning/error, I've found that my Markus container's `/app` is owned by `root`, not `markus`.

### A2

It's unclear exactly why or how this occurred, but one fix is as simple as using another directory for this purpose. Ruby reads a variety of environment variables (env vars) to determine the system's temporary directory that it can use, and you can customize that directory with an env var. Both warnings/errors are complaining about the same thing: no available `TMPDIR`.

Since this is not a wide-spread issue, it's more reasonable to have the setup living entirely on your local (i.e. ignored by git) than committing it to the repo.

1. Start by creating a `compose.override.yaml` file under Markus root. Notice that the filename is already listed in `.gitignore`.
2. The general idea is simple - configure `TMPDIR`, then pass this configuration in. Now we need to find a potential `TMPDIR` candidate inside the container. Reading <https://github.com/ruby/ruby/blob/ruby_3_0/lib/tmpdir.rb> gives us an idea of what ruby expects (at the time of writing, Markus was in ruby 3.0, but this file shouldn't expect major changes in the future versions. If it starts using other env var(s), update this documentation to reflect the new env var(s)).
3. You can find a directory in the rails container with the correct permissions (1777) & that is unused by Markus, or create your own. In my case `/var/tmp` fit the profile.
    1. I found the directory by starting a shell in the `rails` container with `docker exec -it` and then running `find -type d -perm 1777`
4. Write this env var into the `compose.override.yaml` file you created. For example:

    ```YAML
    services:
        rails:
            environment:
            - TMPDIR=/var/tmp
    ```

5. Save your changes. After `docker compose build app`, make sure you run `docker compose -f compose.override.yaml compose.yaml up rails` instead of just `docker compose up rails`. This will apply the `TMPDIR` we created, which would resolve the issue.

### Q3

When the `rails` container is started, postgres' database migrations will be auto applied because of the line `bundle exec rails db:prepare` in `entrypoint-dev-rails.sh`. Sometimes migrations fail - sometimes outright when you first start the container with `docker compose up rails`, other times when you successfully create your `rails` container, then make some data change to markus (i.e. adding a new assignment tag) or shut down and restart the `rails` container - like

```MARKDOWN
...
======================================
2023-09-15 11:47:03 -- create_table(:users, {:id=>:integer})
2023-09-15 11:47:03 rails aborted!
2023-09-15 11:47:03 StandardError: An error has occurred, this and all later migrations canceled:
2023-09-15 11:47:03
2023-09-15 11:47:03 PG::DuplicateTable: ERROR:  relation "users" already exists
2023-09-15 11:47:03 /app/db/migrate/20080729160237_create_users.rb:3:in `up'
2023-09-15 11:47:03
2023-09-15 11:47:03 Caused by:
2023-09-15 11:47:03 ActiveRecord::StatementInvalid: PG::DuplicateTable: ERROR:  relation "users" already exists
...
```

This would also occur after following the setup guide step by step.

### A3

Again, it's unclear exactly why this happened, but there's a fix.

1. If you're running into the first one, it's likely because your migrations were applied successfully the first time, but because of some unknown (likely permission) issues, postgres didn't record those migrations as complete, so next time the db is refreshed, postgres would attempt the migrations again.
2. Verify the cause. If you've taken CSC343, this should seem very familiar:
    1. Start a shell inside the `postgres` container.
    2. Run `psql -U [postgres username]`. At the time of writing, this username is postgres' image's default username, which is `postgres`. Consult `docker-compose.yml` first to check if another username has been specified.
    3. You'll be prompted for the user's password, which you can find in `docker-compose.yml` as well.
    4. Now you're in the postgres shell. Run `\c markus_development` to connect to the `markus_development` database. You can see the list of databases with `\l`.
    5. On success, run `select count(*) from schema_migrations;`. Normally, the outputted count should be equal to the total number of migrations (files) under Markus/db/migrate. In this case, it might be 0 or a smaller number.
    6. Repeat steps iv - v for `markus_test` as well, and the count should be the same.

3. The fix is rather simple as well. You will start with commenting out the line `bundle exec rails db:prepare` in `entrypoint-dev-rails.sh`.
4. Once `rails` container is up, start a shell inside it and run `bundle exec rails db:prepare`. Without running this, you won't be able to browse markus UI.
    1. If for whatever reason this command fails, try `rails db:drop && rails db:create && rails db:migrate && rails db:seed` instead.
5. The downside is you'll have to redo this process every time the containers are recreated, but otherwise this should resolve the issue. Verify that the `schema_migrations` tables now contain the correct number of migration records.

### Q4

I'm seeing a test failing with the following message near the top:

```text
1) SubmissionsController#get_file When the file is a jupyter notebook file should download the file as is
   Failure/Error: _stdout, stderr, status = Open3.capture3(*args, stdin_data: file_contents)

   Errno::ENOENT:
       No such file or directory - /app/nbconvertvenv/bin/jupyter-nbconvert
```

### A4

Run the following commands:

```console
docker compose run --rm rails bash  # This takes you into the Docker container
./venv/bin/python3 -m pip install -r requirements-jupyter.txt
```

Then try re-running the tests. You can do this from your current terminal (inside the Docker container) simply by running `rspec`.

### Q5

When I run `docker compose up rails`, I get a permission denied error along the lines of

```text
markus-rails-1 | cp: cannot create regular file 'config/database.yml': Permission denied
markus-rails-1 exited with code 1
```

### A5

If you are on **Linux**, you may have Docker Desktop installed, which is known to cause issues with MarkUs installation. Use your package manager to verify that you have Docker Desktop installed and see Q6 for further steps.

### Q6

I am using **Linux** and I have Docker Desktop installed instead of Docker Engine.

### A6

*Warning: the steps below will remove all existing docker containers, images, and volumes.*

Remove Docker Desktop and all associated Docker packages using your package manager.

Once the packages are removed, delete existing Docker dotfiles by running:

```bash
rm -rf ~/.docker
```

Finally, install Docker Engine by following the instructions on [this page](https://docs.docker.com/engine/install/).

### Q7

When setting up the autotester, the script might often fail to find the required information to populate the schema required to run the automated tests.

```plaintext
Set up testing environment for autotest
Creating sample autotesting assignment autotest_custom
bin/rails aborted!
NoMethodError: undefined method `[]' for nil (NoMethodError)

      schema_data['definitions']['files_list']['enum'] = files
                                ^^^^^^^^^^^^^^
/app/app/helpers/automated_tests_helper.rb:34:in `fill_in_schema_data!'
```

This often happens when running the last step (#10) during the autotester [setup](https://github.com/MarkUsProject/Wiki/blob/master/Developer-Guide--Set-Up-With-Docker.md#setting-up-the-autotester) process, as a result of missing or corrupted database entries. The easiest and simplest solution is to restart the setup process with a clean docker environment.

Save the following functions to your `.bashrc`, `.zshrc` or other shell configuration file and execute the `nuke_docker` command.

```bash
# Docker functions
# *****************************************************************************
function stop_containers() {
  docker stop $(docker ps -a -q)
}

function remove_containers() {
  docker rm $(docker ps -a -q)
}

function remove_volumes() {
  docker volume rm $(docker volume ls -qf dangling=true)
}

function remove_buildx_cache() {
  docker builder prune -af
  docker buildx prune -af
}

function clean_containers() {
  echo "Cleaning existing containers"
  stop_containers
  remove_containers
  remove_volumes
  remove_buildx_cache
}

function nuke_docker() {
  clean_containers
  docker system prune -a --volumes
}
```

We can now restart the setup process with a clean docker environment.

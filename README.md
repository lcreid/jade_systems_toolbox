# Jade Systems' Toolbox

This gem installs a program to help do container-based development. It provides functions to:

* Prepare a directory for development in containers, including some files to configure VScode.
* Bring up the container(s).
* Open VScode on the code in the container.
* Open a browser window on the application-under-development's web server.
* Open a terminal session on the application container.
* Show mapping of container ports to the ports on your host (laptop, development machine).

[At the moment, this gem has been tested on Ubuntu. In theory, it will do the job for Windows, Macos, and Linux. Feel free to raise issues if it doesn't.]

One of many things this gem _doesn't_ do is impose a Ruby code style on you. The recommended extensions installed by the `init` command include formatting and linting using RuboCop, but you'll get the default RuboCop rules, or the rules from whatever other RuboCop gem you might use (e.g. https://github.com/rails/rubocop-rails-omakase, or https://github.com/standardrb/standard).

## Installation

Don't install this gem in your application. It's meant to be a tool available everywhere on your device. Install the gem by executing:

```bash
gem install --user-install jade_systems_toolbox
```

(If you know what the implications are of _not_ putting `--user-install`, you can install the gem without it.)

## Usage

### Summary

```
Commands:
  tool down                   # docker compose down
  tool edit                   # devcontainer open
  tool help [COMMAND]         # Describe available commands or one specific command
  tool init                   # Initialize compose files and devcontainer.json
  tool initialize_docker      # Initialize compose files
  tool initialize_vscode      # Initialize devcontainer.json for vscode
  tool open                   # Open a page on the services's first port
  tool port [CONTAINER_PORT]  # Get the host port for the CONTAINER_PORT's container port CONTAINER_PORT
  tool ports                  # Get the host ports for the container ports defined in `compose.yml`
  tool server [COMMAND]       # Run the server in the container
  tool terminal               # Run a shell in the container
  tool up                     # docker compose up -d
  tool version                # Show the version number of the tool.

Options:
  -v, [--verbose], [--no-verbose], [--skip-verbose]
                                                     # Default: false
```

### Tutorial

The broad steps to start a brand new project are:

1. Create a directory for the project, and change directory into the new directory.
1. Decide which container(s) you want to use.
1. Initialize the container(s).
1. Bring up the container(s).
1. Open a terminal session and create the application (e.g. `rails new` if you're doing a Rails project.)
1. Run the editor and otherwise do what you need to do to create your project.
1. When the web server is ready to run (if you're developing a web app), run the server.
1. Open a browser window to the web server.
1. When you're done, bring down the containers.

To start:

```bash
mkdir project && cd project
```

#### Choose Containers

`tool` can install `compose.yml` for Rails development with SQLite, or Postgres, or MySQL, or MariaDB. You can also choose the Ruby version
[Coming soon: Install a compose file from any URL, and/or choose any image as the base.]

The default intialization command is:

```bash
tool init
```

The initialization installs

* A `compose.yml` file for Rails development with a SQLite database, using Ruby 3.4, and the `bookworm` version of Debian.
* On Linux, a `compose.override.yml` file.
* A `.devcontainer.json` file, so VScode can edit without the context of the container.
* `.vscode/settings.json` and `vscode/extensions.json` so developers have a consistent experience in VScode (mostly linting and autoformatting).

You can change some of the defaults. To choose another database:

```bash
tool init --database postgres
```

The choices are `mariadb`, `mysql`, `postgres`, and `sqlite`.

To choose a different ruby version and Debian version:

```bash
tool init --ruby-version 3.2 --distro-version bullseye
```

You can choose a currently supported Ruby version, and a Debian version that supports that Ruby version, from the containers built by https://github.com/lcreid/docker.

You're free to modify the `compose.yml` (and `compose.override.yml` on Linux). If you run `tool init` again, it will over-write your changes.

#### Start the Containers

```bash
tool up
```

This takes a while to run, the first time you run it when the image isn't already downloaded to your computer.

### Open a Terminal Session

```bash
tool terminal
```

This connects to the `web` service defined in the `compose.yml` file. If you want to connect to another service:

```bash
tool terminal --service mysql
```

#### Start VScode

```bash
tool edit
```

#### Run the Server

```bash
tool server
```

This runs `bin/dev`. To run something else, e.g. a bare Puma so you can debug it:

```bash
tool server "bin/rails s -b 0.0.0.0"
```

If you have other services running servers, or the server is in a sub-directory of your project:

```bash
tool server --work-dir test/app --service monitor
```

To terminate the server, type Control-C.

#### Open a Browser Window

To connect to the server running on service `web` on port 3000:

```bash
tool open
```

If the server is listening on a different port:

```bash
tool open --container-port 5990
```

As usual, if the server is running in a different service:

```bash
tool open --service monitor
```

If you want to connect to a path other than `/`:

```bash
tool open --path letter_opener
```

#### Bring Down the Containers

```bash
tool down
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To test locally without installing, run the executable like this:

```bash
ruby -I lib exe/tool [COMMAND]
```

To run in another directory, use the path name from the directory you're in, to the directory where you checked out the gem's code, for example:

```bash
ruby -I ../jade_systems_toolbox/lib ../jade_systems_toolbox/exe/tool [COMMAND]
```

To install this gem onto your local machine, build it: `gem build jade_systems_toolbox.gemspec`, and install it: `gem install -l jade_systems_toolbox-0.1.1.gem`. (Change the version number to match the current version number.)

## Release

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lcreid/jade_systems_toolbox. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/lcreid/jade_systems_toolbox/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the JadeSystemsToolbox project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/lcreid/jade_systems_toolbox/blob/main/CODE_OF_CONDUCT.md).

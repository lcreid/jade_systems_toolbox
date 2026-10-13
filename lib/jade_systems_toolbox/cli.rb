# frozen_string_literal: true

module JadeSystemsToolbox
  class Cli < Thor
    stop_on_unknown_option! :down

    class << self
      # This and other improvements from Matt: https://mattbrictson.com/blog/fixing-thor-cli-behavior
      def exit_on_failure? = true
    end

    map "-h" => :help
    map "--help" => :help

    class_option :verbose, type: :boolean, default: false, aliases: "-v"

    desc "down -- COMPOSE_ARGS", "docker compose down. Deletes the container. You probably want stop."
    option :force, default: "n", aliases: "-f"
    def down(*compose_args)
      force = ask("tool down destroys the containers. Are you sure [y/N]?").downcase unless options[:force] == "y"
      exit(1) if force[0] != "y"

      system(([ "docker compose down" ] + compose_args).join(" "))
    end

    desc "edit", "devcontainer open"
    def edit
      `devcontainer open`
    end

    desc "exec COMMAND [ARGS]", "Run a command in the container and exit"
    option :env, repeatable: true, default: [], aliases: "-e", banner: "VAR=value"
    option :mapping, type: :boolean, default: true, aliases: "-m"
    option :service, default: "web", aliases: "-s"
    option :work_dir, aliases: "-w"
    def exec(command_for_container, *args)
      service = options[:service]
      workdir = "-w #{options[:work_dir]} " unless options[:work_dir].nil?
      environment_variables = options[:env].map { "-e #{_1}" }.join(" ")
      port_map_environment_variables = port_map_for_environment(service) if options[:mapping]
      shell_command = [ command_for_container, *args ].join(" ")
      command = [
        "docker compose exec",
        environment_variables,
        port_map_environment_variables,
        workdir,
        "-it",
        service,
        "sh -c",
        "'#{shell_command}'",
      ].compact.join(" ")

      system(command)
    end

    desc "init", "Initialize compose files and devcontainer.json"
    option :database, default: "sqlite", aliases: "-d"
    option :ruby_version, default: "4.0", aliases: "-r"
    option :distro_version, default: "trixie", aliases: "-t" # For Toy Story.
    def init
      invoke :initialize_docker
      invoke :initialize_vscode, [], {}
    end

    desc "initialize_docker", "Initialize compose files"
    option :database, default: "sqlite", aliases: "-d"
    option :ruby_version, default: "4.0", aliases: "-r"
    option :distro_version, default: "trixie", aliases: "-t" # For Toy Story.
    method_option :end_to_end_tool,
      type: :string,
      enum: [ "playwright", "selenium" ],
      desc: "Use an end-to-end (browser) testing tool",
      aliases: "-e"
    def initialize_docker
      DockerInitializer.new(**options.transform_keys(&:to_sym).except(:verbose)).get_and_save_compose_files
    end

    desc "initialize_vscode", "Initialize devcontainer.json for vscode"
    def initialize_vscode
      initializer = Vscode.new
      initializer.write_devcontainer_json
      initializer.write_extensions_json
      initializer.write_settings_json
    end

    desc "open", "Open a page on the services's first port or specified port"
    option :service, default: "web", aliases: "-s"
    option :path, default: "/", alias: "-p"
    option :container_port, default: 3000, type: :numeric
    option :protocol, default: "http"
    def open
      service = options[:service]
      path = options[:path]
      container_port = options[:container_port]
      protocol = options[:protocol]

      container_ports = compose_yaml.dig("services", service, "ports")
      container_port = container_ports&.[](0) || container_port
      path = "/#{path}" if path[0] != "/"
      `open "#{protocol}://localhost:#{host_port_from_container_port(service:, container_port:)}#{path}"`
    end

    desc "port [CONTAINER_PORT]", "Get the host port for the CONTAINER_PORT's container port CONTAINER_PORT"
    option :service, default: "web", aliases: "-s"
    def port(container_port = 3000)
      service = options[:service]
      puts host_port_from_container_port(service:, container_port:)
    end

    desc "ports", "Get the host ports for the container ports defined in `compose.yml`"
    option :compose_file, default: "compose.yml"
    def ports
      services = compose_yaml["services"]
      service_ports = services.transform_values { |attributes| attributes&.[]("ports") }

      service_ports.each do |service, ports|
        ports&.each do |container_port|
          puts "#{service}: #{host_port_from_container_port(service:, container_port:)}"
        end
      end
    end

    desc "server [COMMAND] [ARGS]", "Run the server in the container"
    option :env, repeatable: true, default: [], aliases: "-e", banner: "VAR=value"
    option :mapping, type: :boolean, default: true, aliases: "-m"
    option :service, default: "web", aliases: "-s"
    option :work_dir, aliases: "-w"
    def server(command = "bin/dev", *args)
      service = options[:service]
      workdir = "-w #{options[:work_dir]} " unless options[:work_dir].nil?
      environment_variables = options[:env].map { "-e #{_1}" }.join(" ")
      port_map_environment_variables = port_map_for_environment(service) if options[:mapping]
      shell_command = [ command, *args ].join(" ")
      compose_command = [
        "docker compose exec",
        environment_variables,
        port_map_environment_variables,
        workdir,
        service,
        "sh -c",
        "'#{shell_command}'",
      ].compact.join(" ")

      system(compose_command)
    end

    desc "start [COMPOSE_ARGS]", "docker compose up -d (aliased as `up`)"
    def start(*compose_args)
      system(([ "docker compose up -d" ] + compose_args).join(" "))
    end
    map "up" => :start

    desc "stop", "Stop the service(s) but preserve the container(s)"
    def stop
      system("docker compose stop")
    end

    desc "terminal", "Run a shell in the container"
    option :env, repeatable: true, default: [], aliases: "-e", banner: "VAR=value"
    option :mapping, type: :boolean, default: true, aliases: "-m"
    option :service, default: "web", aliases: "-s"
    def terminal
      service = options[:service]
      environment_variables = options[:env].map { "-e #{_1}" }.join(" ")
      port_map_environment_variables = port_map_for_environment(service) if options[:mapping]
      command = [
        "docker compose exec",
        environment_variables,
        port_map_environment_variables,
        "-it",
        service,
        "'/bin/bash'",
      ].join(" ")
      system(command)
    end

    desc "version", "Show the version number of the tool."
    def version
      puts JadeSystemsToolbox::VERSION
    end

    private

    def compose_yaml = @compose_yaml ||= YAML.load_file(options[:compose_file] || "compose.yml")

    def get_and_save_file(url, target_directory: nil, target_file_name: nil)
      file_contents = Http.get_file(url:)
      yield file_contents if block_given?
      file_name = target_file_name || Pathname.new(url).basename.to_s
      file_name = Pathname.new(target_directory) + file_name unless target_directory.nil?
      File.write(file_name, file_contents)
    end

    def host_port_from_container_port(container_port:, service: "web")
      ports = container_port.to_s.match(/([0-9]+:){0,1}([0-9]+$)/)
      if !ports[1].nil?
        ports[2].to_s
      else
        output = `docker compose port #{service} #{container_port}`
        output.match(/[0-9]+$/)
      end
    end

    def port_map(service)
      service_ports = compose_yaml.dig("services", service, "ports")
      service_ports&.reduce({}) do |acc, port|
        acc[port] = host_port_from_container_port(container_port: port, service:).to_s
        acc
      end
    end

    def port_map_for_environment(service)
      port_map(service).map do |container_port, host_port|
        "-e HOST_PORT_#{container_port}=#{host_port}"
      end.join(" ")
    end

    def handle_argument_error(command, error, args, arity)
      # Check if the error is due to an unknown option or incorrect invocation
      if (error.is_a?(Thor::UnknownArgumentError) || error.message.include?("was called with arguments")) &&
        [ "down" ].include?(command)
        # Return to let Thor proceed instead of raising the error
        nil
      else
        # Fallback to standard Thor behavior for actual code bugs
        super
      end
    end
  end
end

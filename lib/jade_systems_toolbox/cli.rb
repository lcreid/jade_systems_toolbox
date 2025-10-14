module JadeSystemsToolbox
  class Cli < Thor
    # This and other improvements from Matt: https://mattbrictson.com/blog/fixing-thor-cli-behavior
    check_unknown_options!

    class << self
      def exit_on_failure? = true
    end

    map "-h" => :help
    map "--help" => :help

    class_option :verbose, type: :boolean, default: false, aliases: "-v"

    desc "down", "docker compose down"
    def down
      system("docker compose down")
    end

    desc "edit", "devcontainer open"
    def edit
      `devcontainer open`
    end

    desc "init", "Initialize compose files and devcontainer.json"
    option :compose_file, default: "compose.yml"
    option :database, default: "sqlite", aliases: "-d"
    option :ruby_version, default: "3.4", aliases: "-r"
    option :distro_version, default: "bookworm", aliases: "-t" # For Toy Story.
    def init
      invoke :initialize_docker
      invoke :initialize_vscode, [], {}
    end

    desc "initialize_docker", "Initialize compose files"
    option :compose_file, default: "compose.yml"
    option :database, default: "sqlite", aliases: "-d"
    option :ruby_version, default: "3.4", aliases: "-r"
    option :distro_version, default: "bookworm", aliases: "-t" # For Toy Story.
    def initialize_docker
      get_and_save_file(
        "https://github.com/lcreid/docker/raw/refs/heads/main/rails-app-sqlite/compose.yml",
      ) do |file_contents|
        file_contents.gsub!(
          /jade:rails-app-[0-9]+\.[0-9]+-\w+-\w+$/,
          "jade:rails-app-#{options[:ruby_version] || "3.4"}" \
            "-#{options[:database] || "sqlite"}" \
            "-#{options[:distro_version] || bookworm}",
        )
      end

      case Gem::Platform.local.os
      when "linux"
        get_and_save_file("https://github.com/lcreid/docker/raw/refs/heads/main/Linux/compose.override.yml")
      else
        raise Error.new("Not implemented for #{Gem::Platform.local.os}", options[:verbose])
      end
    end

    desc "initilize_vscode", "Initialize devcontainer.json for vscode"
    def initialize_vscode
      get_and_save_file("https://github.com/lcreid/docker/raw/refs/heads/main/.devcontainer.json") do |file_contents|
        file_contents.gsub!(/, "compose.override.yml"/, "") unless Gem::Platform.local.os == "linux"
      end

      Dir.mkdir(".vscode") unless Dir.exist?(".vscode")
      [
        "https://github.com/lcreid/jade_systems_toolbox/raw/refs/heads/main/templates/extensions.json",
        "https://github.com/lcreid/jade_systems_toolbox/raw/refs/heads/main/templates/settings.json",
      ].each { get_and_save_file(_1, target_directory: File.join(".", ".vscode")) }
    end

    desc "open", "Open a page on the services's first port"
    option :service, default: "web"
    option :path, default: "/"
    option :container_port, default: 3000, type: :numeric
    option :protocol, default: "http"
    def open
      service = options[:service]
      path = options[:path]
      container_port = options[:container_port]
      protocol = options[:protocol]

      container_ports = compose_yaml.dig("services", "service", "ports")
      container_port = container_ports&.[](0) || container_port
      path = "/#{path}" if path[0] != "/"
      `open "#{protocol}://localhost:#{host_port_from_container_port(service:, container_port:)}#{path}"`
    end

    desc "port [CONTAINER_PORT]", "Get the host port for the CONTAINER_PORT's container port CONTAINER_PORT"
    option :service, default: "web"
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

    desc "server [COMMAND]", "Run the server in the container"
    option :service, default: "web"
    option :work_dir, aliases: "-w"
    def server(command = "bin/dev")
      service = options[:service]
      workdir = "-w #{options[:work_dir]} " unless options[:work_dir].nil?
      system("docker compose exec #{workdir}#{service} #{command}")
    end

    desc "terminal", "Run a shell in the container"
    option :service, default: "web"
    def terminal
      service = options[:service]
      system("docker compose exec -it #{service} '/bin/bash'")
    end

    desc "up", "docker compose up -d"
    def up
      system("docker compose up -d")
    end

    desc "version", "Show the version number of the tool."
    def version
      puts JadeSystemsToolbox::VERSION
    end

    private

    def compose_yaml = @compose_yaml ||= YAML.load_file(options[:compose_file] || "compose.yml")

    def get_and_save_file(url, target_directory: nil)
      file_contents = get_file_from_internet(url:)
      yield file_contents if block_given?
      file_name = Pathname.new(url).basename.to_s
      file_name = Pathname.new(target_directory) + file_name unless target_directory.nil?
      File.write(file_name, file_contents)
    end

    def get_file_from_internet(url:, redirects: 10)
      raise Errorl.new("Too many redirects", options[:verbose]) if redirects.zero?

      uri = URI.parse(url)
      request = Net::HTTP.new(uri.host, uri.port)
      response = request.get(uri.path)
      request.use_ssl = true

      case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPRedirection
        get_file_from_internet(redirects: redirects - 1, url: response["location"])
      else
        response.error!
      end
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
  end
end

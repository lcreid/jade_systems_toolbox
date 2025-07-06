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
      `docker compose down`
    end

    desc "edit", "devcontainer edit"
    def edit
      `devcontainer open`
    end

    option :compose_file, default: "compose.yml"
    option :database, default: "sqlite", aliases: "-d"
    option :ruby_version, default: "3.4", aliases: "-r"
    option :distro_version, default: "bookworm", aliases: "-t" # For Toy Story.
    desc "init", "Initialize compose files and devcontainer.json"
    def init
      invoke :initialize_docker
      invoke :initialize_vscode, [], {}
    end

    option :compose_file, default: "compose.yml"
    option :database, default: "sqlite", aliases: "-d"
    option :ruby_version, default: "3.4", aliases: "-r"
    option :distro_version, default: "bookworm", aliases: "-t" # For Toy Story.
    desc "initialize_docker", "Initialize compose files"
    def initialize_docker
      get_and_save_file("https://github.com/lcreid/docker/raw/refs/heads/main/rails-app-sqlite/compose.yml") do |file_contents|
        file_contents.gsub!(
          /jade:rails-app-[0-9]+\.[0-9]+-\w+-\w+$/,
          "jade:rails-app-#{options[:ruby_version] || '3.4'}-#{options[:database] || "sqlite"}-#{options[:distro_version] || bookworm}")
      end

      case Gem::Platform.local.os
      when "linux"
        get_and_save_file("https://github.com/lcreid/docker/raw/refs/heads/main/Linux/compose.override.yml")
      else
        raise Error.new("Not implemented for #{Gem::Platform.local.os}", options[:verbose])
      end
    end

    desc "initilaize_vscode", "Initialize devcontainer.json for vscode"
    def initialize_vscode
      get_and_save_file("https://github.com/lcreid/docker/raw/refs/heads/main/.devcontainer.json") do |file_contents|
        file_contents.gsub!(/, "compose.override.yml"/, "") unless Gem::Platform.local.os == "linux"
      end
    end

    option :service, default: "web"
    option :path, default: "/"
    option :container_port, default: 3000, type: :numeric
    option :protocol, default: "http"
    desc "open", "Open a page on the SERVICE's PORT"
    def open
      service = options[:service]
      path = options[:path]
      container_port = options[:container_port]
      protocol = options[:protocol]

      container_ports = compose_yaml.dig("services", "service", "ports")
      container_port = container_ports&.[](0) || container_port
      `open "#{protocol}://localhost:#{host_port_from_container_port(service:, container_port:)}#{path}"`
    end

    desc "port [CONTAINER_PORT]", "Get the host port for the CONTAINER_PORT's container port CONTAINER_PORT"
    option :service, default: "web"
    def port(container_port = 3000)
      service = options[:service]
      puts host_port_from_container_port(service:, container_port:)
    end

    desc "ports", "Get the host ports for the container ports defined in `compose.yml`"
    def ports
      services = compose_yaml["services"]
      service_ports = services.map { |service, attributes| [service, attributes&.[]("ports")] }.to_h

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
      puts("docker compose exec #{workdir}#{service} #{command}")
      run_via_pty("docker compose exec #{workdir}#{service} #{command}")
    end

    desc "terminal", "Run a shell in the container"
    option :service, default: "web"
    def terminal
      service = options[:service]
      run_via_pty("docker compose exec -it #{service} '/bin/bash'")
    end

    desc "up", "docker compose up -d"
    def up
      `docker compose up -d`
    end

    private

    def compose_yaml = @compose_yaml ||= YAML.load_file(options[:compose_file])

    def get_and_save_file(url)
      file_name = Pathname.new(url).basename.to_s
      file_contents = get_file_from_internet(url: )
      yield file_contents if block_given?
      File.write(file_name, file_contents)
    end

    def get_file_from_internet(redirects: 10, url:)
      raise Errorl.new("Too many redirects", options[:verbose]) if redirects.zero?

      uri = URI.parse(url)
      request = Net::HTTP.new(uri.host, uri.port)
      request.use_ssl = true
      response = request.get(uri.path)

      case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPRedirection
        get_file_from_internet(redirects: redirects - 1, url: response['location'])
      else
        response.error!
      end
    end

    def host_port_from_container_port(service: "web", container_port:)
      ports = container_port.to_s.match(/([0-9]+:){0,1}([0-9]+$)/)
      if !ports[1].nil?
        ports[2].to_s
      else
        output = `docker compose port #{service} #{container_port}`
        output.match(/[0-9]+$/)
      end
    end

    # A variation with popen was here:
    # https://nickcharlton.net/posts/ruby-subprocesses-with-stdout-stderr-streams.html
    # This implementation inspired by the docs:
    # https://docs.ruby-lang.org/en/3.4/PTY.html#method-c-spawn
    def run_via_pty(command)
      child_stdout_stderr, child_stdin, pid = PTY.spawn(command)
      puts "PID: #{pid}" if options[:verbose]
      io_threads = [
        me = Thread.new do
          $stdout.raw do |stdout|
            until (c = child_stdout_stderr.getc).nil? do
              stdout.putc c
            end
          end
        rescue Errno::EIO => exception
          puts exception.message if options[:verbose]
          me.terminate
        end,
        me = Thread.new do
          until (c = $stdin.getc).nil? do
            child_stdin.putc c
          end
        rescue Errno::EIO => exception
          puts exception.message if options[:verbose]
          me.terminate
        end,
      ]
      io_threads.each { _1.join }
    ensure
      io_threads.each { _1.terminate if _1.alive? }
      child_stdout_stderr.close
      child_stdin.close
      Process.wait(pid)
    end
  end
end

module JadeSystemsToolbox
  class Cli < Thor
    class_option :compose_file

    desc "down", "docker compose down"
    def down
      `docker compose down`
    end

    desc "edit", "devcontainer edit"
    def edit
            `devcontainer open`
    end

    desc "init", "Initialize compose files and devcontainer.json"
    def init
      initialize_docker
      initialize_vscode
    end

    desc "initialize_docker", "Initialize compose files"
    def initialize_docker
      get_and_save_file("https://github.com/lcreid/docker/raw/refs/heads/main/rails-app-sqlite/compose.yml")

      case Gem::Platform.local.os
      when "linux"
        get_and_save_file("https://github.com/lcreid/docker/raw/refs/heads/main/Linux/compose.override.yml")
      else
        raise Error, "Not implemented for #{Gem::Platform.local.os}"
      end
    end

    desc "initilaize_vscode", "Initialize devcontainer.json for vscode"
    def initialize_vscode
      # TODO: .devcontainer.json has compose.override.yml listed in it, but maybe we don't have it
      # for all O/Ss?
      get_and_save_file("https://github.com/lcreid/docker/raw/refs/heads/main/.devcontainer.json")
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
      container_port = container_ports[0] || container_port
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
      services = compose_yaml(options[:compose_file])["services"]
      service_ports = services.map { |service, attributes| [service, attributes&.[]("ports")] }.to_h

      service_ports.each do |service, ports|
        ports&.each do |container_port|
          puts "#{service}: #{host_port_from_container_port(service:, container_port:)}"
        end
      end
    end

    desc "server [COMMAND]", "Run the server in the container"
    option :service, default: "web"
    def server(command = "bin/dev")
      service = options[:service]
      command_with_io("docker compose exec #{service} #{command}")
    end

    desc "up", "docker compose up -d"
    def up
      `docker compose up -d`
    end

    private

    # https://nickcharlton.net/posts/ruby-subprocesses-with-stdout-stderr-streams.html
    def command_with_io(command)
      Open3.popen3(command) do |child_stdin, child_stdout, child_stderr, thread|
        { :out => child_stdout, :err => child_stderr }.each do |key, stream|
          Thread.new do
            until (raw_line = stream.gets).nil? do
              puts raw_line
            end
          end
        end

        Thread.new do
          until (raw_line = $stdin.gets).nil? do
            child_stdin.puts raw_line
          end
        end

        thread.join # don't exit until the external process is done
      end
    end

    def compose_yaml(compose_file = "compose.yml") = @compose_yaml ||= YAML.load_file(compose_file)

    def get_and_save_file(url)
      file_name = Pathname.new(url).basename.to_s
      file_contents = get_file_from_internet(url: )
      File.write(file_name, file_contents)
    end

    def get_file_from_internet(redirects: 10, url:)
      raise Error, "Too many redirects" if redirects.zero?

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
  end
end

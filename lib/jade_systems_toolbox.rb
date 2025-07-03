# frozen_string_literal: true

require_relative "jade_systems_toolbox/version"
require "debug"
require "net/http"

module JadeSystemsToolbox
  class Error < StandardError; end

  class << self
    def init
      initialize_docker
      initialize_vscode
    end

    def initialize_docker
      get_and_save_file("https://github.com/lcreid/docker/raw/refs/heads/main/rails-app-sqlite/compose.yml")

      case Gem::Platform.local.os
      when "linux"
        get_and_save_file("https://github.com/lcreid/docker/raw/refs/heads/main/Linux/compose.override.yml")
      else
        raise Error, "Not implemented for #{Gem::Platform.local.os}"
      end
    end

    def initialize_vscode
      # TODO: .devcontainer.json has compose.override.yml listed in it, but maybe we don't have it
      # for all O/Ss?
      get_and_save_file("https://github.com/lcreid/docker/raw/refs/heads/main/.devcontainer.json")
    end

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

    def up
      `docker compose up -d`
    end

    def edit
      `devcontainer open`
    end

    def down
      `docker compose down`
    end
  end
end

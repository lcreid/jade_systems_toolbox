# frozen_string_literal: true

module JadeSystemsToolbox
  class DockerInitializer
    def initialize(compose_file: nil, database: nil, ruby_version: nil, distro_version: nil, end_to_end_tool: nil)
      @end_to_end_tool = end_to_end_tool&.downcase&.strip
      database = database.to_s.downcase.strip
      @database = database unless %w[false none nil ""].include?(database)
      @ruby_version = ruby_version&.downcase&.strip
      @distro_version = distro_version&.downcase&.strip
    end

    def compose_file_path
      base_dir = [ "rails-app", database ].compact.join("-")
      Pathname("compose-files").join(*([ base_dir, end_to_end_tool, "compose.yml" ].compact))
    end

    def get_and_save_compose_files
      compose_file = Http.get_file(url: Http.url(path: compose_file_path))
      customize_compose_file!(compose_file)
      File.write("compose.yml", compose_file)

      case Gem::Platform.local.os
      when "linux"
        compose_override_file = Http.get_file(url: Http.url(path: "compose-files/Linux/compose.override.yml"))
        File.write("compose.override.yml", compose_override_file)
      end
    end

    def customize_compose_file!(base_file)
      base_file.gsub!("${RUBY_VERSION:-4.0}", ruby_version) unless ruby_version.nil?
      base_file.gsub!("${DISTRO_VERSION:-trixie}", distro_version) unless distro_version.nil?
      base_file
    end

    private

    attr_reader :end_to_end_tool
    attr_reader :database
    attr_reader :ruby_version
    attr_reader :distro_version
  end
end

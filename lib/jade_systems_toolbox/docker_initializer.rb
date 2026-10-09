# frozen_string_literal: true

module JadeSystemsToolbox
  class DockerInitializer
    def initialize(compose_file: nil, database: nil, ruby_version: nil, distro_version: nil, browser_tester: nil)
      @browser_tester = browser_tester&.downcase&.strip
      @compose_file = compose_file&.downcase&.strip
      database = database&.to_s&.downcase&.strip
      @database = database unless %w[false none nil].include?(database)
      @ruby_version = ruby_version&.downcase&.strip
      @distro_version = distro_version&.downcase&.strip
    end

    def compose_file_path
      Pathname("compose-files/rails-app/").join(*([ database, browser_tester, "compose.yml" ].compact))
    end

    def get_compose_file
    end

    private

    attr_reader :browser_tester
    attr_reader :compose_file
    attr_reader :database
    attr_reader :ruby_version
    attr_reader :distro_version
  end
end

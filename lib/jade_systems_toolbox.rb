# frozen_string_literal: true

require "net/http"
require "pathname"
require "thor"
require "yaml"

require_relative "jade_systems_toolbox/version"
require_relative "jade_systems_toolbox/cli"
require_relative "jade_systems_toolbox/docker_initializer"
require_relative "jade_systems_toolbox/error_reporter"
require_relative "jade_systems_toolbox/http"
require_relative "jade_systems_toolbox/vscode"

module JadeSystemsToolbox
  class Error < StandardError
    def initialize(message, verbose = false)
      @verbose = verbose
      super(message)
    end
    attr_reader :verbose
  end
end

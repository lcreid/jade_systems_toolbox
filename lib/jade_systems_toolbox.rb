# frozen_string_literal: true

require "debug"
require "net/http"
require "open3"
require "thor"
require "yaml"

require_relative "jade_systems_toolbox/version"
require_relative "jade_systems_toolbox/cli"
require_relative "jade_systems_toolbox/error_reporter"

module JadeSystemsToolbox
  class Error < StandardError
    def initialize(message, verbose = false)
      @verbose = verbose
      super(message)
    end
    attr_reader :verbose
  end
end

# frozen_string_literal: true

require "thor"
require "debug"
require "net/http"
require "yaml"

require_relative "jade_systems_toolbox/version"
require_relative "jade_systems_toolbox/cli"

module JadeSystemsToolbox
  class Error < StandardError; end
end

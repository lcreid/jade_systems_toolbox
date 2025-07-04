# frozen_string_literal: true

require "debug"
require "net/http"
require "open3"
require "thor"
require "yaml"

require_relative "jade_systems_toolbox/version"
require_relative "jade_systems_toolbox/cli"

module JadeSystemsToolbox
  class Error < StandardError; end
end

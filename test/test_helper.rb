# frozen_string_literal: true

lib_path = File.expand_path("../lib", __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

require "jade_systems_toolbox"
require "minitest/autorun"

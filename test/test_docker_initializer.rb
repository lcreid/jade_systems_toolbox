# frozen_string_literal: true

require "test_helper"

module JadeSystemsToolbox
  class TestDockerInitializer < Minitest::Test
    def test_compose_file_path
      initializer = DockerInitializer.new(database: "sqlite")
      assert_equal Pathname("compose-files/rails-app/sqlite/compose.yml"), initializer.compose_file_path
    end

    def test_compose_file_path_no_database
      initializer = DockerInitializer.new(database: "none")
      assert_equal Pathname("compose-files/rails-app/compose.yml"), initializer.compose_file_path
    end

    def test_compose_file_path_no_database_with_playwright
      initializer = DockerInitializer.new(database: "none", browser_tester: "playwright")
      assert_equal Pathname("compose-files/rails-app/playwright/compose.yml"), initializer.compose_file_path
    end

    Pathname.glob("compose-files/*").reject { _1 == Pathname("compose-files/Linux") }.each do |dir|
      define_method "test_ruby_version_in_file_#{dir.basename}" do
        initializer = DockerInitializer.new(database: "none", ruby_version: "3.3")
        expected_regexp = /^    image: lenchoreyes\/jade:rails-app-3\.3-\$\{DISTRO_VERSION:-trixie\}$/
        assert_match expected_regexp, initializer.customize_compose_file(test_compose_file(initializer))
      end

      define_method "test_distro_version_in_file_#{dir.basename}" do
        initializer = DockerInitializer.new(database: "none", distro_version: "bookworm")
        expected_regexp = /^    image: lenchoreyes\/jade:rails-app-\$\{RUBY_VERSION:-4.0\}-bookworm$/
        assert_match expected_regexp, initializer.customize_compose_file(test_compose_file(initializer))
      end
    end

    private

    def test_compose_file(initializer)
      initializer.compose_file_path.read
    end
  end
end

# frozen_string_literal: true

require "test_helper"

module JadeSystemsToolbox
  class TestDockerInitializer < Minitest::Test
    def test_compose_file_path
      initializer = DockerInitializer.new(database: "sqlite")
      assert_equal Pathname("compose-files/rails-app-sqlite/compose.yml"), initializer.compose_file_path
    end

    def test_compose_file_path_no_database
      initializer = DockerInitializer.new(database: "none")
      assert_equal Pathname("compose-files/rails-app/compose.yml"), initializer.compose_file_path
    end

    def test_compose_file_path_no_database_with_playwright
      initializer = DockerInitializer.new(database: "none", end_to_end_tool: "playwright")
      assert_equal Pathname("compose-files/rails-app/playwright/compose.yml"), initializer.compose_file_path
    end

    def test_compose_file_url
      initializer = DockerInitializer.new(database: "none", end_to_end_tool: "playwright")
      assert_equal(
        "https://github.com/lcreid/jade_systems_toolbox/raw/refs/heads/main/compose-files/rails-app/playwright/compose.yml",
        initializer.compose_file_url,
      )
    end

    Pathname.glob("compose-files/*").reject do
      [
        Pathname("compose-files/Linux"),
        Pathname("compose-files/databases"),
        Pathname("compose-files/end-to-end-tools"),
      ].include?(_1)
    end.each do |dir|
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

      [ "mariadb", "mysql", "postgres", "sqlite" ].each do |database|
        define_method "test_database_#{dir.basename}_#{database}" do
          initializer = DockerInitializer.new(database:)
          expected_regexp = /^    image: lenchoreyes\/jade:rails-app-.*-#{database}-/
          assert_match expected_regexp, initializer.customize_compose_file(test_compose_file(initializer))
        end

        [ "playwright", "selenium" ].each do |end_to_end_tool|
          define_method "test_end_to_end_tool_#{dir.basename}_#{database}_#{end_to_end_tool}" do
            initializer = DockerInitializer.new(database:, end_to_end_tool:)
            expected_regexp = /^    image: .*#{end_to_end_tool}/
            assert_match expected_regexp, initializer.customize_compose_file(test_compose_file(initializer))
          end
        end
      end
    end

    private

    def test_compose_file(initializer)
      initializer.compose_file_path.read
    end
  end
end

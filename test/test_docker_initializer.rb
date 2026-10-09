# frozen_string_literal: true

require "test_helper"

class TestDockerInitializer < Minitest::Test
  def test_compose_file_path
    initializer = JadeSystemsToolbox::DockerInitializer.new(database: "sqlite")
    assert_equal Pathname("compose-files/rails-app/sqlite/compose.yml"), initializer.compose_file_path
  end

  def test_compose_file_path_no_database
    initializer = JadeSystemsToolbox::DockerInitializer.new(database: "none")
    assert_equal Pathname("compose-files/rails-app/compose.yml"), initializer.compose_file_path
  end

  def test_compose_file_path_no_database_with_playwright
    initializer = JadeSystemsToolbox::DockerInitializer.new(database: "none", browser_tester: "playwright")
    assert_equal Pathname("compose-files/rails-app/playwright/compose.yml"), initializer.compose_file_path
  end
end

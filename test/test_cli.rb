# frozen_string_literal: true

require "test_helper"

class TestCli < Minitest::Test
  def test_read_from_internet
    cli = JadeSystemsToolbox::Cli.new([])
    response = cli.send(
      :get_file_from_internet,
      url: "https://github.com/lcreid/docker/raw/refs/heads/main/rails-app-sqlite/compose.yml",
    )
    assert response.size.positive?
  end
end

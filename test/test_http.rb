# frozen_string_literal: true

module JadeSystemsToolbox
  class TestHttp < Minitest::Test
    def test_url
      assert_equal(
        "https://github.com/lcreid/jade_systems_toolbox/raw/refs/heads/main/",
        Http.url(path: ""),
      )
    end
  end
end

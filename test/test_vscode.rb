# frozen_string_literal: true

module JadeSystemsToolbox
  class TestVscode < Minitest::Test
    def setup
      @temp_dir = Dir.mktmpdir("test_dir")
    end
    attr_reader :temp_dir

    def teardown
      FileUtils.remove_entry(temp_dir) if Dir.exist?(temp_dir)
    end

    def test_write_to_non_existent_settings_file
      Dir.chdir(temp_dir) do
        Vscode.new.write_settings_json

        expected = <<~SETTINGS.strip
          {
            "window.title": "#{Pathname.pwd.basename}"
          }
        SETTINGS
        assert_equal expected, File.read("./.vscode/settings.json")
      end
    end

    def test_write_to_empty_settings_file
      Dir.chdir(temp_dir) do
        FileUtils.mkdir(".vscode")
        FileUtils.touch("./.vscode/settings.json")

        Vscode.new.write_settings_json

        expected = <<~SETTINGS.strip
          {
            "window.title": "#{Pathname.pwd.basename}"
          }
        SETTINGS
        assert_equal expected, File.read("./.vscode/settings.json")
      end
    end

    def test_write_to_populated_settings_file
      Dir.chdir(temp_dir) do
        FileUtils.mkdir(".vscode")
        File.write("./.vscode/settings.json", <<~SETTINGS) do
          { "bogon": "bogon" }
          SETTINGS
        end

        Vscode.new.write_settings_json

        expected = <<~SETTINGS.strip
          {
            "bogon": "bogon",
            "window.title": "#{Pathname.pwd.basename}"
          }
        SETTINGS

        assert_equal expected, File.read("./.vscode/settings.json")
      end
    end

    def test_write_to_populated_settings_file_with_window_title
      Dir.chdir(temp_dir) do
        FileUtils.mkdir(".vscode")
        File.write("./.vscode/settings.json", <<~SETTINGS) do
          {
            "window.title": "notgon",
            "bogon": "bogon"
          }
          SETTINGS
        end

        Vscode.new.write_settings_json

        expected = <<~SETTINGS.strip
          {
            "window.title": "#{Pathname.pwd.basename}",
            "bogon": "bogon"
          }
        SETTINGS

        assert_equal expected, File.read("./.vscode/settings.json")
      end
    end

    # The above aren't really needed, because we know we'll have
    # the template file for settings.json.

    def test_get_and_write_devcontainer_file
      Dir.chdir(temp_dir) do
        Vscode.new.write_devcontainer_json

        assert Pathname("./.devcontainer.json").exist?
      end
    end

    def test_get_and_write_extensions_file
      Dir.chdir(temp_dir) do
        Vscode.new.write_extensions_json

        assert Pathname("./.vscode/extensions.json").exist?
      end
    end

    def test_get_and_write_settings_file
      Dir.chdir(temp_dir) do
        Vscode.new.get_and_write_settings_json

        settings = Pathname("./.vscode/settings.json")
        assert settings.exist?
        assert_equal "#{Pathname.pwd.basename}", JSON.parse(settings.read)["window.title"]
      end
    end
  end
end

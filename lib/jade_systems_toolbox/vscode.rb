# frozen_string_literal: true

require "json"

module JadeSystemsToolbox
  class Vscode
    def write_settings_json
      target_file = target_directory.join("settings.json")
      settings = if !target_file.exist? || target_file.empty?
        {}
      else
        JSON.load_file(target_file)
      end

      settings["window.title"] = Pathname.pwd.basename
      File.write(target_file, JSON.pretty_generate(settings))
    end

    def write_devcontainer_json
      devcontainer_text = Http.get_file(url: Http.url(path: "templates/.devcontainer.json"))
      devcontainer_json = JSON.parse(devcontainer_text, allow_comments: true)
      unless Gem::Platform.local.os == "linux"
        devcontainer_json["dockerComposeFile"] = [ "compose.yml" ]
      end
      Pathname(".devcontainer.json").write(JSON.pretty_generate(devcontainer_json))
    end

    def write_extensions_json
      extensions_text = Http.get_file(url: Http.url(path: "templates/extensions.json"))
      target_directory.join("extensions.json").write(extensions_text)
    end

    def get_and_write_settings_json
      settings_text = Http.get_file(url: Http.url(path: "templates/settings.json"))
      settings = JSON.parse(settings_text, allow_comments: true)
      settings["window.title"] = Pathname.pwd.basename

      target_file = target_directory.join("settings.json")
      File.write(target_file, JSON.pretty_generate(settings))
    end

    private

    def target_directory
      @target_directory unless @target_directory.nil?

      @target_directory = Pathname("./.vscode")
      FileUtils.mkdir(@target_directory) unless @target_directory.exist?
      @target_directory
    end
  end
end

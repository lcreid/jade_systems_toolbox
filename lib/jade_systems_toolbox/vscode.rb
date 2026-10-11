# frozen_string_literal: true

require "json"

module JadeSystemsToolbox
  class Vscode
    def write_settings_json
      target_directory = Pathname("./.vscode")
      make_directory(target_directory)

      target_file = target_directory.join("settings.json")
      settings = if !target_file.exist? || target_file.empty?
        {}
      else
        JSON.load_file(target_file)
      end

      settings["window.title"] = Pathname.pwd.basename
      File.write(target_file, JSON.pretty_generate(settings))
    end

    private

    def make_directory(target_directory)
      FileUtils.mkdir(target_directory) unless target_directory.exist?
    end
  end
end

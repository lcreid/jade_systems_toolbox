# frozen_string_literal: true

module JadeSystemsToolbox
  class Http
    class << self
      def url(path:)
        base_url + path.to_s
      end

      def get_file(url:, redirects: 10)
        raise Error.new("Too many redirects", options[:verbose]) if redirects.zero?

        uri = URI.parse(url)
        request = Net::HTTP.new(uri.host, uri.port)
        request.use_ssl = true
        response = request.get(uri.path)

        case response
        when Net::HTTPSuccess
          response.body
        when Net::HTTPRedirection
          get_file(redirects: redirects - 1, url: response["location"])
        else
          response.value
        end
      end

      private

      def base_url = "https://github.com/lcreid/jade_systems_toolbox/raw/refs/heads/main/"
    end
  end
end

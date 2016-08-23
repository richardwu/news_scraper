module NewsScraper
  module Extractors
    class Article
      include ExtractorsHelpers

      attr_accessor :uri

      def initialize(uri:)
        @uri = uri.gsub(/^https?:\/\//, '')
      end

      def extract
        http_request "http://#{uri}" do |response|
          response.body
        end
      end
    end
  end
end
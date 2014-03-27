require 'faraday'
require 'multi_json'

module FamilySearch
  module Middleware
    # Parses the response from JSON into a Hash. This uses the +multi_json+ gem to provide
    # more flexibility in JSON parser support and to better support other ruby environments such
    # as JRuby, Rubinius, etc.
    class MultiJsonParse < Faraday::Response::Middleware
      dependency do
        require 'json' unless defined?(::JSON)
      end

      # The method that has MultiJson parse the json string.
      def parse(body)
        MultiJson.load(body) unless body.nil?
      end
    end
  end
end

Faraday.register_middleware :response, :multi_json => FamilySearch::Middleware::MultiJsonParse

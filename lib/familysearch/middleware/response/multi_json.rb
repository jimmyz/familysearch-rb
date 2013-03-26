require 'faraday'
require 'multi_json'

module FamilySearch
  module Middleware
    class MultiJsonParse < Faraday::Response::Middleware
      dependency do
        require 'json' unless defined?(::JSON)
      end
      
      def parse(body)
        MultiJson.load(body)
      end
    end
  end
end

Faraday.register_middleware :response, :multi_json => FamilySearch::Middleware::MultiJsonParse
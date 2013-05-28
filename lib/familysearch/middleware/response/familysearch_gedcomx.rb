require 'familysearch/gedcomx'

module FamilySearch
  module Middleware
    # Parse
    class GedcomxParser < Faraday::Response::Middleware      
      # The method that has MultiJson parse the json string.
      def parse(body)
        FamilySearch::Gedcomx::FamilySearch.new body
      end
    end
  end
end

Faraday.register_middleware :response, :gedcomx_parser => FamilySearch::Middleware::GedcomxParser
require 'faraday'

module FamilySearch
  module Middleware
    class RaiseErrors < Faraday::Response::RaiseError
      def on_complete(env)
        case env[:status]
        when 401
          # response_values is a method of the RaiseError class
          raise FamilySearch::Error::BadCredentials, response_values(env) 
        when 400...600
          raise FamilySearch::Error::ClientError, response_values(env)
        end
      end
    end
  end
end

Faraday.register_middleware :response, :familysearch_errors => FamilySearch::Middleware::RaiseErrors
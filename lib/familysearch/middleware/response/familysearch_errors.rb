require 'faraday'

module FamilySearch
  # Middleware specific to the +familysearch+ gem
  module Middleware
    # Handles the raising of errors within the Faraday call stack.
    class RaiseErrors < Faraday::Response::RaiseError
      # If a 400-600 error is raised by the HTTP call, raise it within the app.
      def on_complete(env)
        case env[:status]
        when 401
          # response_values is a method of the RaiseError class
          raise FamilySearch::Error::BadCredentials, response_values(env)
        else
          super
        end
      end
    end
  end
end

Faraday::Response.register_middleware :response, :familysearch_errors => FamilySearch::Middleware::RaiseErrors

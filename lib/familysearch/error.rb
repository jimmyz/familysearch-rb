module FamilySearch
  # namespace for all of the errors that will be raised by this gem.
  module Error
    # To be raised if there is any problem with an HTTP request, meaning 40x-50x error.
    class ClientError < StandardError
      attr_reader :response
      # Allows raising an error and having the error keep the response object with it for debugging purposes.
      def initialize(response = {})
        @response = response
      end
    end
    # Raised if the client cannot successfully authenticate with basic_auth! method.
    class BadCredentials < ClientError; end
    #-- 
    # Template Related Errors
    #++
    
    # Raised if a template is not found on FamilySearch::Client#template call
    class URLTemplateNotFound < StandardError; end
    
    # Raised if a get, post, put, or delete method is called on a FamilySearch::URLTemplate that
    # doesn't support those methods.
    class MethodNotAllowed < StandardError; end
    
    # Raised if a parameter is passed to a get (or other method call) on a FamilySearch::URLTemplate object
    # that doesn't contain that parameter in the template string.
    class TemplateValueNotFound < StandardError; end
  end
end
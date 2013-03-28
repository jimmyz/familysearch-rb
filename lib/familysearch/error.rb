module FamilySearch
  module Error
    class ClientError < StandardError
      attr_reader :response
      def initialize(response = {})
        @response = response
      end
    end
    class BadCredentials < ClientError; end
    # Template Related Errors
    class URLTemplateNotFound < StandardError; end
    class MethodNotAllowed < StandardError; end
    class TemplateValueNotFound < StandardError; end
  end
end
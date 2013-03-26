module FamilySearch
  module Error
    class ClientError < StandardError
      attr_reader :response
      def initialize(response = {})
        @response = response
      end
    end
    class BadCredentials < ClientError; end
  end
end
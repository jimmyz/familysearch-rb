module FamilySearch
  module Error
    class ClientError < StandardError
      def initialize(response = {})
        @response = response
      end
    end
    class BadCredentials < ClientError; end
  end
end
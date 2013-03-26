require 'faraday'
require 'faraday_middleware'
require 'forwardable'
require 'familysearch/error'
require 'familysearch/middleware/familysearch_errors'

module FamilySearch
  class Client
    ENV_CONF = {
      :production => {
        :base_url => 'https://familysearch.org',
        :discovery_path => '/.well-known/app-meta'
      },
      :staging => {
        :base_url => 'https://stage.familysearch.org',
        :discovery_path => '/.well-known/app-meta'
      },
      :sandbox => {
        :base_url => 'https://sandbox.familysearch.org',
        :discovery_path => '/.well-known/app-meta'
      }
    }
    
    attr_accessor :access_token, :logger, :key, :environment, :discovery, :agent
    attr_reader :base_url
    
    extend Forwardable
    def_delegators :@agent, :get, :put, :post, :delete, :head, :options
    
    def initialize(options = {})
      @access_token = options[:access_token] # if options[:access_token]
      @logger = options[:logger]
      @key = options[:key]
      @environment = options[:environment] || :sandbox
      @base_url = options[:base_url] || ENV_CONF[@environment][:base_url]
      @agent = Faraday.new(@base_url) do |faraday|
        faraday.response :familysearch_errors
        faraday.response :logger, options[:logger] if options[:logger]
        # faraday.response :rashify
        faraday.response :json
        faraday.response :follow_redirects, :limit => 3, :standards_compliant => true
        faraday.headers['Accept'] = 'application/x-fs-v1+json'
        faraday.authorization('Bearer',@access_token) if @access_token
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
    end
        
    def discover!
      @discovery ||= get_discovery
    end
    
    # raises FamilySearch::Error::BadCredentials if it cannot authenticate
    def basic_auth!(username,password,key=nil)
      self.discover!
      @key ||= key if key
      @agent.basic_auth username, password
      response = @agent.get @discovery['links']['fs-identity-v2-login']['href'], :dataFormat => 'application/json', :key => @key
      @access_token = response.body['session']['id']
      @agent.authorization('Bearer',@access_token)
    end
    
    private
    def get_discovery
      result = @agent.get(ENV_CONF[@environment][:discovery_path])
      result.body
    end    
  end
end
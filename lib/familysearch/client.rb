require 'faraday'
require 'faraday_middleware'
require 'forwardable'
require 'familysearch/url_template'
require 'familysearch/error'
require 'familysearch/middleware'

# Namespace this gem functionality under FamilySearch. I realise it doesn't exactly follow gem conventions by CamelCasing FamilySearch,
# but I'm just following FamilySearch branding (familysearch.org, not family_search.org and FamilySearch not Familysearch).
module FamilySearch
  # FamilySearch::Client is the core of the +familysearch+ gem. It manages the HTTP requests to
  # the FamilySearch Platform. Under the covers, it is implemented using the wonderful Faraday ruby gem.
  # 
  # The +familysearch+ gem relies heavily on Faraday::Middleware features to handle such things such as
  # following redirects, parsing JSON, logging HTTP traffic, and raising errors for non 20x or 30x responses.
  # 
  # =Usage:
  # TODO: place some examples here.
  # 
  class Client
    # Contains a configuration for finding the discovery resource for the various systems.
    #   {
    #     :production => {
    #      :base_url => 'https://familysearch.org',
    #      :discovery_path => '/.well-known/app-meta'
    #     },
    #     :staging => {
    #      :base_url => 'https://stage.familysearch.org',
    #      :discovery_path => '/.well-known/app-meta'
    #     },
    #     :sandbox => {
    #      :base_url => 'https://sandbox.familysearch.org',
    #      :discovery_path => '/.well-known/app-meta'
    #     }
    #   }
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
    
    # Initializing a FamilySearch::Client object.
    # 
    # *Args*    :
    # - +options+: An Hash containing any of the following configuration items.
    #   - +:key+: Your developer key.
    #   - +:environment+: Accepts the following values: :production, :staging, :sandbox. 
    #     It defaults to :sandbox.
    #   - +:base_url+: If you would like to override the base url of the production, staging, 
    #     or sandbox environments, you can set this to something else like "http://localhost:8080"
    #   - +:access_token+: (optional) Your access token if you already have one.
    #   - +:logger+: (optional) An object that conforms to the Logger interface. 
    #     This could be a Rails logger, or another logger object that writes to 
    #     STDOUT or to a file.
    # *Returns* :
    # - +FamilySearch::Client+: a client object for making requests
    # 
    def initialize(options = {})
      @access_token = options[:access_token] # if options[:access_token]
      @logger = options[:logger]
      @key = options[:key]
      @environment = options[:environment] || :sandbox
      @base_url = options[:base_url] || ENV_CONF[@environment][:base_url]
      @agent = Faraday.new(@base_url) do |faraday|
        faraday.response :familysearch_errors
        faraday.response :logger, options[:logger] if options[:logger]
        faraday.response :gedcomx_parser
        faraday.response :multi_json
        faraday.response :follow_redirects, :limit => 3, :standards_compliant => true
        faraday.headers['Accept'] = 'application/x-fs-v1+json,application/x-gedcomx-atom+json,application/json'
        faraday.authorization('Bearer',@access_token) if @access_token
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
    end
    
    # This method gets information from the {Discovery Resource}[https://familysearch.org/.well-known/app-meta.json]. 
    # 
    # This call will cache the discovery resource in an attribute called @discovery. 
    # 
    # Calling this multiple times should be very cheap because of the caching. a FamilySearch::Client object will only
    # ever make an HTTP request for the discovery resource *once* in its lifetime.
    # 
    # * *Returns* :
    #   - +discovery+: the value of the @discovery attribute now that it has been populated.
    # 
    def discover!
      @discovery ||= get_discovery
    end
    
    # Performs an authentication against the /identity/v2/login resource. It uses the 
    # {Discovery Resource}[https://familysearch.org/.well-known/app-meta.json] to determine the URL to make the request to
    # in case the URL ever changes. This is only to be used for testing/development.
    # 
    # *Note*: You may *NOT* use this method for building web applications. All web applications must use OAuth/OAuth2.
    # Your web application will not be certified if it prompts for user credentials within the application. Also, you may not use
    # your personal credentials to authenticate your system in behalf of a user.
    # 
    # *Args*    :
    # - +username+: A FamilySearch username.
    # - +password+: The user's password.
    # - +key+ (optional): Your developer key if it wasn't already set when you initialized the FamilySearch::Client
    # *Returns* :
    # - true
    # *Raises*  :
    # - +FamilySearch::Error::BadCredentials+: If it cannot authenticate
    # 
    def basic_auth!(username,password,key=nil)
      self.discover!
      @key ||= key if key
      @agent.basic_auth username, password
      response = @agent.get @discovery['links']['fs-identity-v2-login']['href'], :dataFormat => 'application/json', :key => @key
      @access_token = response.body['session']['id']
      @agent.authorization('Bearer',@access_token)
      return true
    end
    
    # Used for taking advantage of URL templates provided by the {Discovery Resource}[https://familysearch.org/.well-known/app-meta.json].
    # 
    # This method will automatically call the FamilySearch::Client#discover! method in order to populate the discovery resources.
    # 
    # ===Usage:
    # 
    #   client = FamilySearch::Client.new
    #   res = client.template('person').get :pid => 'KWQS-BBQ'
    #   res.body['persons'][0]['id] # => 'KWQS-BBQ'
    # 
    # Please note, only the +get+ method has been implemented on the URLTemplate object. POST, PUT, and DELETE should be pretty easy
    # to add. It just hasn't been a priority yet.
    # 
    # *Args*    :
    # - +template_name+: The name of the template. For the "person-template", you can pass "person-template", "person", or :person
    # *Returns* :
    # - FamilySearch::URLTemplate object
    # *Raises*  :
    # - +FamilySearch::Error::URLTemplateNotFound+: if the template is not found.
    # 
    def template(template_name)
      self.discover!
      k = template_name.to_s
      template = @discovery['links'][k] || @discovery['links'][k+'-template'] || @discovery['links'][k+'-query']
      FamilySearch::URLTemplate.new self, template
    end
    
    private
    def get_discovery
      result = @agent.get(ENV_CONF[@environment][:discovery_path])
      result.body
    end    
  end
end
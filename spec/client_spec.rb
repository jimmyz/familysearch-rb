require 'spec_helper'
require 'familysearch/client'

describe FamilySearch::Client do
  
  describe "instantiating" do
    
    it "should accept a hash of config options" do
      client = FamilySearch::Client.new {}
    end
    
    it "should accept a logger option" do
      require 'logger'
      logger = Logger.new STDOUT
      client = FamilySearch::Client.new :logger => logger
      client.logger.should == logger
    end
    
    it "should accept an access_token" do
      token = 'access-token'
      client = FamilySearch::Client.new :access_token => token
      client.access_token.should == token
    end
    
    it "should only set the access_token if passed in the options" do
      client = FamilySearch::Client.new
      client.access_token.should be(nil)
      client.agent.headers['Authorization'].should be(nil)
    end
    
    it "should accept a developer key" do
      key = 'Jimmyz-cool-dev-key'
      client = FamilySearch::Client.new :key => key
      client.key.should == key
    end
    
    it "should accept an environment variable (:production)" do
      client = FamilySearch::Client.new :environment => :production
      client.environment.should == :production
      client.base_url.should == 'https://familysearch.org'
    end
    
    it "should accept an environment variable (:staging)" do
      client = FamilySearch::Client.new :environment => :staging
      client.environment.should == :staging
      client.base_url.should == 'https://stage.familysearch.org'
    end
    
    it "should accept an environment variable (:sandbox)" do
      client = FamilySearch::Client.new :environment => :sandbox
      client.environment.should == :sandbox
      client.base_url.should == 'https://sandbox.familysearch.org'
    end
    
    it "should default to sandbox environment" do
      client = FamilySearch::Client.new
      client.environment.should == :sandbox
      client.base_url.should == 'https://sandbox.familysearch.org'
    end
    
    it "should allow the overriding of the base_url" do
      client = FamilySearch::Client.new :base_url => 'http://localhost:8080'
      client.base_url.should == 'http://localhost:8080'
    end
    
    it "should instantiate a Faraday instance accessible via .agent" do
      client = FamilySearch::Client.new
      client.agent.is_a? Faraday
    end
  end
    
  describe "get" do
    def client
      @client = FamilySearch::Client.new
    end
    
    it "should accept a path and return an object" do
      VCR.use_cassette('discovery') do
        obj = client.get 'https://sandbox.familysearch.org/.well-known/app-meta'
        obj.is_a? Object
      end
    end
    
  end
  
  describe "discover!" do
    def client
      @client ||= FamilySearch::Client.new
    end
    
    it "should make a request " do
      VCR.use_cassette('discovery') do
        client.discover!
        client.discovery['links']['fs-identity-v2-login']['href'].should == 'https://sandbox.familysearch.org/identity/v2/login'
      end
    end
  end
  
  describe "basic_auth!" do
    def client()
      @client ||= FamilySearch::Client.new(:key => 'WCQY-7J1Q-GKVV-7DNM-SQ5M-9Q5H-JX3H-CMJK' )
    end
    
    it "should call discover! if it hasn't already" do
      VCR.use_cassette('discovery_auth') do
        client.should_receive(:discover!).and_call_original
        client.basic_auth! 'api-user-1241', '1782'
      end
    end
    
    it "should accept a username and password" do
      VCR.use_cassette('discovery_auth') do
        client.basic_auth! 'api-user-1241', '1782'
      end
    end
    
    it "should make a call to the fs-identity-v2-login with credentials and set the access_token" do
      VCR.use_cassette('discovery_auth') do
        client.basic_auth! 'api-user-1241', '1782'
        client.access_token.should == 'USYS8B6B487A084AA3B3C027451E23D20D5E_nbci-045-034.d.usys.fsglobal.net'
      end
    end
    
    it "should set the agent's authorization to Bearer with the access token" do
      VCR.use_cassette('discovery_auth') do
        client.agent.should_receive(:authorization).with('Bearer','USYS8B6B487A084AA3B3C027451E23D20D5E_nbci-045-034.d.usys.fsglobal.net').and_call_original
        client.basic_auth! 'api-user-1241', '1782'
      end
    end
    
    it "should raise an error if the username or password are incorrect" do
      VCR.use_cassette('discovery_auth_wrong_creds') do
        expect {client.basic_auth! 'api-user-1241', '1783' }.to raise_error(FamilySearch::Error::BadCredentials)
      end
    end
  end
  
  describe "get" do
    def client()
      unless @client
        @client = FamilySearch::Client.new(:key => 'WCQY-7J1Q-GKVV-7DNM-SQ5M-9Q5H-JX3H-CMJK' )
        @client.discover!
        @client.basic_auth! 'api-user-1241', '1782'
      end
      @client
    end
    
    # The following specs were put in place to record the VCR cassette so that I could develop on the road...
    it "should read the current user person" do
      VCR.use_cassette('current_user_person_read') do
        person = client.get client.discovery['links']['current-user-person']['href']
      end
    end
    
    it "should read a person by ID" do
      VCR.use_cassette('person_by_id') do
        person = client.get 'https://sandbox.familysearch.org/platform/tree/persons/KWQX-52J'
      end
    end
    
    it "gets the persons-with-relationships resource" do
      VCR.use_cassette('person_with_relationship') do
        person = client.get 'https://sandbox.familysearch.org/platform/tree/persons-with-relationships?person=KWQX-52J'
      end
    end
  end  
end
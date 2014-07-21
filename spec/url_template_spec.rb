require 'spec_helper'
require 'familysearch/client'

describe FamilySearch::URLTemplate do

  describe "initializing" do
    def template_hash
      {
        "template" => "https://sandbox.familysearch.org/platform/tree/persons/{pid}/change-summary{?access_token}",
        "type" => "application/atom+xml,application/json,application/x-gedcomx-atom+json,application/xml,text/html",
        "accept" => "*/*",
        "allow" => "GET",
        "title" => "Person Change Summary"
      }
    end

    def client
      FamilySearch::Client.new
    end

    it "should accept the client object and a hash" do
      template = FamilySearch::URLTemplate.new(client,template_hash)
    end

    it "should set instance attributes for the objects in the hash" do
      template = FamilySearch::URLTemplate.new(client,template_hash)
      template.template.should == "https://sandbox.familysearch.org/platform/tree/persons/{pid}/change-summary{?access_token}"
      template.type.should == "application/atom+xml,application/json,application/x-gedcomx-atom+json,application/xml,text/html"
      template.accept.should == '*/*'
      template.allow.should == ['get']
      template.title.should == 'Person Change Summary'
    end
  end

  describe "get" do
    def template_hash
      {
        "template" => "https://sandbox.familysearch.org/platform/tree/persons-with-relationships{?access_token,person}",
        "type" => "application/json,application/x-fs-v1+json,application/x-fs-v1+xml,application/xml,text/html",
        "accept" => "*/*",
        "allow" => "GET",
        "title" => "Person With Relationships"
      }
    end

    def person_template_hash
      {
        "template" => "https://sandbox.familysearch.org/platform/tree/persons/{pid}{?access_token}",
        "type" => "application/json,application/x-fs-v1+json,application/x-fs-v1+xml,application/x-gedcomx-v1+json,application/x-gedcomx-v1+xml,application/xml,text/html",
        "accept" => "application/x-fs-v1+json,application/x-fs-v1+xml,application/x-gedcomx-v1+json,application/x-gedcomx-v1+xml",
        "allow" => "HEAD,GET,POST,DELETE,GET,POST",
        "title" => "Person"
      }
    end

    def client()
      unless @client
        @client = FamilySearch::Client.new(:key => 'WCQY-7J1Q-GKVV-7DNM-SQ5M-9Q5H-JX3H-CMJK' )
        @client.discover!
        @client.basic_auth! 'api-user-1241', '1782'
      end
      @client
    end

    def template
      @template ||= FamilySearch::URLTemplate.new client, template_hash
    end

    def person_template
      @person_template ||= FamilySearch::URLTemplate.new client, person_template_hash
    end

    it "should accept a hash of options" do
      VCR.use_cassette('person_with_relationship') do
        template.get 'person' => 'KWQX-52J'
      end
    end

    it "should raise an error if the get isn't in the allowed list" do
      VCR.use_cassette('person_with_relationship') do
        template.stub(:allow).and_return([])
        expect {template.get 'person' => 'KWQX-52J'}.to raise_error(FamilySearch::Error::MethodNotAllowed)
      end
    end

    it "should raise an error if a template value isn't found in the template" do
      VCR.use_cassette('person_with_relationship') do
        expect {template.get 'person_id' => 'KWQX-52J'}.to raise_error(FamilySearch::Error::TemplateValueNotFound)
      end
    end

    it "should call get on the client with the url and values on the querystring" do
      VCR.use_cassette('person_with_relationship') do
        client
          .should_receive(:get)
          .with('https://sandbox.familysearch.org/platform/tree/persons-with-relationships?person=KWQX-52J', nil, {})
          .and_call_original
        template.get 'person' => 'KWQX-52J'
      end
    end

    it "should call get on the client with the url and no querystring if nothing needs to be called" do
      VCR.use_cassette('person_by_id') do
        client
          .should_receive(:get)
          .with('https://sandbox.familysearch.org/platform/tree/persons/KWQX-52J', nil, {})
        person_template.get 'pid' => 'KWQX-52J'
      end
    end

    it "should accept symbols in the values hash" do
      VCR.use_cassette('person_with_relationship') do
        client
          .should_receive(:get)
          .with('https://sandbox.familysearch.org/platform/tree/persons-with-relationships?person=KWQX-52J', nil, {})
          .and_call_original
        template.get :person => 'KWQX-52J'
      end
      VCR.use_cassette('person_by_id') do
        client
          .should_receive(:get)
          .with('https://sandbox.familysearch.org/platform/tree/persons/KWQX-52J', nil, {})
        person_template.get :pid => 'KWQX-52J'
      end
    end
  end
end

require 'addressable/template'
module FamilySearch
  # Used to make calls on templates that are exposed through the Discovery Resource.
  #
  # It wouldn't be expected that a developer would access this class directly, but is the
  # resulting object of a FamilySearch::Client#template call.
  #
  # =Usage:
  #
  # To use the URLTemplate, access the template from the FamilySearch::Client object like so:
  #
  #   client = FamilySearch::Client.new
  #   res = client.template('person').get :pid => 'KWQS-BBQ'
  #   res.body['persons'][0]['id] # => 'KWQS-BBQ'
  #
  # For information on which templates are available, see the discovery resource.
  #
  # [sandbox] https://sandbox.familysearch.org/.well-known/app-meta.json
  #
  # [production]  https://familysearch.org/.well-known/app-meta.json
  #
  class URLTemplate
    attr :template, :type, :accept, :allow, :title

    # Instantiate a new FamilySearch::URLTemplate
    #
    # *Args*    :
    # - +client+: a FamilySearch::Client object.
    # - +template_hash+: a hash containing template values from the Discovery Resource.
    #   Example:
    #     {
    #       "template" => "https://sandbox.familysearch.org/platform/tree/persons/{pid}{?access_token}",
    #       "type" => "application/json,application/x-fs-v1+json,application/x-fs-v1+xml,application/x-gedcomx-v1+json,application/x-gedcomx-v1+xml,application/xml,text/html",
    #       "accept" => "application/x-fs-v1+json,application/x-fs-v1+xml,application/x-gedcomx-v1+json,application/x-gedcomx-v1+xml",
    #       "allow" => "HEAD,GET,POST,DELETE,GET,POST",
    #       "title" => "Person"
    #     }
    # *Returns* :
    # - +FamilySearch::URLTemplate+ object
    # *Raises*  :
    # - +FamilySearch::Error::URLTemplateNotFound+: if the template_hash is nil.
    #   This is intended to catch problems if FamilySearch::Client#template method doesn't find
    #   a template and still instantiates this object.
    #
    def initialize(client,template_hash)
      raise FamilySearch::Error::URLTemplateNotFound if template_hash.nil?
      @client = client
      @template = template_hash['template']
      @type = template_hash['type']
      @accept = template_hash['accept']
      @allow = template_hash['allow'].split(',').map{|v|v.downcase}
      @title = template_hash['title']
    end

    # Calls HTTP GET on the URL template. It takes the +template_values+ hash and merges the values into the template.
    #
    # A template will contain a URL like this:
    #   https://sandbox.familysearch.org/platform/tree/persons-with-relationships{?access_token,person}
    # or
    #   https://sandbox.familysearch.org/platform/tree/persons/{pid}/matches{?access_token}
    #
    # The {?person} type attributes in the first example will be passed as querystring parameters. These will automatically be URL Encoded
    # by the underlying Faraday library that handles the HTTP request.
    #
    # The {pid} type attibutes will simply be substituted into the URL.
    #
    # *Note*: The +access_token+ parameter doesn't need to be passed here. This should be handled by the FamilySearch::Client's
    # Authorization header.
    #
    # *Args*    :
    # - +template_values+: A Hash object containing the values for the items in the URL template. For example, if the URL is:
    #     https://sandbox.familysearch.org/platform/tree/persons-with-relationships{?access_token,person}
    #   then you would pass a hash like this:
    #     :person => 'KWQS-BBQ'
    #   or
    #     'person' => 'KWQS-BBQ'
    # *Returns* :
    # - +Faraday::Response+ object. This object contains methods +body+, +headers+, and +status+. +body+ should contain a Hash of the
    #   parsed result of the request.
    # *Raises*  :
    # - +FamilySearch::Error::MethodNotAllowed+: if you call +get+ for a template that doesn't allow GET method.
    #
    def get(template_values)
      raise FamilySearch::Error::MethodNotAllowed unless allow.include?('get')
      etag            = template_values.delete(:etag)
      template_values = validate_values(template_values)
      t = Addressable::Template.new(@template)
      url = t.expand(template_values).to_s
      @client.get do |req|
        req.url(url)
        req.headers['If-None-Match'] = etag if etag.present?
      end
    end

    # Calls HTTP HEAD on the URL template. It takes the +template_values+ hash and merges the values into the template.
    #
    # A template will contain a URL like this:
    #   https://sandbox.familysearch.org/platform/tree/persons-with-relationships{?access_token,person}
    # or
    #   https://sandbox.familysearch.org/platform/tree/persons/{pid}/matches{?access_token}
    #
    # The {?person} type attributes in the first example will be passed as querystring parameters. These will automatically be URL Encoded
    # by the underlying Faraday library that handles the HTTP request.
    #
    # The {pid} type attibutes will simply be substituted into the URL.
    #
    # *Note*: The +access_token+ parameter doesn't need to be passed here. This should be handled by the FamilySearch::Client's
    # Authorization header.
    #
    # *Args*    :
    # - +template_values+: A Hash object containing the values for the items in the URL template. For example, if the URL is:
    #     https://sandbox.familysearch.org/platform/tree/persons-with-relationships{?access_token,person}
    #   then you would pass a hash like this:
    #     :person => 'KWQS-BBQ'
    #   or
    #     'person' => 'KWQS-BBQ'
    # *Returns* :
    # - +Faraday::Response+ object. This object contains methods +body+, +headers+, and +status+. +body+ should contain a Hash of the
    #   parsed result of the request.
    # *Raises*  :
    # - +FamilySearch::Error::MethodNotAllowed+: if you call +head+ for a template that doesn't allow HEAD method.
    #
    def head(template_values)
      raise FamilySearch::Error::MethodNotAllowed unless allow.include?('head')
      template_values = validate_values(template_values)
      t = Addressable::Template.new(@template)
      url = t.expand(template_values).to_s
      @client.head url
    end

    private
    def value_array
      template_value_array = []
      values = @template.scan(/\{([^}]*)\}/).flatten
      values.each do |value|
        value.gsub!('?','')
        template_value_array += value.split(',')
      end
      template_value_array
    end

    def validate_values(template_values)
      vals = value_array
      stringified_hash = {}
      template_values.each do |k,v|
        stringified_hash[k.to_s] = v
        raise FamilySearch::Error::TemplateValueNotFound unless vals.include?(k.to_s)
      end
      stringified_hash
    end
  end
end

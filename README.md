# familysearch gem

## Installation

You can install it from the commandline.

    gem install familysearch

Or add it to a Gemfile for use with Bundler

    gem "familysearch", "~> 0.3.0 "


## Basic Usage

Here's how to use it

    require 'rubygems'
    require 'familysearch'
    
    # Instantiate a Client object
    client = FamilySearch::Client.new :environment => :sandbox, :key => 'your-dev-key-here'
        
    # For testing, you can use basic auth to get a session, 
    # Don't do this in your production web app. Use OAuth 2.0
    client.basic_auth! 'your-username', 'your-password'
    
    # the client object has a get, post, put, delete, and head method
    response = client.get(client.discovery['links']['current-user-person']['href'])
    response.status #=> 200
	
	# The response contains a Hash object on the body attribute.
    response.body['persons'][0]['display']['name']

## Discovery Resource

The FamilySearch Platform is RESTful and conforms to HATEOAS principles. This means that you can discover addressable resources in the hypermedia that is returned by the platform. As a starting point, a Discovery Resource is offered up that lists resources that you can programatically begin to explore.

The Discovery Resource is intended to be utilized heavily by this gem. One of the benefits of this is that if FamilySearch needs to change a URI for any resource, your application should continue to work because the URI will be updated in the discovery resource. URIs are not constructed by hard-coding paths within the gem. They are constructed by utilizing templates exposed via the Discovery Resource.

### URL Templates

The `familysearch` gem makes use of the templates exposed on the Discovery Resource. For example, the discovery resource exposes a person-template that looks like this:

	"person-template" : {
      "template" : "https://sandbox.familysearch.org/platform/tree/persons/{pid}{?access_token}",
      "type" : "application/json,application/x-fs-v1+json,application/x-fs-v1+xml,application/x-gedcomx-v1+json,application/x-gedcomx-v1+xml,application/xml,text/html",
      "accept" : "application/x-fs-v1+json,application/x-fs-v1+xml,application/x-gedcomx-v1+json,application/x-gedcomx-v1+xml",
      "allow" : "HEAD,GET,POST,DELETE,GET,POST",
      "title" : "Person"
    }
 
To utilize this template, you can do the following from your `client` object. 

	response = client.template('person-template').get :pid => 'KWQS-BBQ'

You can also use `'person'`, or `:person` instead of 'person-template'. The client will still find the appropriate template.

The above code is equivalent to the following:

	response = client.get 'https://sandbox.familysearch.org/platform/tree/persons/KWQX-52J'

## Faraday

This gem depends upon the wonderful `faraday` gem for handling HTTP calls. One of the advantages of this is that you could possibly swap out underlying http libraries. Currently, it utilizes the Net::HTTP library, but in the future it could potentially support other libraries such as EventMachine's asynchronous http library.

## MultiJson

This gem makes use of the awesome `multi_json` gem. This allows you to utilize faster json libraries if desired, such as `oj` or `yajil`. If you have `require`ed either of these libraries prior to requiring the `familysearch` gem, then it will make use of the faster JSON parsing libraries.

## Future

Next on the roadmap:

* Support post, put, delete, head, etc. from the FamilySearch::URLTemplate objec. (currently only supports get)
* Better object deserialization. Currently, everything is just a dumb Hash. I'd like to be able to allow an option to pass in another middleware for smarter objects (pershaps Hashie::Mash or Rash, or some sort of GedcomX model).
* More documentation examples.

## Bugs and Feature Requests

Please file bug reports and 

## Copyright

Copyright (c) 2013 Jimmy Zimmerman. See LICENSE.txt for
further details.


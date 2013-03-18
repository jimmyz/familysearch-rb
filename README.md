# familysearch gem

## Installation

You can install it from the commandline.

    gem install familysearch

Or add it to a Gemfile for use with Bundler

    gem "familysearch", "~> 0.1.0 "


## Basic Usage

Here's how to use it

    require 'rubygems'
    require 'familysearch'
    
    # Instantiate a Client object
    client = FamilySearch::Client.new :environment => :sandbox, :key => 'your-dev-key-here'
    
    # Load the Discovery resource
    client.discover!
    
    # For testing, you can use basic auth to get a session, 
    # Don't do this in your production web app. Use OAuth 2.0
    client.basic_auth! 'your-username', 'your-password'
    
    me = client.get(client.discovery.links.current_user_person.href).body
    
    # The response object is a Rash object (Hashie extension) which allows you to traverse via dot notation.
    # It also allows an _ to be placed at the end of elements you are traversing to guard against nil values.
    me.persons[0].display_.name

More documentation coming soon...

## Copyright

Copyright (c) 2013 Jimmy Zimmerman. See LICENSE.txt for
further details.


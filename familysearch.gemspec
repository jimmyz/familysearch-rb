# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "familysearch/version"

Gem::Specification.new do |s|
  s.name        = "familysearch"
  s.version     = FamilySearch::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jimmy Zimmerman"]
  s.email       = ["jimmy.zimmerman@gmail.com"]
  s.homepage    = "https://github.com/jimmyz/familysearch-rb"
  s.summary     = %q{A gem for the FamilySearch Platform.}
  s.description = %q{A gem for the FamilySearch Platform. Documentation for the FamilySearch Platform can be found at https://familysearch.org/developers/.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("faraday", ["~> 0.8.4"])
  s.add_dependency("faraday_middleware", ["~> 0.9.0"])
  s.add_dependency("multi_json", ["~> 1.0"])
  s.add_dependency("addressable", ["~> 2.3.3"])
  s.add_dependency("familysearch-gedcomx", ["~> 1.0.2"])

  s.add_development_dependency("rspec", ["~> 2.99.0"])
  s.add_development_dependency("shoulda", ["~> 3.3.2"])
  s.add_development_dependency("bundler", [">= 1.2.3"])
  s.add_development_dependency("vcr", ["~> 2.4.0"])
  s.add_development_dependency("webmock", ["~> 1.10.0"])
  s.add_development_dependency("rake")
end

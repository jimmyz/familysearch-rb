require 'rubygems'
require 'faraday'
require 'faraday_middleware'
require 'pp'

conn = Faraday.new do |faraday|
  faraday.request  :url_encoded             # form-encode POST params
  faraday.response :logger                  # log requests to STDOUT
  faraday.response :json
  faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
end

conn.basic_auth('{username}','{password}')
response = conn.get('https://sandbox.familysearch.org/identity/v2/login?key={key}&dataFormat=application/json')
token = response.env[:body]["session"]["id"]
puts token

headers = {
  'Authorization' => "Bearer #{token}",
  'Accept' => 'application/x-fs-v1+json'
}

platform = Faraday.new(:headers => headers) do |faraday|
  faraday.response :logger                  # log requests to STDOUT
  faraday.response :json
  faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
end

discovery = platform.get("https://familysearch.org/.well-known/app-meta")

pp discovery.env[:body]
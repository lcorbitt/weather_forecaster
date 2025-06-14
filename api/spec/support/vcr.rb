require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true
  config.filter_sensitive_data('<WEATHER_API_KEY>') { ENV['WEATHER_API_KEY'] }
  config.filter_sensitive_data('<GEOCODING_API_KEY>') { ENV['GEOCODING_API_KEY'] }
  
  # Ignore localhost requests
  config.ignore_localhost = true
  
  # Configure which HTTP requests to record
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body],
    allow_playback_repeats: true
  }
  
  # Ignore requests to the geocoding service
  config.ignore_hosts 'nominatim.openstreetmap.org'
end 
Geocoder.configure(
  # Geocoding options
  timeout: 3,                      # geocoding service timeout (secs)
  lookup: :nominatim,             # name of geocoding service (symbol)
  language: :en,                  # ISO-639 language code
  use_https: true,               # use HTTPS for lookup requests? (if supported)
  
  # HTTP headers for request
  http_headers: { "User-Agent" => "WeatherForecaster Rails App" },

  # Cache responses
  cache: Rails.cache,
  cache_options: {
    expiration: 30.minutes,
    prefix: 'geocoder:'
  },

  # Calculation options
  units: :mi,                    # :km for kilometers or :mi for miles
  distances: :linear             # :spherical or :linear
) 
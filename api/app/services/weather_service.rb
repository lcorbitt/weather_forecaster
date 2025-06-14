class WeatherService
  class WeatherAPIError < StandardError; end

  def initialize
    @connection = Faraday.new(url: ENV.fetch('WEATHER_API_BASE_URL', 'https://api.weatherapi.com/v1')) do |faraday|
      faraday.request :json
      faraday.response :json, content_type: /\bjson$/
      faraday.adapter Faraday.default_adapter
    end

    @api_key = ENV.fetch('WEATHER_API_KEY')
  end

  # Main method for getting weather forecast
  def get_forecast(location)
    # Try to find cached forecast
    if (forecast = location.current_forecast)
      forecast.from_cache = true
      return forecast
    end

    # Fetch fresh data from API
    response = @connection.get('forecast.json') do |req|
      req.params = {
        key: @api_key,
        q: location.address,
        days: 3
      }
    end

    data = handle_response(response)
    return nil unless data

    # Create new forecast
    forecast = location.weather_forecasts.create!(
      current_temp: extract_value(data, %w[current temp_f]),
      high_temp: extract_value(data, %w[forecast forecastday 0 day maxtemp_f]),
      low_temp: extract_value(data, %w[forecast forecastday 0 day mintemp_f]),
      conditions: extract_value(data, %w[current condition text]),
      cached_at: Time.current
    )

    forecast.from_cache = false
    forecast
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
    raise WeatherAPIError, 'Unable to connect to weather service'
  rescue NoMethodError, TypeError => e
    raise WeatherAPIError, 'Invalid response format from weather service'
  end

  # Method for fetching raw weather data
  def fetch_weather(address)
    cache_key = "weather_#{address}"
    
    # Try to find cached data
    if Rails.cache.exist?(cache_key)
      return Rails.cache.read(cache_key)
    end

    # Fetch fresh data from API
    response = @connection.get('forecast.json') do |req|
      req.params = {
        key: @api_key,
        q: address,
        days: 3
      }
    end

    data = handle_response(response)
    return nil unless data

    # Format the response
    weather_data = {
      'location' => {
        'name' => data['location']['name'],
        'region' => data['location']['region']
      },
      'current' => {
        'temp_f' => data['current']['temp_f'],
        'temp_c' => data['current']['temp_c'],
        'condition' => {
          'text' => data['current']['condition']['text']
        }
      }
    }

    # Cache the data
    Rails.cache.write(cache_key, weather_data, expires_in: 30.minutes)
    weather_data
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
    raise WeatherAPIError, 'Unable to connect to weather service'
  rescue NoMethodError, TypeError => e
    raise WeatherAPIError, 'Invalid response format from weather service'
  end

  private

  def handle_response(response)
    case response.status
    when 200
      if response.body.is_a?(Hash)
        response.body
      else
        JSON.parse(response.body)
      end
    when 401
      raise WeatherAPIError, 'Invalid API key'
    when 429
      raise WeatherAPIError, 'API rate limit exceeded'
    when 404
      raise WeatherAPIError, 'Location not found'
    else
      raise WeatherAPIError, "Unexpected error: #{response.status}"
    end
  rescue JSON::ParserError => e
    raise WeatherAPIError, 'Invalid response format from weather service'
  end

  def extract_value(data, keys)
    value = keys.reduce(data) { |acc, key| acc.is_a?(Hash) ? acc[key] : acc[key.to_i] }
    raise WeatherAPIError, 'Invalid response format from weather service' if value.nil?
    value
  end
end 
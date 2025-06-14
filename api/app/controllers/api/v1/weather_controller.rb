module Api
  module V1
    # Handles weather forecast requests for given addresses
    # @api public
    class WeatherController < BaseController
      before_action :validate_address, only: [:forecast]

      # Retrieves the current weather forecast for a given address
      #
      # @example
      #   GET /api/v1/weather/forecast?address=123 Main St, New York, NY
      #
      # @param [String] address The address to get the forecast for
      #
      # @return [JSON] Weather forecast data including:
      #   - current_temp [Float] Current temperature
      #   - high_temp [Float] High temperature
      #   - low_temp [Float] Low temperature
      #   - conditions [String] Weather conditions description
      #   - from_cache [Boolean] Whether the forecast was retrieved from cache
      #   - location_address [String] The address the forecast is for
      #   - cached_at [String] ISO8601 timestamp of when the forecast was cached
      #
      # @raise [BadRequest] If address parameter is missing
      # @raise [UnprocessableEntity] If address is invalid
      # @raise [NotFound] If location cannot be found
      # @raise [ServiceUnavailable] If weather service is unavailable
      # @raise [InternalServerError] If an unexpected error occurs
      def forecast
        zip_code = extract_zip_code(forecast_params[:address])
        return render_error('Invalid ZIP code', :unprocessable_entity) unless valid_zip_code?(zip_code)

        location = Location.find_or_create_by!(zip_code: zip_code) do |loc|
          loc.address = forecast_params[:address]
          loc.geocode
        end
        
        return if performed?

        forecast = WeatherService.new.get_forecast(location)
        
        if forecast.nil?
          render_error('Unable to fetch weather data', :service_unavailable)
        else
          render json: {
            data: {
              current_temp: forecast.current_temp,
              high_temp: forecast.high_temp,
              low_temp: forecast.low_temp,
              conditions: forecast.conditions,
              location_address: forecast.location.address
            },
            meta: {
              cached: forecast.from_cache?,
              cached_at: forecast.cached_at&.iso8601,
              expires_at: (forecast.cached_at + 30.minutes).iso8601
            }
          }, status: :ok
        end
      rescue WeatherService::WeatherAPIError => e
        handle_weather_api_error(e)
      rescue StandardError => e
        render_error('An unexpected error occurred', :internal_server_error)
      end

      private

      # Strong parameters for forecast requests
      # @return [ActionController::Parameters] Permitted parameters
      def forecast_params
        params.permit(:address)
      end

      def validate_address
        if forecast_params[:address].blank?
          render_error('Address is required', :bad_request)
          return
        end
      end

      def extract_zip_code(address)
        # Extract ZIP code from address string
        # This regex matches both 5-digit and 9-digit ZIP codes
        zip_match = address.match(/\b\d{5}(?:-\d{4})?\b/)
        zip_match&.to_s
      end

      def valid_zip_code?(zip_code)
        zip_code.present? && zip_code.match?(/^\d{5}(?:-\d{4})?$/)
      end

      def handle_weather_api_error(error)
        case error.message
        when 'Invalid API key'
          render_error(error.message, :internal_server_error)
        when 'API rate limit exceeded', 'Unable to connect to weather service'
          render_error(error.message, :service_unavailable)
        when 'Location not found'
          render_error(error.message, :not_found)
        else
          render_error('An unexpected error occurred', :internal_server_error)
        end
      end

      # Renders an error response with the given message and status
      # @param message [String] The error message
      # @param status [Symbol] The HTTP status code
      def render_error(message, status)
        render json: { error: message }, status: status
      end
    end
  end
end 
module Api
  module V1
    # Base controller for API V1 endpoints
    # Provides common functionality for all API controllers
    #
    # @abstract Subclass and use as base for API controllers
    # @api public
    class BaseController < ApplicationController
      # Handle common API errors with appropriate responses
      rescue_from ActiveRecord::RecordNotFound do |e|
        render_error(e.message, :not_found)
      end

      rescue_from ActionController::ParameterMissing do |e|
        render_error(e.message, :bad_request)
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render_error(e.message, :unprocessable_entity)
      end

      rescue_from WeatherService::WeatherAPIError do |e|
        status = case e.message
                when 'Invalid API key' then :internal_server_error
                when 'Rate limit exceeded', 'Unable to connect to weather service' then :service_unavailable
                when 'Location not found' then :not_found
                else :internal_server_error
                end
        render_error(e.message, status)
      end

      rescue_from StandardError do |e|
        Rails.logger.error("Unexpected error: #{e.message}\n#{e.backtrace.join("\n")}")
        render_error('An unexpected error occurred', :internal_server_error)
      end

      private

      # Renders a JSON error response with the given message and status
      #
      # @param [String] message The error message to return
      # @param [Symbol] status The HTTP status code to return
      #
      # @return [void]
      def render_error(message, status)
        render json: { error: message }, status: status
      end
    end
  end
end 
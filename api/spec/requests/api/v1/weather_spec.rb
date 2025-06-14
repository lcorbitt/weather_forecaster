require 'rails_helper'

RSpec.describe "Api::V1::Weather", type: :request do
  describe "GET /api/v1/weather/forecast" do
    let(:address) { "123 Main St, Beverly Hills, CA 90210" }
    let(:weather_service) { instance_double(WeatherService) }
    let(:location) { build(:location, address: address, zip_code: '90210') }
    let(:forecast) { build(:weather_forecast, location: location) }

    before do
      # Mock geocoding
      allow_any_instance_of(Location).to receive(:geocode).and_return([34.0928, -118.4744])
      
      # Mock weather service
      allow(WeatherService).to receive(:new).and_return(weather_service)
      allow(weather_service).to receive(:get_forecast).and_return(forecast)
    end

    context "when requesting a new forecast" do
      it "returns a successful response with forecast data" do
        get "/api/v1/weather/forecast", params: { address: address }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response).to include('data', 'meta')
        expect(json_response['data']).to include(
          'current_temp',
          'high_temp',
          'low_temp',
          'conditions',
          'location_address'
        )
        expect(json_response['meta']).to include(
          'cached',
          'cached_at',
          'expires_at'
        )
        expect(json_response['meta']['cached']).to be false
      end

      it "reuses location for same ZIP code with different address" do
        # First request creates the location
        get "/api/v1/weather/forecast", params: { address: address }
        
        # Second request with different address but same ZIP code
        get "/api/v1/weather/forecast", params: { address: "456 Palm Dr, Beverly Hills, CA 90210" }
        
        expect(Location.count).to eq(1)
        expect(Location.first.zip_code).to eq('90210')
      end
    end

    context "when a cached forecast exists" do
      before do
        forecast.from_cache = true
      end

      it "returns the cached forecast" do
        get "/api/v1/weather/forecast", params: { address: address }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['meta']['cached']).to be true
      end
    end

    context "when weather service fails" do
      before do
        allow(weather_service).to receive(:get_forecast).and_return(nil)
      end

      it "returns an error" do
        get "/api/v1/weather/forecast", params: { address: address }

        expect(response).to have_http_status(:service_unavailable)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Unable to fetch weather data")
      end
    end

    context "when address parameter is missing" do
      it "returns a bad request error" do
        get "/api/v1/weather/forecast"

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Address is required')
      end
    end

    context "when address has invalid ZIP code" do
      it "returns an unprocessable entity error for missing ZIP" do
        get "/api/v1/weather/forecast", params: { address: "123 Main St, City, ST" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Invalid ZIP code')
      end

      it "returns an unprocessable entity error for invalid ZIP format" do
        get "/api/v1/weather/forecast", params: { address: "123 Main St, City, ST 1234" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Invalid ZIP code')
      end
    end
  end
end

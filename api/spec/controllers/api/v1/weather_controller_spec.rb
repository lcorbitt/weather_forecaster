require 'rails_helper'

RSpec.describe Api::V1::WeatherController, type: :controller do
  describe 'GET #forecast' do
    let(:address) { '123 Main St, Beverly Hills, CA 90210' }
    let(:weather_service) { instance_double(WeatherService) }

    before do
      # Mock geocoding
      allow_any_instance_of(Location).to receive(:geocode).and_return([34.0928, -118.4744])
      
      # Mock weather service
      allow(WeatherService).to receive(:new).and_return(weather_service)
    end

    context 'with valid address' do
      let(:location) { build(:location, address: address, zip_code: '90210') }
      let(:forecast) { build(:weather_forecast, location: location) }

      before do
        allow(weather_service).to receive(:get_forecast).and_return(forecast)
      end

      it 'returns a successful response' do
        get :forecast, params: { address: address }
        expect(response).to have_http_status(:success)
      end

      it 'returns forecast data in the correct format' do
        get :forecast, params: { address: address }
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
      end

      it 'creates a new location if it does not exist' do
        expect {
          get :forecast, params: { address: '456 Oak St, Chicago, IL 60601' }
        }.to change(Location, :count).by(1)
      end

      it 'reuses existing location with same ZIP code' do
        location.save!
        expect {
          get :forecast, params: { address: '456 Palm Dr, Beverly Hills, CA 90210' }
        }.not_to change(Location, :count)
      end

      context 'when response is cached' do
        before do
          forecast.from_cache = true
        end

        it 'indicates the response is from cache' do
          get :forecast, params: { address: address }
          json_response = JSON.parse(response.body)
          expect(json_response['meta']['cached']).to be true
        end
      end
    end

    context 'with invalid parameters' do
      it 'returns an error when address is missing' do
        get :forecast
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Address is required')
      end

      it 'returns an error when address is blank' do
        get :forecast, params: { address: '' }
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Address is required')
      end

      it 'returns an error when address has no ZIP code' do
        get :forecast, params: { address: 'Invalid Address Without ZIP' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Invalid ZIP code')
      end

      it 'returns an error when ZIP code format is invalid' do
        get :forecast, params: { address: '123 Main St, City, ST 1234' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Invalid ZIP code')
      end
    end

    context 'when weather service fails' do
      let(:address) { '123 Main St, New York, NY 10001' }

      context 'with invalid API key' do
        before do
          allow(weather_service).to receive(:get_forecast)
            .and_raise(WeatherService::WeatherAPIError.new('Invalid API key'))
        end

        it 'returns an internal server error' do
          get :forecast, params: { address: address }
          expect(response).to have_http_status(:internal_server_error)
          expect(JSON.parse(response.body)['error']).to eq('Invalid API key')
        end
      end

      context 'with rate limit exceeded' do
        before do
          allow(weather_service).to receive(:get_forecast)
            .and_raise(WeatherService::WeatherAPIError.new('API rate limit exceeded'))
        end

        it 'returns a service unavailable error' do
          get :forecast, params: { address: address }
          expect(response).to have_http_status(:service_unavailable)
          expect(JSON.parse(response.body)['error']).to eq('API rate limit exceeded')
        end
      end

      context 'with invalid location' do
        before do
          allow(weather_service).to receive(:get_forecast)
            .and_raise(WeatherService::WeatherAPIError.new('Location not found'))
        end

        it 'returns a not found error' do
          get :forecast, params: { address: address }
          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)['error']).to eq('Location not found')
        end
      end

      context 'with network error' do
        before do
          allow(weather_service).to receive(:get_forecast)
            .and_raise(WeatherService::WeatherAPIError.new('Unable to connect to weather service'))
        end

        it 'returns a service unavailable error' do
          get :forecast, params: { address: address }
          expect(response).to have_http_status(:service_unavailable)
          expect(JSON.parse(response.body)['error']).to eq('Unable to connect to weather service')
        end
      end
    end
  end
end 
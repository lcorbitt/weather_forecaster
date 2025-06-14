require 'rails_helper'

RSpec.describe WeatherService do
  let(:service) { described_class.new }
  let(:location) { create(:location) }
  let(:mock_weather_data) do
    {
      'location' => { 'name' => 'Beverly Hills', 'region' => 'California' },
      'current' => {
        'temp_f' => 72.5,
        'temp_c' => 22.5,
        'condition' => { 'text' => 'Sunny' }
      },
      'forecast' => {
        'forecastday' => [{
          'day' => {
            'maxtemp_f' => 75.0,
            'mintemp_f' => 65.0
          }
        }]
      }
    }
  end

  describe '#get_forecast', :vcr do
    context 'when forecast is not cached' do
      before do
        stub_request(:get, /#{ENV['WEATHER_API_BASE_URL']}/)
          .with(query: hash_including({ q: location.address }))
          .to_return(status: 200, body: mock_weather_data.to_json)
      end

      it 'creates a new forecast' do
        expect {
          service.get_forecast(location)
        }.to change(WeatherForecast, :count).by(1)
      end

      it 'returns a forecast with correct attributes' do
        forecast = service.get_forecast(location)
        
        expect(forecast).to be_a(WeatherForecast)
        expect(forecast.current_temp).to eq(72.5)
        expect(forecast.high_temp).to eq(75.0)
        expect(forecast.low_temp).to eq(65.0)
        expect(forecast.conditions).to eq('Sunny')
        expect(forecast).not_to be_from_cache
      end
    end

    context 'when forecast is cached' do
      let!(:cached_forecast) do
        create(:weather_forecast,
          location: location,
          current_temp: 70.0,
          high_temp: 75.0,
          low_temp: 65.0,
          conditions: 'Partly Cloudy',
          cached_at: 15.minutes.ago
        )
      end

      it 'returns the cached forecast' do
        forecast = service.get_forecast(location)
        
        expect(forecast).to eq(cached_forecast)
        expect(forecast).to be_from_cache
      end

      it 'does not make an API call' do
        service.get_forecast(location)
        expect(WebMock).not_to have_requested(:get, /#{ENV['WEATHER_API_BASE_URL']}/)
      end
    end

    context 'when the API request fails' do
      context 'with invalid API key' do
        before do
          stub_request(:get, /#{ENV['WEATHER_API_BASE_URL']}/)
            .to_return(status: 401, body: { error: 'Invalid API Key' }.to_json)
        end

        it 'raises WeatherAPIError' do
          expect {
            service.get_forecast(location)
          }.to raise_error(WeatherService::WeatherAPIError, 'Invalid API key')
        end
      end

      context 'with rate limit exceeded' do
        before do
          stub_request(:get, /#{ENV['WEATHER_API_BASE_URL']}/)
            .to_return(status: 429, body: { error: 'Rate limit exceeded' }.to_json)
        end

        it 'raises WeatherAPIError' do
          expect {
            service.get_forecast(location)
          }.to raise_error(WeatherService::WeatherAPIError, 'API rate limit exceeded')
        end
      end

      context 'with invalid location' do
        before do
          stub_request(:get, /#{ENV['WEATHER_API_BASE_URL']}/)
            .to_return(status: 404, body: { error: 'Location not found' }.to_json)
        end

        it 'raises WeatherAPIError' do
          expect {
            service.get_forecast(location)
          }.to raise_error(WeatherService::WeatherAPIError, 'Location not found')
        end
      end

      context 'with network error' do
        before do
          stub_request(:get, /#{ENV['WEATHER_API_BASE_URL']}/)
            .to_raise(Faraday::ConnectionFailed.new('Failed to connect'))
        end

        it 'raises WeatherAPIError' do
          expect {
            service.get_forecast(location)
          }.to raise_error(WeatherService::WeatherAPIError, 'Unable to connect to weather service')
        end
      end
    end
  end
end 
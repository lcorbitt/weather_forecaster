require 'rails_helper'

RSpec.describe WeatherForecast, type: :model do
  describe 'validations' do
    subject { build(:weather_forecast) }

    it { should validate_presence_of(:current_temp) }
    it { should validate_presence_of(:high_temp) }
    it { should validate_presence_of(:low_temp) }
    it { should validate_presence_of(:conditions) }
    
    # We don't need to test cached_at presence validation since it's set automatically
    it 'sets cached_at before validation' do
      forecast = build(:weather_forecast, cached_at: nil)
      expect(forecast.cached_at).to be_nil
      forecast.valid?
      expect(forecast.cached_at).not_to be_nil
    end
  end

  describe 'associations' do
    it { should belong_to(:location) }
  end

  describe 'callbacks' do
    let(:location) { build(:location) }
    let(:forecast) { build(:weather_forecast, location: location, cached_at: nil) }

    before do
      VCR.use_cassette('weather_forecast_callbacks') do
        location.save
      end
    end

    it 'sets cached_at before validation on create' do
      expect(forecast.cached_at).to be_nil
      forecast.valid?
      expect(forecast.cached_at).not_to be_nil
    end
  end

  describe '.current' do
    let(:location) { build(:location) }
    let(:old_time) { Time.current - 31.minutes }
    let(:current_time) { Time.current - 29.minutes }

    before do
      VCR.use_cassette('weather_forecast_current') do
        location.save
        @old_forecast = location.weather_forecasts.create!(
          current_temp: 70.0,
          high_temp: 72.0,
          low_temp: 68.0,
          conditions: "Cloudy",
          cached_at: old_time
        )
        @current_forecast = location.weather_forecasts.create!(
          current_temp: 72.0,
          high_temp: 75.0,
          low_temp: 70.0,
          conditions: "Clear",
          cached_at: current_time
        )
      end
    end

    it 'returns forecasts cached within the last 30 minutes' do
      current_forecasts = WeatherForecast.current
      expect(current_forecasts).to include(@current_forecast)
      expect(current_forecasts).not_to include(@old_forecast)
    end
  end
end 
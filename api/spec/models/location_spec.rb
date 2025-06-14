require 'rails_helper'

RSpec.describe Location, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:address) }
    it { should validate_presence_of(:zip_code) }

    context 'zip_code format' do
      it 'accepts valid 5-digit ZIP codes' do
        location = build(:location, zip_code: '12345')
        expect(location).to be_valid
      end

      it 'accepts valid 9-digit ZIP codes' do
        location = build(:location, zip_code: '12345-6789')
        expect(location).to be_valid
      end

      it 'rejects invalid ZIP codes' do
        location = build(:location, zip_code: '1234')
        expect(location).not_to be_valid
        expect(location.errors[:zip_code]).to include('must be a valid 5-digit or 9-digit ZIP code')
      end
    end
  end

  describe 'associations' do
    it { should have_many(:weather_forecasts).dependent(:destroy) }
  end

  describe 'geocoding' do
    let(:location) { build(:location, address: '123 Main St, New York, NY', zip_code: '10001') }

    it 'geocodes the address', :vcr do
      location.save
      expect(location.latitude).not_to be_nil
      expect(location.longitude).not_to be_nil
    end

    it 'preserves the original zip_code if already set', :vcr do
      original_zip = '10001'
      location = build(:location, address: '123 Main St, New York, NY', zip_code: original_zip)
      location.save
      expect(location.zip_code).to eq(original_zip)
    end
  end

  describe '.find_or_create_by_zip_code' do
    let(:zip_code) { '10001' }
    let(:address) { '123 Main St, New York, NY 10001' }

    it 'finds an existing location by zip_code' do
      existing_location = create(:location, zip_code: zip_code, address: 'Different address')
      location = Location.find_or_create_by_zip_code(zip_code, address)
      expect(location).to eq(existing_location)
    end

    it 'creates a new location if zip_code not found' do
      expect {
        Location.find_or_create_by_zip_code(zip_code, address)
      }.to change(Location, :count).by(1)
    end

    it 'updates the address when creating a new location' do
      location = Location.find_or_create_by_zip_code(zip_code, address)
      expect(location.address).to eq(address)
    end
  end

  describe '.cleanup_old_locations' do
    let!(:active_location) { create(:location) }
    let!(:inactive_location) { create(:location) }

    before do
      create(:weather_forecast, location: active_location, cached_at: 29.days.ago)
      create(:weather_forecast, location: inactive_location, cached_at: 31.days.ago)
    end

    it 'removes locations without recent forecasts' do
      expect {
        Location.cleanup_old_locations
      }.to change(Location, :count).by(-1)

      expect(Location.exists?(inactive_location.id)).to be false
      expect(Location.exists?(active_location.id)).to be true
    end
  end

  describe '#current_forecast' do
    let(:location) { build(:location) }
    let(:old_time) { Time.current - 31.minutes }
    let(:current_time) { Time.current - 29.minutes }

    before do
      VCR.use_cassette('location_current_forecast') do
        location.save
        location.weather_forecasts.create!(
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

    it 'returns the most recent forecast within 30 minutes' do
      expect(location.current_forecast).to eq(@current_forecast)
    end
  end

  describe '#needs_new_forecast?' do
    let(:location) { build(:location) }

    before do
      VCR.use_cassette('location_needs_forecast') do
        location.save
      end
    end

    context 'when there is no current forecast' do
      it 'returns true' do
        expect(location.needs_new_forecast?).to be true
      end
    end

    context 'when there is a current forecast' do
      before do
        create(:weather_forecast, location: location, cached_at: 29.minutes.ago)
      end

      it 'returns false' do
        expect(location.needs_new_forecast?).to be false
      end
    end
  end
end 
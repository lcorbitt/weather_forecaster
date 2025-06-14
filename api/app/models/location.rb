class Location < ApplicationRecord
  has_many :weather_forecasts, dependent: :destroy

  validates :address, presence: true
  validates :zip_code, presence: true, format: { 
    with: /\A\d{5}(-\d{4})?\z/, 
    message: "must be a valid 5-digit or 9-digit ZIP code" 
  }
  
  geocoded_by :address do |obj, results|
    if geo = results.first
      obj.latitude = geo.latitude
      obj.longitude = geo.longitude
      # Only update zip_code if it's not already set
      obj.zip_code ||= geo.postal_code
    end
  end
  
  after_validation :geocode, if: ->(obj) { obj.address.present? && obj.address_changed? }

  def current_forecast
    weather_forecasts.where('cached_at > ?', 30.minutes.ago).order(cached_at: :desc).first
  end

  def needs_new_forecast?
    current_forecast.nil?
  end

  # Class method to find or create a location by ZIP code
  def self.find_or_create_by_zip_code(zip_code, address)
    find_or_create_by(zip_code: zip_code) do |location|
      location.address = address
    end
  end

  # Cleanup old locations that haven't been queried recently
  def self.cleanup_old_locations
    where.not(id: WeatherForecast.where('cached_at > ?', 30.days.ago).select(:location_id))
         .destroy_all
  end
end 
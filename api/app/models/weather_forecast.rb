class WeatherForecast < ApplicationRecord
  belongs_to :location

  validates :current_temp, :high_temp, :low_temp, :conditions, presence: true
  validates :cached_at, presence: true

  before_validation :set_cached_at, on: :create

  scope :current, -> { where('cached_at > ?', 30.minutes.ago).order(cached_at: :desc) }

  attr_accessor :from_cache

  def from_cache?
    @from_cache == true
  end

  private

  def set_cached_at
    self.cached_at ||= Time.current
  end
end 
FactoryBot.define do
  factory :weather_forecast do
    association :location
    current_temp { rand(0.0..100.0).round(1) }
    high_temp { current_temp + rand(1.0..10.0).round(1) }
    low_temp { current_temp - rand(1.0..10.0).round(1) }
    conditions { ['Clear', 'Cloudy', 'Rain', 'Snow', 'Thunderstorm'].sample }
    cached_at { Time.current }

    trait :cached do
      cached_at { 15.minutes.ago }
    end

    trait :stale do
      cached_at { 35.minutes.ago }
    end
  end
end

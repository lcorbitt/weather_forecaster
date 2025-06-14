FactoryBot.define do
  factory :location do
    address { '90210' }
    latitude { 34.0901 }
    longitude { -118.4065 }
    zip_code { '90210' }

    trait :with_geocoding do
      after(:build) do |location|
        location.geocode
      end
    end
  end
end

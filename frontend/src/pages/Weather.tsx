import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { AddressForm } from '../components/AddressForm';
import { WeatherDisplay } from '../components/WeatherDisplay';

interface WeatherData {
  data: {
    current_temp: string;
    high_temp: string;
    low_temp: string;
    conditions: string;
    location_address: string;
  };
  meta: {
    cached: boolean;
    cached_at: string;
    expires_at: string;
  };
}

const fetchWeather = async (address: string): Promise<WeatherData | null> => {
  if (!address) return null;

  const response = await fetch(
    `http://localhost:3001/api/v1/weather/forecast?address=${encodeURIComponent(address)}`
  );

  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(errorData.error || 'Failed to fetch weather data');
  }

  const data = await response.json();
  
  // Add a minimum delay of 300ms to make loading state more visible
  await new Promise(resolve => setTimeout(resolve, 300));
  
  return data;
};

export const Weather = () => {
  const [address, setAddress] = useState('');
  const [isRefetching, setIsRefetching] = useState(false);

  const {
    data: weather,
    isLoading: isInitialLoading,
    error,
    refetch
  } = useQuery<WeatherData | null, Error>({
    queryKey: ['weather', address],
    queryFn: () => fetchWeather(address),
    enabled: Boolean(address)
  });

  const handleAddressSubmit = async (newAddress: string) => {
    setIsRefetching(true);
    
    if (address === newAddress) {
      await refetch();
    } else {
      setAddress(newAddress);
    }
    
    setIsRefetching(false);
  };

  // Combine both loading states
  const isLoading = isInitialLoading || isRefetching;

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-md mx-auto px-4">
        <h1 className="text-3xl font-bold text-center text-gray-900 mb-8">
          Weather Forecaster
        </h1>

        <div className="bg-white rounded-lg shadow-md p-6">
          <AddressForm onSubmit={handleAddressSubmit} isLoading={isLoading} />

          {error instanceof Error && (
            <div className="mt-4 p-4 bg-red-50 text-red-700 rounded-md">
              {error.message}
            </div>
          )}

          {weather && <WeatherDisplay weather={weather} />}
        </div>
      </div>
    </div>
  );
}; 
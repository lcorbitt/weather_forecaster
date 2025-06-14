import { WeatherLoading } from './WeatherLoading';

export interface WeatherData {
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

interface WeatherDisplayProps {
  weather?: WeatherData;
  isLoading?: boolean;
}

export const WeatherDisplay = ({ weather, isLoading }: WeatherDisplayProps) => {
  if (isLoading) {
    return <WeatherLoading />;
  }

  if (!weather) {
    return null;
  }

  // Extracts city from address (format: "street, city, state zip")
  const city = weather.data.location_address.split(',')[1]?.trim() || 'Unknown City';

  return (
    <div className="mt-8 p-8 bg-white rounded-xl shadow-lg transform transition-all duration-500 hover:scale-[1.02]">
      {/* Temperature and Conditions */}
      <div className="text-center relative">
        <div className="inline-block relative">
          <div className="text-7xl font-bold bg-gradient-to-r from-blue-600 to-blue-400 bg-clip-text text-transparent">
            {weather.data.current_temp}°F
          </div>
          <div className="absolute -right-4 -top-4 bg-yellow-400 text-xs font-bold px-2 py-1 rounded-full shadow-md transform rotate-12">
            NOW
          </div>
        </div>
        <div className="mt-3 text-2xl text-gray-600 capitalize font-light">
          {weather.data.conditions}
        </div>
      </div>

      {/* High/Low Temperatures */}
      <div className="mt-8 flex justify-center space-x-12">
        <div className="text-center transform transition-transform hover:scale-110">
          <div className="text-sm font-semibold text-gray-500 uppercase tracking-wide">
            High
          </div>
          <div className="mt-1 text-3xl font-bold text-red-500">
            {weather.data.high_temp}°F
          </div>
        </div>
        <div className="text-center transform transition-transform hover:scale-110">
          <div className="text-sm font-semibold text-gray-500 uppercase tracking-wide">
            Low
          </div>
          <div className="mt-1 text-3xl font-bold text-blue-500">
            {weather.data.low_temp}°F
          </div>
        </div>
      </div>

      {/* Location */}
      <div className="mt-8 text-center">
        <div className="text-sm font-semibold text-gray-500 uppercase tracking-wide">
          Location
        </div>
        <div className="mt-1 text-lg text-gray-700 font-medium">
          {city}
        </div>
      </div>

      {/* Cache Status */}
      <div className="mt-6 text-center">
        {weather.meta.cached ? (
          <div className="inline-block bg-gray-100 rounded-lg px-4 py-2">
            <div className="text-sm font-medium text-gray-600">
              Retrieved from cache
            </div>
            <div className="mt-1 text-xs text-gray-500">
              Cached: {new Date(weather.meta.cached_at).toLocaleString()}
            </div>
            <div className="text-xs text-gray-500">
              Expires: {new Date(weather.meta.expires_at).toLocaleString()}
            </div>
          </div>
        ) : (
          <div className="inline-block bg-green-100 rounded-lg px-4 py-2">
            <div className="text-sm font-medium text-green-600">
              Fresh data
            </div>
          </div>
        )}
      </div>
    </div>
  );
}; 
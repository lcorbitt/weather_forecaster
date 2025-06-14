export const WeatherLoading = () => {
  return (
    <div className="mt-8 p-8 bg-white rounded-xl shadow-lg">
      {/* Temperature and Conditions */}
      <div className="text-center">
        <div className="inline-block relative">
          <div className="h-24 w-48 bg-gray-200 rounded-lg animate-pulse" />
        </div>
        <div className="mt-3">
          <div className="h-8 w-32 mx-auto bg-gray-200 rounded-lg animate-pulse" />
        </div>
      </div>

      {/* High/Low Temperatures */}
      <div className="mt-8 flex justify-center space-x-12">
        <div className="text-center">
          <div className="h-4 w-12 bg-gray-200 rounded animate-pulse mb-2" />
          <div className="h-8 w-20 bg-gray-200 rounded animate-pulse" />
        </div>
        <div className="text-center">
          <div className="h-4 w-12 bg-gray-200 rounded animate-pulse mb-2" />
          <div className="h-8 w-20 bg-gray-200 rounded animate-pulse" />
        </div>
      </div>

      {/* Location */}
      <div className="mt-8 text-center">
        <div className="h-4 w-20 mx-auto bg-gray-200 rounded animate-pulse mb-2" />
        <div className="h-6 w-48 mx-auto bg-gray-200 rounded animate-pulse" />
      </div>

      {/* Animated Loading Ring */}
      <div className="mt-6 flex justify-center">
        <div className="inline-flex items-center px-4 py-2 space-x-2">
          <svg className="animate-spin h-5 w-5 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <span className="text-sm font-medium text-gray-500">Fetching weather data...</span>
        </div>
      </div>
    </div>
  );
}; 
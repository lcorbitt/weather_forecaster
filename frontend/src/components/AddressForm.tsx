/// <reference types="@types/google.maps" />
import { useState, useEffect, useRef } from 'react';

interface AddressFields {
  street: string;
  city: string;
  state: string;
  zipCode: string;
}

interface AddressFormProps {
  onSubmit: (address: string) => void;
  isLoading: boolean;
}

export const AddressForm = ({ onSubmit, isLoading }: AddressFormProps) => {
  const [fields, setFields] = useState<AddressFields>({
    street: '',
    city: '',
    state: '',
    zipCode: ''
  });
  const [inputValue, setInputValue] = useState('');
  const [error, setError] = useState<string | null>(null);
  const autoCompleteRef = useRef<google.maps.places.Autocomplete | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const [fullAddress, setFullAddress] = useState('');

  useEffect(() => {
    // Load Google Places API script
    const script = document.createElement('script');
    script.src = `https://maps.googleapis.com/maps/api/js?key=${import.meta.env.VITE_GOOGLE_MAPS_API_KEY}&libraries=places`;
    script.async = true;
    script.defer = true;
    script.onload = initAutocomplete;
    document.head.appendChild(script);

    return () => {
      // Cleanup script on component unmount
      document.head.removeChild(script);
    };
  }, []);

  const initAutocomplete = () => {
    if (!inputRef.current) return;

    autoCompleteRef.current = new google.maps.places.Autocomplete(inputRef.current, {
      componentRestrictions: { country: 'us' },
      fields: ['address_components', 'formatted_address'],
    });

    autoCompleteRef.current.addListener('place_changed', handlePlaceSelect);
  };

  const handlePlaceSelect = () => {
    if (!autoCompleteRef.current) return;

    const place = autoCompleteRef.current.getPlace();
    if (!place.address_components) {
      setError('Please select an address from the dropdown');
      return;
    }

    const newFields: AddressFields = {
      street: '',
      city: '',
      state: '',
      zipCode: ''
    };

    // Extract address components
    place.address_components?.forEach((component) => {
      const types = component.types;

      if (types.includes('street_number')) {
        newFields.street = component.long_name + ' ';
      }
      if (types.includes('route')) {
        newFields.street += component.long_name;
      }
      if (types.includes('locality')) {
        newFields.city = component.long_name;
      }
      if (types.includes('administrative_area_level_1')) {
        newFields.state = component.short_name;
      }
      if (types.includes('postal_code')) {
        newFields.zipCode = component.long_name;
      }
    });

    setFields(newFields);
    setFullAddress(place.formatted_address || '');
    setInputValue(newFields.street);
    setError(null);
  };

  const handleClick = () => {
    if (!fullAddress) {
      setError('Please select a complete address from the dropdown');
      return;
    }

    onSubmit(fullAddress);
  };

  return (
    <div className="space-y-4">
      <div className="relative">
        <input
          ref={inputRef}
          type="search"
          aria-label="Adress search"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          placeholder="Start typing an address..."
          className={`
            w-full px-4 py-3 rounded-lg border
            ${error ? 'border-red-300' : 'border-gray-300'}
            focus:outline-none focus:ring-2
            ${error ? 'focus:ring-red-200' : 'focus:ring-blue-200'}
            focus:border-transparent
            transition-all duration-200
            placeholder-gray-400
            disabled:bg-gray-50 disabled:text-gray-500
          `}
          disabled={isLoading}
        />
      </div>

      <div className="w-full">
        <input
          type="text"
          value={fields.city}
          placeholder="City"
          readOnly
          className="w-full px-4 py-2 rounded-lg border border-gray-300 bg-gray-50 focus:outline-none focus:ring-0 pointer-events-none"
        />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <input
          type="text"
          value={fields.state}
          placeholder="State"
          readOnly
          className="px-4 py-2 rounded-lg border border-gray-300 bg-gray-50 focus:outline-none focus:ring-0 pointer-events-none"
        />
        <input
          type="text"
          value={fields.zipCode}
          placeholder="ZIP Code"
          readOnly
          className="px-4 py-2 rounded-lg border border-gray-300 bg-gray-50 focus:outline-none focus:ring-0 pointer-events-none"
        />
      </div>

      {error && (
        <div className="text-sm text-red-500">
          {error}
        </div>
      )}

      <button
        type="button"
        onClick={handleClick}
        disabled={isLoading}
        className={`
          w-full py-3 px-4 rounded-lg
          ${isLoading
            ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
            : 'bg-gradient-to-r from-blue-500 to-blue-600 text-white hover:from-blue-600 hover:to-blue-700'
          }
          font-medium transition-all duration-200
          focus:outline-none focus:ring-2 focus:ring-blue-200 focus:ring-offset-2
          flex items-center justify-center space-x-2
        `}
      >
        {isLoading ? (
          <>
            <svg className="animate-spin h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <span>Getting Weather...</span>
          </>
        ) : (
          <span>Get Weather</span>
        )}
      </button>
    </div>
  );
}; 
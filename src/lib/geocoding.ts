import { Client } from '@googlemaps/google-maps-services-js';

const client = new Client({});

export interface GeocodingResult {
  latitude: number;
  longitude: number;
  formattedAddress: string;
}

export async function geocodeAddress(address: string): Promise<GeocodingResult> {
  if (!process.env.GOOGLE_MAPS_API_KEY) {
    throw new Error('GOOGLE_MAPS_API_KEY environment variable is not set');
  }

  const response = await client.geocode({
    params: {
      address,
      key: process.env.GOOGLE_MAPS_API_KEY,
    },
  });

  if (response.data.results.length === 0) {
    throw new Error('Could not find that address. Please check and try again.');
  }

  const result = response.data.results[0];
  return {
    latitude: result.geometry.location.lat,
    longitude: result.geometry.location.lng,
    formattedAddress: result.formatted_address,
  };
}

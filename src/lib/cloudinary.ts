import { v2 as cloudinary } from 'cloudinary';

// Check if required environment variables are set
const requiredEnvVars = {
  CLOUDINARY_CLOUD_NAME: process.env.CLOUDINARY_CLOUD_NAME,
  CLOUDINARY_API_KEY: process.env.CLOUDINARY_API_KEY,
  CLOUDINARY_API_SECRET: process.env.CLOUDINARY_API_SECRET,
};

// Validate environment variables
const missingVars = Object.entries(requiredEnvVars)
  .filter(([key, value]) => !value || value === 'your_actual_api_secret')
  .map(([key]) => key);

if (missingVars.length > 0) {
  console.warn(`⚠️  Missing or invalid Cloudinary environment variables: ${missingVars.join(', ')}`);
  console.warn('Cloudinary service will not work properly. Please set valid credentials in .env.local');
}

// Configure Cloudinary only if all required variables are present
if (missingVars.length === 0) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
  });
  console.log('✅ Cloudinary configured successfully');
} else {
  console.error('❌ Cloudinary configuration failed due to missing environment variables');
}

export { cloudinary };

// Helper function to generate signature for direct uploads
export function generateSignature(params: Record<string, any>): string {
  // Check if Cloudinary is properly configured
  if (missingVars.length > 0) {
    throw new Error('Cloudinary not configured. Please set all required environment variables.');
  }

  // Sort parameters alphabetically
  const sortedParams = Object.keys(params)
    .sort()
    .reduce((result: Record<string, any>, key) => {
      result[key] = params[key];
      return result;
    }, {});

  // Create query string
  const queryString = Object.entries(sortedParams)
    .map(([key, value]) => `${key}=${value}`)
    .join('&');

  // Generate SHA-1 hash with api_secret
  const crypto = require('crypto');
  return crypto
    .createHash('sha1')
    .update(queryString + process.env.CLOUDINARY_API_SECRET)
    .digest('hex');
}

// Helper function to create upload parameters
export function createUploadParams(
  publicId: string,
  folder: string,
  resourceType: 'image' | 'video' = 'image'
) {
  // Check if Cloudinary is properly configured
  if (missingVars.length > 0) {
    throw new Error('Cloudinary not configured. Please set all required environment variables.');
  }

  const timestamp = Math.round(new Date().getTime() / 1000);
  
  const params = {
    timestamp,
    folder,
    public_id: publicId,
    resource_type: resourceType,
    overwrite: true,
  };

  const signature = generateSignature(params);

  return {
    ...params,
    signature,
    api_key: process.env.CLOUDINARY_API_KEY,
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  };
}

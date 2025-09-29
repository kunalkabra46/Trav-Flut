import { NextRequest, NextResponse } from 'next/server'
import { ok, badRequest, serverError } from '@/lib/response-helpers'
import { prisma } from '@/lib/db'
import { z } from 'zod'
import crypto from 'crypto'

// Validation schema for signature request
const signatureSchema = z.object({
  tripId: z.string().uuid(),
  resourceType: z.enum(['image', 'video']).default('image'),
  filename: z.string().min(1).max(255)
})

// Generate Cloudinary signature
function generateSignature(params: Record<string, any>): string {
  // Create a copy of params without api_key and cloud_name (they're not included in signature)
  const signatureParams = { ...params };
  delete signatureParams.api_key;
  delete signatureParams.cloud_name;
  
  // Sort parameters alphabetically
  const sortedParams = Object.keys(signatureParams)
    .sort()
    .reduce((result: Record<string, any>, key) => {
      result[key] = signatureParams[key];
      return result;
    }, {});

  // Create query string
  const queryString = Object.entries(sortedParams)
    .map(([key, value]) => `${key}=${value}`)
    .join('&');

  console.log('[SIGNATURE] Parameters for signature:', sortedParams);
  console.log('[SIGNATURE] Query string:', queryString);
  console.log('[SIGNATURE] Resource type in signature params:', signatureParams.resource_type);

  // Generate SHA-1 hash with api_secret
  const apiSecret = process.env.CLOUDINARY_API_SECRET;
  if (!apiSecret || apiSecret === 'your_actual_api_secret') {
    throw new Error('CLOUDINARY_API_SECRET not configured');
  }

  const signature = crypto
    .createHash('sha1')
    .update(queryString + apiSecret)
    .digest('hex');

  console.log('[SIGNATURE] Generated signature:', signature);
  return signature;
}

export async function POST(request: NextRequest) {
  try {
    console.log('[MEDIA] Received signature request')
    
    const body = await request.json()
    console.log('[MEDIA] Request body:', body)
    
    const validatedData = signatureSchema.parse(body)
    const { tripId, resourceType, filename } = validatedData
    console.log('[MEDIA] Validated data:', { tripId, resourceType, filename })

    // TEMPORARY: Skip authentication and database check for testing
    // TODO: Re-enable authentication and database validation once setup is complete
    const userId = 'test-user-id' // This should come from auth middleware

    // TEMPORARY: Skip database validation for testing
    // TODO: Re-enable this once database is properly set up
    console.log('[MEDIA] Skipping database validation for testing')

    // Generate unique public ID for the media
    const timestamp = Math.round(Date.now() / 1000)
    const publicId = `tripthread/${tripId}/${timestamp}_${filename.replace(/\.[^/.]+$/, '')}`
    const folder = `tripthread/${tripId}`

    // Check if we have Cloudinary credentials
    const cloudName = process.env.CLOUDINARY_CLOUD_NAME
    const apiKey = process.env.CLOUDINARY_API_KEY
    const apiSecret = process.env.CLOUDINARY_API_SECRET

    if (!cloudName || !apiKey || !apiSecret || apiSecret === 'your_actual_api_secret') {
      console.log('[MEDIA] Cloudinary credentials not configured, returning mock response')
      
      // Return mock response for testing
      const mockUploadParams = {
        timestamp,
        folder,
        public_id: publicId,
        resource_type: resourceType,
        api_key: 'test_key',
        cloud_name: 'test_cloud',
        upload_preset: 'test_preset',
        transformation: 'f_auto,q_auto',
      }

      return ok({
        uploadParams: mockUploadParams,
        publicId,
        folder,
        resourceType,
        message: 'Test mode - Cloudinary not configured, using mock parameters'
      })
    }

    // Try signed uploads first, fallback to unsigned if there are issues
    try {
      console.log('[MEDIA] Attempting signed uploads with Cloudinary')
      
      // Generate signature using only the parameters that should be signed
      // NOTE: Cloudinary expects resource_type to match the URL path (/auto/upload)
      const signatureParams = {
        timestamp,
        public_id: publicId,
        folder,
        resource_type: 'auto', // Use 'auto' to match the URL path
        overwrite: true,
      };
      
      console.log('[MEDIA] Signature parameters before generation:', signatureParams);
      
      const signature = generateSignature(signatureParams)
      
      // Return ONLY the parameters that should be sent to Cloudinary
      // This ensures the client sends exactly what the signature was generated for
      const clientUploadParams = {
        timestamp,
        public_id: publicId,
        folder,
        resource_type: 'auto', // Use 'auto' to match the URL path
        overwrite: true,
        api_key: apiKey,
        cloud_name: cloudName,
        signature, // Add the signature
      }

      console.log(`[MEDIA] Generated signed upload params for trip ${tripId}, user ${userId}`)
      console.log(`[MEDIA] Parameters used for signature:`, signatureParams)
      console.log(`[MEDIA] Client upload params:`, clientUploadParams)
      console.log(`[MEDIA] Generated signature:`, signature)

      return ok({
        uploadParams: clientUploadParams,
        publicId,
        folder,
        resourceType,
        message: 'Signed upload parameters generated successfully'
      })
      
    } catch (signatureError) {
      console.log('[MEDIA] Signed upload failed, falling back to unsigned upload:', signatureError)
      
      // Fallback to unsigned upload with default preset
      const unsignedUploadParams = {
        timestamp,
        folder,
        public_id: publicId,
        resource_type: 'auto', // Use 'auto' to match the URL path
        api_key: apiKey,
        cloud_name: cloudName,
        upload_preset: 'ml_default', // Try default preset
        transformation: 'f_auto,q_auto',
      }

      console.log(`[MEDIA] Using unsigned upload fallback for trip ${tripId}, user ${userId}`)

      return ok({
        uploadParams: unsignedUploadParams,
        publicId,
        folder,
        resourceType,
        message: 'Using unsigned upload fallback (ml_default preset)'
      })
    }

  } catch (error: any) {
    console.error('[MEDIA] Error in signature endpoint:', error)
    
    if (error.name === 'ZodError') {
      return badRequest('Invalid request data', error.errors)
    }
    
    return serverError('Failed to generate upload signature')
  }
}

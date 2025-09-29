import { NextRequest, NextResponse } from 'next/server'
import { ok, badRequest, serverError } from '@/lib/response-helpers'
import { z } from 'zod'

// Validation schema for signature request
const signatureSchema = z.object({
  tripId: z.string().uuid(),
  resourceType: z.enum(['image', 'video']).default('image'),
  filename: z.string().min(1).max(255)
})

export async function POST(request: NextRequest) {
  try {
    console.log('[SIMPLE] Received upload request')
    
    const body = await request.json()
    console.log('[SIMPLE] Request body:', body)
    
    const validatedData = signatureSchema.parse(body)
    const { tripId, resourceType, filename } = validatedData
    console.log('[SIMPLE] Validated data:', { tripId, resourceType, filename })

    // Generate unique public ID for the media
    const timestamp = Math.round(Date.now() / 1000)
    const publicId = `tripthread/${tripId}/${timestamp}_${filename.replace(/\.[^/.]+$/, '')}`
    const folder = `tripthread/${tripId}`

    // Get Cloudinary credentials
    const cloudName = process.env.CLOUDINARY_CLOUD_NAME
    const apiKey = process.env.CLOUDINARY_API_KEY

    if (!cloudName || !apiKey) {
      console.log('[SIMPLE] Cloudinary credentials missing, returning mock response')
      
      const mockUploadParams = {
        timestamp,
        folder,
        public_id: publicId,
        resource_type: resourceType,
        api_key: 'test_key',
        cloud_name: 'test_cloud',
        upload_preset: 'test_preset',
      }

      return ok({
        uploadParams: mockUploadParams,
        publicId,
        folder,
        resourceType,
        message: 'Test mode - Mock parameters'
      })
    }

    // Use the simplest possible upload parameters
    console.log('[SIMPLE] Using simple upload parameters')
    
    // Try different preset names that commonly exist
    const presetOptions = ['ml_default', 'tripthread_uploads', 'default', 'public'];
    const uploadParams = {
      timestamp,
      folder,
      public_id: publicId,
      resource_type: resourceType,
      api_key: apiKey,
      cloud_name: cloudName,
      upload_preset: presetOptions[0], // Use first preset for now
    };
    
    console.log(`[SIMPLE] Using preset: ${uploadParams.upload_preset}`);

    console.log(`[SIMPLE] Generated simple upload params for trip ${tripId}`)

    return ok({
      uploadParams,
      publicId,
      folder,
      resourceType,
      message: `Simple upload parameters generated (${uploadParams.upload_preset} preset)`
    })

  } catch (error: any) {
    console.error('[SIMPLE] Error in simple upload endpoint:', error)
    
    if (error.name === 'ZodError') {
      return badRequest('Invalid request data', error.errors)
    }
    
    return serverError('Failed to generate upload parameters')
  }
}

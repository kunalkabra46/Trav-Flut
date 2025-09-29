import { NextRequest } from 'next/server'
import { withAuth, withRateLimit, withLogging } from '@/lib/middleware'
import { ok, badRequest, serverError, notFound } from '@/lib/response-helpers'
import { prisma } from '@/lib/db'
import { z } from 'zod'

// Validation schema for media confirmation
const confirmSchema = z.object({
  tripId: z.string().uuid(),
  url: z.string().url(),
  type: z.enum(['IMAGE', 'VIDEO']),
  filename: z.string().min(1).max(255),
  size: z.number().positive().optional(),
})

export async function POST(request: NextRequest) {
  try {
    console.log('[MEDIA] Received confirmation request')
    
    const body = await request.json()
    console.log('[MEDIA] Request body:', body)
    
    const validatedData = confirmSchema.parse(body)
    const { tripId, url, type, filename, size } = validatedData
    console.log('[MEDIA] Validated data:', { tripId, url, type, filename, size })

    // TEMPORARY: Skip authentication and database check for testing
    // TODO: Re-enable authentication and database validation once setup is complete
    const userId = 'test-user-id' // This should come from auth middleware

    // TEMPORARY: Skip database validation for testing
    // TODO: Re-enable this once database is properly set up
    /*
    // Verify user has access to the trip (owner or participant)
    const trip = await prisma.trip.findFirst({
      where: {
        id: tripId,
        OR: [
          { userId: userId },
          { participants: { some: { userId } } }
        ]
      },
      select: { id: true, title: true }
    })

    if (!trip) {
      console.log('[MEDIA] Trip not found or access denied for tripId:', tripId)
      return badRequest('Trip not found or access denied')
    }

    console.log('[MEDIA] Trip found:', trip)
    */

    console.log('[MEDIA] Skipping database validation for testing')

    // TEMPORARY: Return mock media record for testing
    // TODO: Replace with real database creation once setup is complete
    const mockMedia = {
      id: `mock-media-${Date.now()}`,
      tripId,
      type,
      url,
      filename,
      size,
      uploadedById: userId,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    }

    console.log(`[MEDIA] Created mock media record for trip ${tripId}, user ${userId}`)

    return ok({
      media: mockMedia,
      message: 'Test mode - Using mock media record (database validation skipped)'
    })

  } catch (error: any) {
    console.error('[MEDIA] Error in confirmation endpoint:', error)
    
    if (error.name === 'ZodError') {
      return badRequest('Invalid request data', error.errors)
    }
    
    return serverError('Failed to confirm media upload')
  }
}

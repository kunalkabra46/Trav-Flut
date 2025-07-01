import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { createTripSchema } from '@/lib/validation'
import { ApiResponse, TripResponse } from '@/types/api'
import { withAuth, withRateLimit, withLogging, handleApiError } from '@/lib/middleware'
import { PerformanceMonitor, ErrorTracker } from '@/lib/monitoring'
import { NotFoundError, ConflictError, ValidationError } from '@/lib/errors'

// Create a new trip
export async function POST(request: NextRequest) {
  return withLogging(
    withRateLimit(
      withAuth(async (req) => {
        const endTimer = PerformanceMonitor.getInstance().startTimer('create_trip')
        
        try {
          const body = await req.json()
          const validatedData = createTripSchema.parse(body)
          const userId = req.user!.userId

          // Check if user has an ongoing trip
          const ongoingTrip = await prisma.trip.findFirst({
            where: {
              userId,
              status: 'ONGOING'
            }
          })

          if (ongoingTrip) {
            throw new ConflictError('You already have an ongoing trip. Please end it before starting a new one.')
          }

          // Create trip with transaction for data consistency
          const trip = await prisma.$transaction(async (tx) => {
            const newTrip = await tx.trip.create({
              data: {
                ...validatedData,
                userId,
                startDate: validatedData.startDate ? new Date(validatedData.startDate) : null,
                endDate: validatedData.endDate ? new Date(validatedData.endDate) : null,
                status: 'ONGOING'
              },
              include: {
                user: {
                  select: {
                    id: true,
                    email: true,
                    username: true,
                    name: true,
                    avatarUrl: true,
                    bio: true,
                    isPrivate: true,
                    createdAt: true,
                    updatedAt: true
                  }
                },
                _count: {
                  select: {
                    threadEntries: true,
                    media: true,
                    participants: true
                  }
                }
              }
            })

            // Log trip creation for analytics
            console.log(`Trip created: ${newTrip.id} by user ${userId}`)
            
            return newTrip
          })

          const tripResponse: TripResponse = {
            ...trip,
            startDate: trip.startDate?.toISOString() || undefined,
            endDate: trip.endDate?.toISOString() || undefined,
            createdAt: trip.createdAt.toISOString(),
            updatedAt: trip.updatedAt.toISOString(),
            user: trip.user ? {
              ...trip.user,
              createdAt: trip.user.createdAt.toISOString(),
              updatedAt: trip.user.updatedAt.toISOString()
            } : undefined
          }

          return NextResponse.json<ApiResponse<TripResponse>>({
            success: true,
            data: tripResponse
          }, { status: 201 })

        } catch (error: any) {
          ErrorTracker.getInstance().trackError(error, { operation: 'create_trip' }, req.user?.userId)
          
          if (error.name === 'ZodError') {
            throw new ValidationError(error.errors[0]?.message || 'Validation error')
          }
          
          throw error
        } finally {
          endTimer()
        }
      }),
      { maxRequests: 10, windowMs: 60000 } // 10 trips per minute max
    )
  )(request)
}

// Get user's trips
export async function GET(request: NextRequest) {
  return withLogging(
    withRateLimit(
      withAuth(async (req) => {
        const endTimer = PerformanceMonitor.getInstance().startTimer('get_trips')
        
        try {
          const userId = req.user!.userId
          const { searchParams } = new URL(req.url)
          const status = searchParams.get('status') as 'UPCOMING' | 'ONGOING' | 'ENDED' | null

          const whereClause: any = { userId }
          if (status) {
            whereClause.status = status
          }

          const trips = await prisma.trip.findMany({
            where: whereClause,
            include: {
              user: {
                select: {
                  id: true,
                  email: true,
                  username: true,
                  name: true,
                  avatarUrl: true,
                  bio: true,
                  isPrivate: true,
                  createdAt: true,
                  updatedAt: true
                }
              },
              _count: {
                select: {
                  threadEntries: true,
                  media: true,
                  participants: true
                }
              }
            },
            orderBy: { createdAt: 'desc' },
            take: 50 // Limit results for performance
          })

          const tripsResponse: TripResponse[] = trips.map(trip => ({
            ...trip,
            startDate: trip.startDate?.toISOString() || undefined,
            endDate: trip.endDate?.toISOString() || undefined,
            createdAt: trip.createdAt.toISOString(),
            updatedAt: trip.updatedAt.toISOString(),
            user: trip.user ? {
              ...trip.user,
              createdAt: trip.user.createdAt.toISOString(),
              updatedAt: trip.user.updatedAt.toISOString()
            } : undefined
          }))

          return NextResponse.json<ApiResponse<TripResponse[]>>({
            success: true,
            data: tripsResponse
          })

        } catch (error: any) {
          ErrorTracker.getInstance().trackError(error, { operation: 'get_trips' }, req.user?.userId)
          throw error
        } finally {
          endTimer()
        }
      })
    )
  )(request)
}
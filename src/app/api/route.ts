import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  return NextResponse.json({
    message: 'TripThread API',
    version: '1.0.0',
    status: 'running',
    timestamp: new Date().toISOString(),
    endpoints: {
      health: '/api/health',
      auth: '/api/auth',
      users: '/api/users',
      trips: '/api/trips',
      feed: '/api/feed',
      discover: '/api/discover',
      follow: '/api/follow'
    }
  })
}

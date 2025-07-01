import { NextRequest, NextResponse } from 'next/server'
import { AuthService } from '@/lib/auth'
import { ApiResponse } from '@/types/api'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { refreshToken } = body

    if (refreshToken) {
      // Revoke refresh token
      await AuthService.revokeRefreshToken(refreshToken)
    }

    const response: ApiResponse = {
      success: true,
      message: 'Logged out successfully'
    }

    return NextResponse.json(response)

  } catch (error: any) {
    console.error('Logout error:', error)
    
    return NextResponse.json<ApiResponse>({
      success: false,
      error: 'Internal server error'
    }, { status: 500 })
  }
}
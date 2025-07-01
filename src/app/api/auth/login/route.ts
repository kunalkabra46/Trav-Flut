import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { AuthService } from '@/lib/auth'
import { loginSchema } from '@/lib/validation'
import { ApiResponse, AuthResponse } from '@/types/api'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    
    // Validate input
    const validatedData = loginSchema.parse(body)
    const { email, password } = validatedData

    // Find user
    const user = await prisma.user.findUnique({
      where: { email: email.toLowerCase() }
    })

    if (!user || !user.password) {
      return NextResponse.json<ApiResponse>({
        success: false,
        error: 'Invalid email or password'
      }, { status: 401 })
    }

    // Verify password
    const isValidPassword = await AuthService.comparePassword(password, user.password)

    if (!isValidPassword) {
      return NextResponse.json<ApiResponse>({
        success: false,
        error: 'Invalid email or password'
      }, { status: 401 })
    }

    // Generate tokens
    const accessToken = AuthService.generateAccessToken(user)
    const refreshToken = AuthService.generateRefreshToken(user)

    // Store refresh token
    await AuthService.storeRefreshToken(user.id, refreshToken)

    // Remove password from response
    const { password: _, ...userWithoutPassword } = user

    const response: ApiResponse<AuthResponse> = {
      success: true,
      data: {
        user: {
          ...userWithoutPassword,
          createdAt: user.createdAt.toISOString(),
          updatedAt: user.updatedAt.toISOString()
        },
        accessToken,
        refreshToken
      }
    }

    return NextResponse.json(response)

  } catch (error: any) {
    console.error('Login error:', error)
    
    if (error.name === 'ZodError') {
      return NextResponse.json<ApiResponse>({
        success: false,
        error: error.errors[0]?.message || 'Validation error'
      }, { status: 400 })
    }

    return NextResponse.json<ApiResponse>({
      success: false,
      error: 'Internal server error'
    }, { status: 500 })
  }
}
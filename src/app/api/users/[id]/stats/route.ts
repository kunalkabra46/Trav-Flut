import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { ApiResponse, UserStats } from '@/types/api'

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const userId = params.id

    // Get follower count
    const followerCount = await prisma.follow.count({
      where: { followeeId: userId }
    })

    // Get following count
    const followingCount = await prisma.follow.count({
      where: { followerId: userId }
    })

    const stats: UserStats = {
      tripCount: 0, // Will be implemented in Trip module
      followerCount,
      followingCount
    }

    return NextResponse.json<ApiResponse<UserStats>>({
      success: true,
      data: stats
    })

  } catch (error: any) {
    console.error('Get user stats error:', error)
    
    return NextResponse.json<ApiResponse>({
      success: false,
      error: 'Internal server error'
    }, { status: 500 })
  }
}
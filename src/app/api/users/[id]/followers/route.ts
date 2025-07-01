import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { ApiResponse, UserProfile } from '@/types/api'

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const userId = params.id
    const { searchParams } = new URL(request.url)
    const page = parseInt(searchParams.get('page') || '1')
    const limit = parseInt(searchParams.get('limit') || '20')
    const offset = (page - 1) * limit

    // Get followers
    const follows = await prisma.follow.findMany({
      where: { followeeId: userId },
      include: {
        follower: {
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
        }
      },
      skip: offset,
      take: limit,
      orderBy: { createdAt: 'desc' }
    })

    // Get total count
    const totalCount = await prisma.follow.count({
      where: { followeeId: userId }
    })

    const followers: UserProfile[] = follows.map(follow => ({
      ...follow.follower,
      createdAt: follow.follower.createdAt.toISOString(),
      updatedAt: follow.follower.updatedAt.toISOString()
    }))

    return NextResponse.json<ApiResponse<{
      followers: UserProfile[]
      pagination: {
        page: number
        limit: number
        total: number
        totalPages: number
      }
    }>>({
      success: true,
      data: {
        followers,
        pagination: {
          page,
          limit,
          total: totalCount,
          totalPages: Math.ceil(totalCount / limit)
        }
      }
    })

  } catch (error: any) {
    console.error('Get followers error:', error)
    
    return NextResponse.json<ApiResponse>({
      success: false,
      error: 'Internal server error'
    }, { status: 500 })
  }
}
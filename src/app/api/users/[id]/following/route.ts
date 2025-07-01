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

    // Get following
    const follows = await prisma.follow.findMany({
      where: { followerId: userId },
      include: {
        followee: {
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
      where: { followerId: userId }
    })

    const following: UserProfile[] = follows.map(follow => ({
      ...follow.followee,
      createdAt: follow.followee.createdAt.toISOString(),
      updatedAt: follow.followee.updatedAt.toISOString()
    }))

    return NextResponse.json<ApiResponse<{
      following: UserProfile[]
      pagination: {
        page: number
        limit: number
        total: number
        totalPages: number
      }
    }>>({
      success: true,
      data: {
        following,
        pagination: {
          page,
          limit,
          total: totalCount,
          totalPages: Math.ceil(totalCount / limit)
        }
      }
    })

  } catch (error: any) {
    console.error('Get following error:', error)
    
    return NextResponse.json<ApiResponse>({
      success: false,
      error: 'Internal server error'
    }, { status: 500 })
  }
}
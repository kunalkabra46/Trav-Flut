import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { AuthService } from "@/lib/auth";
import { ApiResponse } from "@/types/api";

export interface DiscoverUserDto {
  id: string;
  username?: string;
  name?: string;
  avatarUrl?: string;
  bio?: string;
  isPrivate: boolean;
  isFollowing: boolean;
  isFollowedBy: boolean;
}

export interface PaginatedResponse<T> {
  items: T[];
  page: number;
  limit: number;
  total: number;
  hasNext: boolean;
}

export async function GET(request: NextRequest) {
  try {
    // Verify authentication
    const authHeader = request.headers.get("authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return NextResponse.json<ApiResponse>(
        {
          success: false,
          error: "Authorization token required",
        },
        { status: 401 }
      );
    }

    const token = authHeader.substring(7);
    const payload = AuthService.verifyAccessToken(token);

    if (!payload) {
      return NextResponse.json<ApiResponse>(
        {
          success: false,
          error: "Invalid token",
        },
        { status: 401 }
      );
    }

    const currentUserId = payload.userId;

    // Parse query parameters
    const searchParams = request.nextUrl.searchParams;
    const search = searchParams.get("search")?.trim();
    const page = parseInt(searchParams.get("page") || "1");
    const limit = Math.min(parseInt(searchParams.get("limit") || "20"), 50);

    // Validate parameters
    if (page < 1) {
      return NextResponse.json<ApiResponse>(
        {
          success: false,
          error: "Page must be greater than 0",
        },
        { status: 400 }
      );
    }

    if (limit < 1 || limit > 50) {
      return NextResponse.json<ApiResponse>(
        {
          success: false,
          error: "Limit must be between 1 and 50",
        },
        { status: 400 }
      );
    }

    if (search && search.length < 1) {
      return NextResponse.json<ApiResponse>(
        {
          success: false,
          error: "Search query must be at least 1 character",
        },
        { status: 400 }
      );
    }

    const offset = (page - 1) * limit;

    // Build where clause
    const whereClause: any = {
      id: { not: currentUserId }, // Exclude current user
    };

    if (search) {
      whereClause.OR = [
        { username: { contains: search, mode: "insensitive" } },
        { name: { contains: search, mode: "insensitive" } },
      ];
    }

    // Get total count
    const total = await prisma.user.count({ where: whereClause });

    // Get users with follow status
    const users = await prisma.user.findMany({
      where: whereClause,
      select: {
        id: true,
        username: true,
        name: true,
        avatarUrl: true,
        bio: true,
        isPrivate: true,
        createdAt: true,
        // Check if current user follows this user
        followers: {
          where: { followerId: currentUserId },
          select: { id: true },
        },
        // Check if this user follows current user
        following: {
          where: { followeeId: currentUserId },
          select: { id: true },
        },
      },
      orderBy: { createdAt: "desc" },
      skip: offset,
      take: limit,
    });

    // Transform to DTO
    const discoverUsers: DiscoverUserDto[] = users.map((user) => ({
      id: user.id,
      username: user.username || undefined,
      name: user.name || undefined,
      avatarUrl: user.avatarUrl || undefined,
      bio: user.bio || undefined,
      isPrivate: user.isPrivate,
      isFollowing: user.followers.length > 0,
      isFollowedBy: user.following.length > 0,
    }));

    const hasNext = offset + limit < total;

    const response: PaginatedResponse<DiscoverUserDto> = {
      items: discoverUsers,
      page,
      limit,
      total,
      hasNext,
    };

    return NextResponse.json<ApiResponse<PaginatedResponse<DiscoverUserDto>>>({
      success: true,
      data: response,
    });
  } catch (error: any) {
    console.error("Discover users error:", error);

    return NextResponse.json<ApiResponse>(
      {
        success: false,
        error: "Internal server error",
      },
      { status: 500 }
    );
  }
}

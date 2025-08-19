import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { AuthService } from "@/lib/auth";
import { ApiResponse, FollowResponse, FollowStatusResponse } from "@/types/api";

export async function GET(
  request: NextRequest,
  { params }: { params: { userId: string } }
) {
  try {
    const followeeId = params.userId;

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

    const followerId = payload.userId;

    // Check if following (accepted follow relationship)
    const existingFollow = await prisma.follow.findUnique({
      where: {
        followerId_followeeId: {
          followerId,
          followeeId,
        },
      },
    });

    // Check if there's a pending follow request
    const pendingRequest = await prisma.followRequest.findFirst({
      where: {
        followerId,
        followingId: followeeId,
        status: "PENDING",
      },
    });

    const followStatus: FollowStatusResponse = {
      isFollowing: !!existingFollow,
      isRequestPending: !!pendingRequest,
      requestId: pendingRequest?.id,
    };

    return NextResponse.json<ApiResponse<FollowStatusResponse>>({
      success: true,
      data: followStatus,
    });
  } catch (error: any) {
    console.error("Check follow status error:", error);

    return NextResponse.json<ApiResponse>(
      {
        success: false,
        error: "Internal server error",
      },
      { status: 500 }
    );
  }
}

// Follow a user
export async function POST(
  request: NextRequest,
  { params }: { params: { userId: string } }
) {
  try {
    const followeeId = params.userId;

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

    const followerId = payload.userId;

    // Prevent self-follow
    if (followerId === followeeId) {
      return NextResponse.json<ApiResponse>(
        {
          success: false,
          error: "You cannot follow yourself",
        },
        { status: 400 }
      );
    }

    // Check if followee exists
    const followee = await prisma.user.findUnique({
      where: { id: followeeId },
      select: { id: true, isPrivate: true },
    });

    if (!followee) {
      return NextResponse.json<ApiResponse>(
        {
          success: false,
          error: "User not found",
        },
        { status: 404 }
      );
    }

    // Check if already following or has pending request
    const existingFollow = await prisma.follow.findUnique({
      where: {
        followerId_followeeId: {
          followerId,
          followeeId,
        },
      },
    });

    if (existingFollow) {
      // Idempotent success - already following
      return NextResponse.json<ApiResponse>(
        {
          success: true,
          message: "Already following this user",
        },
        { status: 200 }
      );
    }

    const existingRequest = await prisma.followRequest.findFirst({
      where: {
        followerId,
        followingId: followeeId,
        status: "PENDING",
      },
    });

    if (existingRequest) {
      return NextResponse.json<ApiResponse>(
        {
          success: true,
          message: "Follow request already sent",
        },
        { status: 200 }
      );
    }

    // If followee is private, create a follow request
    if (followee.isPrivate) {
      const followRequest = await prisma.followRequest.create({
        data: {
          followerId,
          followingId: followeeId,
          status: "PENDING",
        },
      });

      return NextResponse.json<ApiResponse>(
        {
          success: true,
          message: "Follow request sent successfully",
        },
        { status: 201 }
      );
    }

    // If followee is public, create direct follow relationship
    const follow = await prisma.follow.create({
      data: {
        followerId,
        followeeId,
      },
    });

    const followResponse: FollowResponse = {
      id: follow.id,
      followerId: follow.followerId,
      followeeId: follow.followeeId,
      createdAt: follow.createdAt.toISOString(),
    };

    return NextResponse.json<ApiResponse<FollowResponse>>(
      {
        success: true,
        data: followResponse,
      },
      { status: 201 }
    );
  } catch (error: any) {
    console.error("Follow user error:", error);

    return NextResponse.json<ApiResponse>(
      {
        success: false,
        error: "Internal server error",
      },
      { status: 500 }
    );
  }
}

// Unfollow a user
export async function DELETE(
  request: NextRequest,
  { params }: { params: { userId: string } }
) {
  try {
    const followeeId = params.userId;

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

    const followerId = payload.userId;

    // Delete follow relationship
    const deletedFollow = await prisma.follow.deleteMany({
      where: {
        followerId,
        followeeId,
      },
    });

    if (deletedFollow.count === 0) {
      // Idempotent success - already not following
      return NextResponse.json<ApiResponse>(
        {
          success: true,
          message: "Already not following this user",
        },
        { status: 200 }
      );
    }

    return NextResponse.json<ApiResponse>({
      success: true,
      message: "Successfully unfollowed user",
    });
  } catch (error: any) {
    console.error("Unfollow user error:", error);

    return NextResponse.json<ApiResponse>(
      {
        success: false,
        error: "Internal server error",
      },
      { status: 500 }
    );
  }
}

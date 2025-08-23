import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { AuthService } from "@/lib/auth";
import { ApiResponse, FollowRequestDto } from "@/types/api";
import { withAuth, withRateLimit, withLogging } from "@/lib/middleware";

// Get pending follow requests for current user
export async function GET(request: NextRequest) {
  return withLogging(async (req) => {
    return withRateLimit(req, async (rateLimitedReq) => {
      return withAuth(rateLimitedReq, async (authenticatedReq) => {
        try {
          const currentUserId = authenticatedReq.user!.userId;

          // Get pending follow requests where current user is the target
          const pendingRequests = await prisma.followRequest.findMany({
            where: {
              followingId: currentUserId,
              status: "PENDING",
            },
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
                  updatedAt: true,
                },
              },
            },
            orderBy: { createdAt: "desc" },
          });

          const requestsResponse: FollowRequestDto[] = pendingRequests.map(
            (request) => ({
              id: request.id,
              followerId: request.followerId,
              followingId: request.followingId,
              status: request.status,
              createdAt: request.createdAt.toISOString(),
              updatedAt: request.updatedAt.toISOString(),
              follower: {
                ...request.follower,
                username: request.follower.username ?? undefined,
                name: request.follower.name ?? undefined,
                avatarUrl: request.follower.avatarUrl ?? undefined,
                bio: request.follower.bio ?? undefined,
                createdAt: request.follower.createdAt.toISOString(),
                updatedAt: request.follower.updatedAt.toISOString(),
              },
            })
          );

          return NextResponse.json<ApiResponse<FollowRequestDto[]>>({
            success: true,
            data: requestsResponse,
          });
        } catch (error: any) {
          console.error("Get pending follow requests error:", error);

          return NextResponse.json<ApiResponse>(
            {
              success: false,
              error: "Internal server error",
            },
            { status: 500 }
          );
        }
      });
    });
  })(request);
}

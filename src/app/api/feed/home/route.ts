import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { AuthService } from "@/lib/auth";
import { paginationSchema } from "@/lib/validation";
import {
  ApiResponse,
  TripFinalPostResponse,
  PaginatedResponse,
} from "@/types/api";
import {
  withAuth,
  withRateLimit,
  withLogging,
  handleApiError,
} from "@/lib/middleware";
import { PerformanceMonitor, ErrorTracker } from "@/lib/monitoring";

// Get home feed (final posts from followed users and public profiles)
export async function GET(request: NextRequest) {
  return withLogging(async (req) => {
    return withRateLimit(req, async (rateLimitedReq) => {
      return withAuth(rateLimitedReq, async (authenticatedReq) => {
        const endTimer =
          PerformanceMonitor.getInstance().startTimer("get_home_feed");

        try {
          const currentUserId = authenticatedReq.user!.userId;
          const { searchParams } = new URL(authenticatedReq.url);

          // Validate pagination parameters
          const paginationData = paginationSchema.parse({
            page: searchParams.get("page") || "1",
            limit: searchParams.get("limit") || "20",
          });

          const { page, limit } = paginationData;
          const offset = (page - 1) * limit;

          // Get list of users that current user is following
          const followedUsers = await prisma.follow.findMany({
            where: { followerId: currentUserId },
            select: { followeeId: true },
          });

          const followedUserIds = followedUsers.map((f) => f.followeeId);

          // Build where clause for final posts
          const whereClause: any = {
            isPublished: true,
            OR: [
              // Posts from followed users
              ...(followedUserIds.length > 0
                ? [
                    {
                      trip: {
                        userId: { in: followedUserIds },
                      },
                    },
                  ]
                : []),
              // Posts from public users (not private)
              {
                trip: {
                  user: {
                    isPrivate: false,
                  },
                },
              },
            ],
          };

          // Get total count for pagination
          const totalCount = await prisma.tripFinalPost.count({
            where: whereClause,
          });

          // Get final posts with trip and user details
          const finalPosts = await prisma.tripFinalPost.findMany({
            where: whereClause,
            include: {
              trip: {
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
                      updatedAt: true,
                    },
                  },
                  _count: {
                    select: {
                      threadEntries: true,
                      media: true,
                      participants: true,
                    },
                  },
                },
              },
            },
            orderBy: [{ createdAt: "desc" }, { trip: { updatedAt: "desc" } }],
            skip: offset,
            take: limit,
          });

          // Transform to response format
          const finalPostsResponse: TripFinalPostResponse[] = finalPosts.map(
            (post) => ({
              id: post.id,
              tripId: post.tripId,
              summaryText: post.summaryText,
              curatedMedia: post.curatedMedia,
              caption: post.caption ?? undefined,
              isPublished: post.isPublished,
              createdAt: post.createdAt.toISOString(),
              trip: {
                ...post.trip,
                startDate: post.trip.startDate?.toISOString() || undefined,
                endDate: post.trip.endDate?.toISOString() || undefined,
                description: post.trip.description ?? undefined,
                mood: post.trip.mood ?? undefined,
                type: post.trip.type ?? undefined,
                coverMediaUrl: post.trip.coverMediaUrl ?? undefined,
                createdAt: post.trip.createdAt.toISOString(),
                updatedAt: post.trip.updatedAt.toISOString(),
                user: post.trip.user
                  ? {
                      ...post.trip.user,
                      username: post.trip.user.username ?? undefined,
                      name: post.trip.user.name ?? undefined,
                      avatarUrl: post.trip.user.avatarUrl ?? undefined,
                      bio: post.trip.user.bio ?? undefined,
                      createdAt: post.trip.user.createdAt.toISOString(),
                      updatedAt: post.trip.user.updatedAt.toISOString(),
                    }
                  : undefined,
              },
            })
          );

          const hasNext = offset + limit < totalCount;

          const response: PaginatedResponse<TripFinalPostResponse> = {
            items: finalPostsResponse,
            page,
            limit,
            total: totalCount,
            hasNext,
          };

          return NextResponse.json<
            ApiResponse<PaginatedResponse<TripFinalPostResponse>>
          >({
            success: true,
            data: response,
          });
        } catch (error: any) {
          ErrorTracker.getInstance().trackError(
            error,
            { operation: "get_home_feed" },
            authenticatedReq.user?.userId
          );
          throw error;
        } finally {
          endTimer();
        }
      });
    });
  })(request);
}

/*
  Warnings:

  - You are about to drop the `followRequests` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "followRequests" DROP CONSTRAINT "followRequests_followeeId_fkey";

-- DropForeignKey
ALTER TABLE "followRequests" DROP CONSTRAINT "followRequests_followerId_fkey";

-- DropTable
DROP TABLE "followRequests";

-- CreateTable
CREATE TABLE "follow_requests" (
    "id" TEXT NOT NULL,
    "followerId" TEXT NOT NULL,
    "followeeId" TEXT NOT NULL,
    "status" "FollowRequestStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "follow_requests_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "follow_requests_followerId_followeeId_key" ON "follow_requests"("followerId", "followeeId");

-- AddForeignKey
ALTER TABLE "follow_requests" ADD CONSTRAINT "follow_requests_followerId_fkey" FOREIGN KEY ("followerId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "follow_requests" ADD CONSTRAINT "follow_requests_followeeId_fkey" FOREIGN KEY ("followeeId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

import { NextRequest, NextResponse } from "next/server";
import { ApiResponse } from "@/types/api";

export async function POST(request: NextRequest) {
  try {
    // Since we're using JWT and not storing tokens in the database,
    // we just need to return a success response
    // The client will handle clearing the tokens
    return NextResponse.json<ApiResponse>({
      success: true,
      message: "Successfully logged out",
    });
  } catch (error: any) {
    console.error("Logout error:", error);
    return NextResponse.json<ApiResponse>(
      {
        success: false,
        error: "Internal server error",
      },
      { status: 500 }
    );
  }
}
import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  try {
    console.log('[TEST-CONNECTION] Flutter app connection test');
    
    return NextResponse.json({
      success: true,
      message: 'Flutter app successfully connected to server',
      timestamp: new Date().toISOString(),
      serverInfo: {
        nodeVersion: process.version,
        environment: process.env.NODE_ENV || 'development',
        cloudinaryConfigured: !!process.env.CLOUDINARY_API_SECRET,
        cloudinarySecretLength: process.env.CLOUDINARY_API_SECRET?.length || 0,
      }
    });
    
  } catch (error) {
    console.error('[TEST-CONNECTION] Error in connection test:', error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}

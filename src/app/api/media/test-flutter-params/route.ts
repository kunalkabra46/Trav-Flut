import { NextRequest, NextResponse } from 'next/server'
import crypto from 'crypto'

export async function POST(request: NextRequest) {
  try {
    console.log('[FLUTTER-TEST] Starting Flutter parameters test');
    
    const body = await request.json();
    const { tripId, resourceType, filename } = body;
    
    console.log('[FLUTTER-TEST] Request from Flutter:', { tripId, resourceType, filename });
    
    // Generate parameters with current timestamp
    const timestamp = Math.round(Date.now() / 1000);
    const publicId = `tripthread/${tripId}/${timestamp}_${filename.replace(/\.[^/.]+$/, '')}`;
    const folder = `tripthread/${tripId}`;
    
    // These are the EXACT parameters used for signature generation
    const signatureParams = {
      timestamp,
      public_id: publicId,
      folder,
      resource_type: resourceType,
      overwrite: true,
    };
    
    // Sort parameters alphabetically (this is what Cloudinary expects)
    const sortedParams = Object.keys(signatureParams)
      .sort()
      .reduce((result: Record<string, any>, key) => {
        result[key] = signatureParams[key as keyof typeof signatureParams];
        return result;
      }, {});
    
    // Create the exact query string that should be signed
    const queryString = Object.entries(sortedParams)
      .map(([key, value]) => `${key}=${value}`)
      .join('&');
    
    // Generate signature
    const apiSecret = process.env.CLOUDINARY_API_SECRET;
    if (!apiSecret) {
      throw new Error('CLOUDINARY_API_SECRET not configured');
    }
    
    const signature = crypto
      .createHash('sha1')
      .update(queryString + apiSecret)
      .digest('hex');
    
    // What the Flutter app should send to Cloudinary (EXACTLY as strings)
    const uploadParams = {
      timestamp,
      public_id: publicId,
      folder,
      resource_type: resourceType,
      overwrite: true,
      api_key: process.env.CLOUDINARY_API_KEY,
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
      signature,
    };
    
    console.log('[FLUTTER-TEST] ===== FLUTTER PARAMETERS TEST =====');
    console.log('[FLUTTER-TEST] Timestamp:', timestamp);
    console.log('[FLUTTER-TEST] Signature parameters:', signatureParams);
    console.log('[FLUTTER-TEST] Query string for signature:', queryString);
    console.log('[FLUTTER-TEST] Generated signature:', signature);
    console.log('[FLUTTER-TEST] Upload params for Flutter:', uploadParams);
    console.log('[FLUTTER-TEST] API Secret length:', apiSecret.length);
    console.log('[FLUTTER-TEST] API Secret preview:', apiSecret.substring(0, 8) + '...');
    
    return NextResponse.json({
      success: true,
      message: 'Flutter parameters test completed',
      data: {
        uploadParams,
        publicId,
        folder,
        resourceType,
        signature,
        timestamp,
        note: 'Use these EXACT parameters in your Flutter app. Do not modify any values!'
      }
    });
    
  } catch (error) {
    console.error('[FLUTTER-TEST] Error in Flutter parameters test:', error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}

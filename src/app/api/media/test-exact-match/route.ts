import { NextRequest, NextResponse } from 'next/server'
import crypto from 'crypto'

export async function GET(request: NextRequest) {
  try {
    console.log('[EXACT-MATCH] Starting exact match test');
    
    // Use FIXED parameters to ensure consistency
    const tripId = '8019cb1d-6130-4d80-ad94-93042f61168f';
    const timestamp = 1756662000; // Fixed timestamp for testing
    const filename = 'test.jpg';
    const publicId = `tripthread/${tripId}/${timestamp}_${filename.replace(/\.[^/.]+$/, '')}`;
    const folder = `tripthread/${tripId}`;
    
    // These are the EXACT parameters used for signature generation
    const signatureParams = {
      timestamp,
      public_id: publicId,
      folder,
      resource_type: 'image',
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
    
    // What the client should send to Cloudinary (EXACTLY as strings)
    const formDataParams = {
      timestamp: timestamp.toString(),
      public_id: publicId,
      folder,
      resource_type: 'image',
      overwrite: 'true', // Convert boolean to string
      api_key: process.env.CLOUDINARY_API_KEY,
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
      signature,
    };
    
    console.log('[EXACT-MATCH] ===== EXACT MATCH TEST =====');
    console.log('[EXACT-MATCH] Fixed timestamp:', timestamp);
    console.log('[EXACT-MATCH] Signature parameters:', signatureParams);
    console.log('[EXACT-MATCH] Sorted parameters:', sortedParams);
    console.log('[EXACT-MATCH] Query string for signature:', queryString);
    console.log('[EXACT-MATCH] Generated signature:', signature);
    console.log('[EXACT-MATCH] Form data for Cloudinary:', formDataParams);
    console.log('[EXACT-MATCH] API Secret length:', apiSecret.length);
    console.log('[EXACT-MATCH] API Secret preview:', apiSecret.substring(0, 8) + '...');
    
    // Create a cURL command that should work
    const curlCommand = `curl -X POST "https://api.cloudinary.com/v1_1/${process.env.CLOUDINARY_CLOUD_NAME}/auto/upload" \\
  -F "file=@test_image.jpg" \\
  -F "timestamp=${timestamp}" \\
  -F "public_id=${publicId}" \\
  -F "folder=${folder}" \\
  -F "resource_type=image" \\
  -F "overwrite=true" \\
  -F "api_key=${process.env.CLOUDINARY_API_KEY}" \\
  -F "cloud_name=${process.env.CLOUDINARY_CLOUD_NAME}" \\
  -F "signature=${signature}"`;
    
    return NextResponse.json({
      success: true,
      message: 'Exact match test completed',
      fixedTimestamp: timestamp,
      signatureParams,
      sortedParams,
      queryString,
      signature,
      formDataParams,
      curlCommand,
      apiSecretLength: apiSecret.length,
      apiSecretPreview: apiSecret.substring(0, 8) + '...',
      note: 'Use these EXACT parameters and signature for testing. The timestamp is fixed to ensure consistency.',
      warning: 'Make sure your Flutter app sends EXACTLY these parameters, especially the timestamp and signature'
    });
    
  } catch (error) {
    console.error('[EXACT-MATCH] Error in exact match test:', error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}

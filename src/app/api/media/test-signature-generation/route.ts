import { NextRequest, NextResponse } from 'next/server'
import crypto from 'crypto'

export async function GET(request: NextRequest) {
  try {
    console.log('[TEST-SIGNATURE] Testing signature generation');
    
    // Simulate the exact parameters your app is using
    const tripId = '8019cb1d-6130-4d80-ad94-93042f61168f';
    const timestamp = Math.round(Date.now() / 1000);
    const filename = 'test.jpg';
    const resourceType = 'image';
    const publicId = `tripthread/${tripId}/${timestamp}_${filename.replace(/\.[^/.]+$/, '')}`;
    const folder = `tripthread/${tripId}`;
    
    // These are the EXACT parameters used for signature generation
    // NOTE: Cloudinary expects resource_type to match the URL path (/auto/upload)
    const signatureParams = {
      timestamp,
      public_id: publicId,
      folder,
      resource_type: 'auto', // Use 'auto' to match the URL path
      overwrite: true,
    };
    
    console.log('[TEST-SIGNATURE] Original signature params:', signatureParams);
    
    // Sort parameters alphabetically (this is what Cloudinary expects)
    const sortedParams = Object.keys(signatureParams)
      .sort()
      .reduce((result: Record<string, any>, key) => {
        result[key] = signatureParams[key as keyof typeof signatureParams];
        return result;
      }, {});
    
    console.log('[TEST-SIGNATURE] Sorted signature params:', sortedParams);
    
    // Create the exact query string that should be signed
    const queryString = Object.entries(sortedParams)
      .map(([key, value]) => `${key}=${value}`)
      .join('&');
    
    console.log('[TEST-SIGNATURE] Query string for signature:', queryString);
    
    // Generate signature
    const apiSecret = process.env.CLOUDINARY_API_SECRET;
    if (!apiSecret) {
      throw new Error('CLOUDINARY_API_SECRET not configured');
    }
    
    const signature = crypto
      .createHash('sha1')
      .update(queryString + apiSecret)
      .digest('hex');
    
    console.log('[TEST-SIGNATURE] Generated signature:', signature);
    
    // What the client should send to Cloudinary
    const clientParams = {
      ...signatureParams,
      api_key: process.env.CLOUDINARY_API_KEY,
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
      signature,
    };
    
    return NextResponse.json({
      success: true,
      message: 'Signature generation test completed',
      signatureParams,
      sortedParams,
      queryString,
      signature,
      clientParams,
      note: 'Check console logs for detailed signature generation information'
    });
    
  } catch (error) {
    console.error('[TEST-SIGNATURE] Error in signature generation test:', error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}

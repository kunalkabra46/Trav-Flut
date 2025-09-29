import { NextRequest, NextResponse } from 'next/server'
import crypto from 'crypto'

export async function GET(request: NextRequest) {
  try {
    console.log('[DEBUG] Starting signature debug test');
    
    // Simulate the exact parameters your app is using
    const tripId = '8019cb1d-6130-4d80-ad94-93042f61168f';
    const timestamp = Math.round(Date.now() / 1000);
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
    
    // What the client should send to Cloudinary
    const clientParams = {
      ...signatureParams,
      api_key: process.env.CLOUDINARY_API_KEY,
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
      signature,
    };
    
    // What the client should send in form data (all as strings)
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
    
    console.log('[DEBUG] ===== SIGNATURE DEBUG =====');
    console.log('[DEBUG] Original parameters:', signatureParams);
    console.log('[DEBUG] Sorted parameters:', sortedParams);
    console.log('[DEBUG] Query string for signature:', queryString);
    console.log('[DEBUG] Generated signature:', signature);
    console.log('[DEBUG] Client parameters:', clientParams);
    console.log('[DEBUG] Form data parameters:', formDataParams);
    console.log('[DEBUG] API Secret length:', apiSecret.length);
    console.log('[DEBUG] API Secret preview:', apiSecret.substring(0, 8) + '...');
    
    return NextResponse.json({
      success: true,
      message: 'Signature debug completed',
      signatureParams,
      sortedParams,
      queryString,
      signature,
      clientParams,
      formDataParams,
      apiSecretLength: apiSecret.length,
      apiSecretPreview: apiSecret.substring(0, 8) + '...',
      note: 'Check console logs for detailed debug information'
    });
    
  } catch (error) {
    console.error('[DEBUG] Error in signature debug:', error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}

import { NextRequest, NextResponse } from 'next/server'
import crypto from 'crypto'

export async function GET(request: NextRequest) {
  try {
    // First, get the actual parameters from the main endpoint
    const signatureResponse = await fetch(`${request.nextUrl.origin}/api/media/cloudinary-signature`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        tripId: '8019cb1d-6130-4d80-ad94-93042f61168f', // Use the real trip ID from your app
        resourceType: 'image',
        filename: 'test.jpg'
      }),
    });

    if (!signatureResponse.ok) {
      throw new Error(`Signature endpoint failed: ${signatureResponse.status}`);
    }

    const signatureData = await signatureResponse.json();
    const actualUploadParams = signatureData.data.uploadParams;
    const actualSignature = actualUploadParams.signature;

    // Extract only the parameters that should be used for signature generation
    const signatureParams = {
      timestamp: actualUploadParams.timestamp,
      public_id: actualUploadParams.public_id,
      folder: actualUploadParams.folder,
      resource_type: actualUploadParams.resource_type,
      overwrite: actualUploadParams.overwrite,
    };

    // Sort parameters alphabetically (exactly as Cloudinary expects)
    const sortedParams: Record<string, any> = Object.keys(signatureParams)
      .sort()
      .reduce((result: Record<string, any>, key) => {
        result[key] = signatureParams[key as keyof typeof signatureParams];
        return result;
      }, {});

    // Create query string (exactly as Cloudinary expects)
    const queryString = Object.entries(sortedParams)
      .map(([key, value]) => `${key}=${value}`)
      .join('&');

    console.log('[VERIFY] Actual parameters from main endpoint:', signatureParams);
    console.log('[VERIFY] Sorted parameters for signature:', sortedParams);
    console.log('[VERIFY] Query string:', queryString);

    // Get API secret
    const apiSecret = process.env.CLOUDINARY_API_SECRET;
    if (!apiSecret || apiSecret === 'your_actual_api_secret' || apiSecret === 'your_actual_api_secret_here') {
      return NextResponse.json({
        success: false,
        error: 'CLOUDINARY_API_SECRET not configured properly',
        currentValue: apiSecret || 'undefined'
      }, { status: 400 });
    }

    // Generate expected signature (exactly as Cloudinary expects)
    const expectedSignature = crypto
      .createHash('sha1')
      .update(queryString + apiSecret)
      .digest('hex');

    console.log('[VERIFY] Expected signature:', expectedSignature);
    console.log('[VERIFY] Actual signature:', actualSignature);
    console.log('[VERIFY] Signatures match:', expectedSignature === actualSignature);

    return NextResponse.json({
      success: true,
      message: 'Signature verification completed',
      actualParams: signatureParams,
      sortedParams,
      queryString,
      expectedSignature,
      actualSignature,
      signaturesMatch: expectedSignature === actualSignature,
      apiSecretLength: apiSecret.length,
      apiSecretPreview: apiSecret.substring(0, 8) + '...'
    });

  } catch (error) {
    console.error('[VERIFY] Error verifying signature:', error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}

import { NextRequest, NextResponse } from 'next/server'
import crypto from 'crypto'

export async function GET(request: NextRequest) {
  try {
    console.log('[TEST-FLOW] Starting complete upload flow test');
    
    // Step 1: Get upload parameters from our signature endpoint
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
    const uploadParams = signatureData.data.uploadParams;
    
    console.log('[TEST-FLOW] Received upload params:', uploadParams);

    // Step 2: Extract the parameters that should be used for signature verification
    const signatureParams = {
      timestamp: uploadParams.timestamp,
      public_id: uploadParams.public_id,
      folder: uploadParams.folder,
      resource_type: uploadParams.resource_type,
      overwrite: uploadParams.overwrite,
    };

    // Step 3: Generate the signature that Cloudinary expects
    const sortedParams = Object.keys(signatureParams)
      .sort()
      .reduce((result: Record<string, any>, key) => {
        result[key] = signatureParams[key as keyof typeof signatureParams];
        return result;
      }, {});

    const queryString = Object.entries(sortedParams)
      .map(([key, value]) => `${key}=${value}`)
      .join('&');

    console.log('[TEST-FLOW] Parameters for signature:', sortedParams);
    console.log('[TEST-FLOW] Query string for signature:', queryString);

    // Step 4: Generate expected signature
    const apiSecret = process.env.CLOUDINARY_API_SECRET;
    if (!apiSecret) {
      throw new Error('CLOUDINARY_API_SECRET not configured');
    }

    const expectedSignature = crypto
      .createHash('sha1')
      .update(queryString + apiSecret)
      .digest('hex');

    console.log('[TEST-FLOW] Expected signature:', expectedSignature);
    console.log('[TEST-FLOW] Actual signature from endpoint:', uploadParams.signature);
    console.log('[TEST-FLOW] Signatures match:', expectedSignature === uploadParams.signature);

    // Step 5: Create the exact request that Flutter will send
    const testRequest = {
      url: `https://api.cloudinary.com/v1_1/${uploadParams.cloud_name}/auto/upload`,
      fields: {
        timestamp: uploadParams.timestamp.toString(),
        public_id: uploadParams.public_id,
        folder: uploadParams.folder,
        resource_type: uploadParams.resource_type,
        overwrite: uploadParams.overwrite.toString(),
        api_key: uploadParams.api_key,
        cloud_name: uploadParams.cloud_name,
        signature: uploadParams.signature,
      }
    };

    console.log('[TEST-FLOW] Test request that Flutter will send:', testRequest);

    // Step 6: Verify the signature matches what Cloudinary expects
    const cloudinarySignatureParams = {
      timestamp: uploadParams.timestamp,
      public_id: uploadParams.public_id,
      folder: uploadParams.folder,
      resource_type: uploadParams.resource_type,
      overwrite: uploadParams.overwrite,
    };

    const cloudinaryQueryString = Object.entries(cloudinarySignatureParams)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([key, value]) => `${key}=${value}`)
      .join('&');

    const cloudinaryExpectedSignature = crypto
      .createHash('sha1')
      .update(cloudinaryQueryString + apiSecret)
      .digest('hex');

    console.log('[TEST-FLOW] Cloudinary expected query string:', cloudinaryQueryString);
    console.log('[TEST-FLOW] Cloudinary expected signature:', cloudinaryExpectedSignature);
    console.log('[TEST-FLOW] Cloudinary signature match:', cloudinaryExpectedSignature === uploadParams.signature);

    return NextResponse.json({
      success: true,
      message: 'Complete upload flow test completed',
      uploadParams,
      signatureParams,
      queryString,
      expectedSignature,
      actualSignature: uploadParams.signature,
      signaturesMatch: expectedSignature === uploadParams.signature,
      testRequest,
      cloudinaryQueryString,
      cloudinaryExpectedSignature,
      cloudinarySignatureMatch: cloudinaryExpectedSignature === uploadParams.signature,
      apiSecretLength: apiSecret.length,
      apiSecretPreview: apiSecret.substring(0, 8) + '...'
    });

  } catch (error) {
    console.error('[TEST-FLOW] Error in upload flow test:', error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}

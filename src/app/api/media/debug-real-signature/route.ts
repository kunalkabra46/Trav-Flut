import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  try {
    console.log('[DEBUG-REAL] Starting real signature debug test');
    
    // Call the actual signature endpoint that your Flutter app uses
    const signatureResponse = await fetch(`${request.nextUrl.origin}/api/media/cloudinary-signature`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        tripId: '8019cb1d-6130-4d80-ad94-93042f61168f',
        resourceType: 'image',
        filename: 'test.jpg'
      }),
    });

    if (!signatureResponse.ok) {
      throw new Error(`Signature endpoint failed: ${signatureResponse.status}`);
    }

    const signatureData = await signatureResponse.json();
    const uploadParams = signatureData.data.uploadParams;
    
    console.log('[DEBUG-REAL] ===== REAL SIGNATURE DEBUG =====');
    console.log('[DEBUG-REAL] Full response from signature endpoint:', signatureData);
    console.log('[DEBUG-REAL] Upload params received:', uploadParams);
    console.log('[DEBUG-REAL] Signature received:', uploadParams.signature);
    console.log('[DEBUG-REAL] All parameters:', Object.keys(uploadParams));
    
    // Show what the client should send to Cloudinary
    const formDataParams = {
      timestamp: uploadParams.timestamp.toString(),
      public_id: uploadParams.public_id,
      folder: uploadParams.folder,
      resource_type: uploadParams.resource_type,
      overwrite: uploadParams.overwrite.toString(),
      api_key: uploadParams.api_key,
      cloud_name: uploadParams.cloud_name,
      signature: uploadParams.signature,
    };
    
    console.log('[DEBUG-REAL] Form data parameters for Cloudinary:', formDataParams);
    
    return NextResponse.json({
      success: true,
      message: 'Real signature debug completed',
      fullResponse: signatureData,
      uploadParams,
      formDataParams,
      note: 'This shows exactly what your Flutter app receives and should send to Cloudinary'
    });
    
  } catch (error) {
    console.error('[DEBUG-REAL] Error in real signature debug:', error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}

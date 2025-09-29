import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  try {
    // Get upload parameters from our signature endpoint
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

    // Show the exact form data that should be sent
    const formDataFields = {
      timestamp: uploadParams.timestamp.toString(),
      public_id: uploadParams.public_id,
      folder: uploadParams.folder,
      resource_type: uploadParams.resource_type,
      overwrite: uploadParams.overwrite.toString(), // Convert boolean to string
      api_key: uploadParams.api_key,
      cloud_name: uploadParams.cloud_name,
      signature: uploadParams.signature,
    };

    // Show what the signature was generated for
    const signatureParams = {
      timestamp: uploadParams.timestamp,
      public_id: uploadParams.public_id,
      folder: uploadParams.folder,
      resource_type: uploadParams.resource_type,
      overwrite: uploadParams.overwrite,
    };

    return NextResponse.json({
      success: true,
      message: 'Form data test completed',
      originalUploadParams: uploadParams,
      formDataFields,
      signatureParams,
      note: 'All form data values must be strings. Boolean values like overwrite must be converted to "true"/"false"',
      warning: 'If overwrite is sent as boolean true instead of string "true", Cloudinary will reject the signature'
    });

  } catch (error) {
    console.error('[TEST-FORM] Error in form data test:', error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}

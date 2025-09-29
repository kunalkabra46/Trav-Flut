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

    // Create the exact cURL command that should work
    const curlCommand = `curl -X POST "https://api.cloudinary.com/v1_1/${uploadParams.cloud_name}/auto/upload" \\
  -F "file=@test_image.jpg" \\
  -F "timestamp=${uploadParams.timestamp}" \\
  -F "public_id=${uploadParams.public_id}" \\
  -F "folder=${uploadParams.folder}" \\
  -F "resource_type=${uploadParams.resource_type}" \\
  -F "overwrite=${uploadParams.overwrite}" \\
  -F "api_key=${uploadParams.api_key}" \\
  -F "cloud_name=${uploadParams.cloud_name}" \\
  -F "signature=${uploadParams.signature}"`;

    // Create the exact form data that Flutter should send
    const formData = {
      timestamp: uploadParams.timestamp.toString(),
      public_id: uploadParams.public_id,
      folder: uploadParams.folder,
      resource_type: uploadParams.resource_type,
      overwrite: uploadParams.overwrite.toString(), // Convert boolean to string
      api_key: uploadParams.api_key,
      cloud_name: uploadParams.cloud_name,
      signature: uploadParams.signature,
    };

    return NextResponse.json({
      success: true,
      message: 'cURL test command generated',
      uploadParams,
      formData,
      curlCommand,
      note: 'Convert all boolean values to strings for form data'
    });

  } catch (error) {
    console.error('[TEST-CURL] Error generating cURL command:', error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}

import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { tripId, resourceType, filename } = body
    
    console.log('[TEST] Testing upload parameters:', { tripId, resourceType, filename })
    
    // Call the signature endpoint to get upload parameters
    const signatureResponse = await fetch(`${request.nextUrl.origin}/api/media/cloudinary-signature`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ tripId, resourceType, filename }),
    })
    
    if (!signatureResponse.ok) {
      throw new Error(`Signature endpoint failed: ${signatureResponse.status}`)
    }
    
    const signatureData = await signatureResponse.json()
    console.log('[TEST] Signature response:', signatureData)
    
    // Test the upload parameters by creating a test request
    const uploadParams = signatureData.data.uploadParams
    const testUrl = `https://api.cloudinary.com/v1_1/${uploadParams.cloud_name}/auto/upload`
    
    console.log('[TEST] Test upload URL:', testUrl)
    console.log('[TEST] Upload parameters:', uploadParams)
    
    return NextResponse.json({
      success: true,
      message: 'Upload parameters test successful',
      testUrl,
      uploadParams,
      signatureData: signatureData.data
    })
    
  } catch (error) {
    console.error('[TEST] Error testing upload:', error)
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 })
  }
}

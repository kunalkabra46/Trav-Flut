import { NextRequest, NextResponse } from 'next/server'
import crypto from 'crypto'

export async function GET(request: NextRequest) {
  try {
    // Test signature generation with simple parameters
    const testParams = {
      timestamp: Math.round(Date.now() / 1000),
      public_id: 'test_public_id',
      folder: 'test_folder',
      resource_type: 'image',
      overwrite: true,
    };

    // Sort parameters alphabetically
    const sortedParams = Object.keys(testParams)
      .sort()
      .reduce((result: Record<string, any>, key) => {
        result[key] = testParams[key];
        return result;
      }, {});

    // Create query string
    const queryString = Object.entries(sortedParams)
      .map(([key, value]) => `${key}=${value}`)
      .join('&');

    console.log('[TEST] Test parameters:', sortedParams);
    console.log('[TEST] Query string:', queryString);

    // Get API secret
    const apiSecret = process.env.CLOUDINARY_API_SECRET;
    if (!apiSecret || apiSecret === 'your_actual_api_secret' || apiSecret === 'your_actual_api_secret_here') {
      return NextResponse.json({
        success: false,
        error: 'CLOUDINARY_API_SECRET not configured properly',
        currentValue: apiSecret || 'undefined',
        message: 'Please update .env.local with your real Cloudinary API secret'
      }, { status: 400 });
    }

    // Generate signature
    const signature = crypto
      .createHash('sha1')
      .update(queryString + apiSecret)
      .digest('hex');

    console.log('[TEST] Generated signature:', signature);
    console.log('[TEST] API secret length:', apiSecret.length);

    return NextResponse.json({
      success: true,
      message: 'Signature generation test successful',
      testParams: sortedParams,
      queryString,
      signature,
      apiSecretLength: apiSecret.length,
      apiSecretPreview: apiSecret.substring(0, 8) + '...'
    });

  } catch (error) {
    console.error('[TEST] Error testing signature:', error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}

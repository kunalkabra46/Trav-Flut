import { NextRequest, NextResponse } from 'next/server'
import crypto from 'crypto'

export async function POST(request: NextRequest) {
  try {
    console.log('[LIVE-DEBUG] ===== LIVE UPLOAD DEBUG STARTED =====');
    
    // Get the form data that Flutter is trying to send
    const formData = await request.formData();
    
    console.log('[LIVE-DEBUG] Form data received from Flutter:');
    console.log('[LIVE-DEBUG] - File present:', formData.has('file'));
    console.log('[LIVE-DEBUG] - All form fields:');

    const receivedParams: Record<string, any> = {};
    Array.from(formData.entries()).forEach(([key, value]) => {
      if (key !== 'file') {
        receivedParams[key] = value;
        console.log(`[LIVE-DEBUG]   ${key}: ${value} (type: ${typeof value})`);
      }
    });
    
    console.log('[LIVE-DEBUG] - File info:');
    const file = formData.get('file') as File;
    if (file) {
      console.log(`[LIVE-DEBUG]   Filename: ${file.name}`);
      console.log(`[LIVE-DEBUG]   Size: ${file.size} bytes`);
      console.log(`[LIVE-DEBUG]   Type: ${file.type}`);
    }
    
    // Now generate what the signature SHOULD be for these parameters
    console.log('[LIVE-DEBUG] ===== GENERATING EXPECTED SIGNATURE =====');
    
    // Extract the parameters that should be used for signature generation
    const signatureParams = {
      timestamp: receivedParams.timestamp,
      public_id: receivedParams.public_id,
      folder: receivedParams.folder,
      resource_type: receivedParams.resource_type,
      overwrite: receivedParams.overwrite,
    };
    
    console.log('[LIVE-DEBUG] Parameters extracted for signature:', signatureParams);
    
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
    
    console.log('[LIVE-DEBUG] Sorted parameters:', sortedParams);
    console.log('[LIVE-DEBUG] Query string for signature:', queryString);
    
    // Generate expected signature
    const apiSecret = process.env.CLOUDINARY_API_SECRET;
    if (!apiSecret) {
      throw new Error('CLOUDINARY_API_SECRET not configured');
    }
    
    const expectedSignature = crypto
      .createHash('sha1')
      .update(queryString + apiSecret)
      .digest('hex');
    
    const actualSignature = receivedParams.signature;
    
    console.log('[LIVE-DEBUG] ===== SIGNATURE COMPARISON =====');
    console.log('[LIVE-DEBUG] Expected signature:', expectedSignature);
    console.log('[LIVE-DEBUG] Actual signature received:', actualSignature);
    console.log('[LIVE-DEBUG] Signatures match:', expectedSignature === actualSignature);
    
    if (expectedSignature !== actualSignature) {
      console.log('[LIVE-DEBUG] 🚨 SIGNATURE MISMATCH DETECTED!');
      console.log('[LIVE-DEBUG] This explains the 401 error!');
      
      // Show what the client should have sent
      const correctFormData = {
        timestamp: receivedParams.timestamp,
        public_id: receivedParams.public_id,
        folder: receivedParams.folder,
        resource_type: receivedParams.resource_type,
        overwrite: receivedParams.overwrite,
        api_key: receivedParams.api_key,
        cloud_name: receivedParams.cloud_name,
        signature: expectedSignature, // Use the correct signature
      };
      
      console.log('[LIVE-DEBUG] Correct form data should be:', correctFormData);
    }
    
    // Now actually forward the request to Cloudinary with the CORRECT signature
    console.log('[LIVE-DEBUG] ===== FORWARDING TO CLOUDINARY =====');
    
    // Create new form data with correct signature
    const correctedFormData = new FormData();
    
    // Add the file
    if (file) {
      correctedFormData.append('file', file);
    }
    
    // CRITICAL: Add parameters in EXACTLY the same order and format as signature generation
    // This ensures perfect consistency between signature generation and upload
    correctedFormData.append('timestamp', receivedParams.timestamp);
    correctedFormData.append('public_id', receivedParams.public_id);
    correctedFormData.append('folder', receivedParams.folder);
    correctedFormData.append('resource_type', receivedParams.resource_type);
    correctedFormData.append('overwrite', receivedParams.overwrite);
    correctedFormData.append('api_key', receivedParams.api_key);
    correctedFormData.append('cloud_name', receivedParams.cloud_name);
    correctedFormData.append('signature', expectedSignature); // Use correct signature
    
    console.log('[LIVE-DEBUG] Corrected form data being sent to Cloudinary:');
    console.log('[LIVE-DEBUG] - timestamp:', receivedParams.timestamp);
    console.log('[LIVE-DEBUG] - public_id:', receivedParams.public_id);
    console.log('[LIVE-DEBUG] - folder:', receivedParams.folder);
    console.log('[LIVE-DEBUG] - resource_type:', receivedParams.resource_type);
    console.log('[LIVE-DEBUG] - overwrite:', receivedParams.overwrite);
    console.log('[LIVE-DEBUG] - api_key:', receivedParams.api_key);
    console.log('[LIVE-DEBUG] - cloud_name:', receivedParams.cloud_name);
    console.log('[LIVE-DEBUG] - signature:', expectedSignature);
    
    console.log('[LIVE-DEBUG] Forwarding corrected request to Cloudinary...');
    
    // CRITICAL: Verify that the parameters we're sending match the signature generation
    const cloudinaryParams = {
      timestamp: receivedParams.timestamp,
      public_id: receivedParams.public_id,
      folder: receivedParams.folder,
      resource_type: receivedParams.resource_type,
      overwrite: receivedParams.overwrite,
    };
    
    const cloudinarySortedParams = Object.keys(cloudinaryParams)
      .sort()
      .reduce((result: Record<string, any>, key) => {
        result[key] = cloudinaryParams[key as keyof typeof cloudinaryParams];
        return result;
      }, {});
    
    const cloudinaryQueryString = Object.entries(cloudinarySortedParams)
      .map(([key, value]) => `${key}=${value}`)
      .join('&');
    
    console.log('[LIVE-DEBUG] Cloudinary query string verification:');
    console.log('[LIVE-DEBUG] - Original query string:', queryString);
    console.log('[LIVE-DEBUG] - Cloudinary query string:', cloudinaryQueryString);
    console.log('[LIVE-DEBUG] - Query strings match:', queryString === cloudinaryQueryString);
    
    if (queryString !== cloudinaryQueryString) {
      console.log('[LIVE-DEBUG] 🚨 CRITICAL ERROR: Query strings do not match!');
      console.log('[LIVE-DEBUG] This will cause signature validation to fail!');
    }
    
    // Forward to Cloudinary
    const cloudinaryResponse = await fetch(
      `https://api.cloudinary.com/v1_1/${receivedParams.cloud_name}/auto/upload`,
      {
        method: 'POST',
        body: correctedFormData,
      }
    );
    
    const cloudinaryResult = await cloudinaryResponse.text();
    
    console.log('[LIVE-DEBUG] Cloudinary response status:', cloudinaryResponse.status);
    console.log('[LIVE-DEBUG] Cloudinary response body:', cloudinaryResult);
    
    if (cloudinaryResponse.ok) {
      console.log('[LIVE-DEBUG] ✅ SUCCESS! Upload worked with corrected signature');
      return NextResponse.json({
        success: true,
        message: 'Upload successful with corrected signature',
        data: {
          originalSignature: actualSignature,
          correctedSignature: expectedSignature,
          cloudinaryResponse: cloudinaryResult,
          note: 'The issue was a signature mismatch. Your Flutter app needs to send the exact parameters used for signature generation.'
        }
      });
    } else {
      console.log('[LIVE-DEBUG] ❌ Still failed even with corrected signature');
      return NextResponse.json({
        success: false,
        message: 'Upload failed even with corrected signature',
        error: cloudinaryResult,
        data: {
          originalSignature: actualSignature,
          correctedSignature: expectedSignature,
          note: 'There might be another issue beyond signature mismatch.'
        }
      }, { status: cloudinaryResponse.status });
    }
    
  } catch (error) {
    console.error('[LIVE-DEBUG] Error in live upload debug:', error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}

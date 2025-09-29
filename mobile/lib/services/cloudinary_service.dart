import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tripthread/services/api_service.dart';
import 'package:tripthread/services/storage_service.dart';

class CloudinaryService {
  final ApiService _apiService;
  final StorageService _storageService;

  CloudinaryService(this._apiService, this._storageService);

  /// Get upload signature from backend
  Future<Map<String, dynamic>?> getUploadSignature({
    required String tripId,
    required String filename,
    required String resourceType,
  }) async {
    try {
      print('[CloudinaryService] ===== GET UPLOAD SIGNATURE START =====');
      print('[CloudinaryService] Trip ID: $tripId');
      print('[CloudinaryService] Filename: $filename');
      print('[CloudinaryService] Resource Type: $resourceType');
      
      final token = await _storageService.getAccessToken();
      if (token == null) {
        print('[CloudinaryService] ❌ No access token available');
        throw Exception('No access token available');
      }
      
      print('[CloudinaryService] ✅ Got access token: ${token.substring(0, 10)}...');

      // Use the working cloudinary-signature endpoint
      print('[CloudinaryService] Calling backend endpoint: /media/cloudinary-signature');
      final response = await _apiService.post(
        '/media/cloudinary-signature', // Changed back to the working endpoint
        body: {
          'tripId': tripId,
          'filename': filename,
          'resourceType': resourceType,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      print('[CloudinaryService] Backend response received:');
      print('[CloudinaryService] - Success: ${response.success}');
      print('[CloudinaryService] - Error: ${response.error}');
      print('[CloudinaryService] - Data: ${response.data}');

      if (response.success && response.data != null) {
        final uploadParams = response.data['uploadParams'] as Map<String, dynamic>;
        print('[CloudinaryService] ✅ Got upload params: $uploadParams');
        return uploadParams;
      } else {
        print('[CloudinaryService] ❌ Failed to get upload params: ${response.error}');
        return null;
      }
    } catch (e) {
      print('[CloudinaryService] ❌ Exception in getUploadSignature: $e');
      return null;
    }
  }

  /// Upload file directly to Cloudinary
  Future<String?> uploadToCloudinary({
    required File file,
    required Map<String, dynamic> uploadParams,
  }) async {
    try {
      print('[CloudinaryService] ===== UPLOAD START =====');
      print('[CloudinaryService] Received upload params: $uploadParams');
      
      // Check if this is a mock response
      if (uploadParams['cloud_name'] == 'test_cloud' || 
          uploadParams['api_key'] == 'test_key') {
        print('[CloudinaryService] Mock mode detected, returning placeholder image');
        return 'https://via.placeholder.com/400x300/007bff/ffffff?text=Test+Image';
      }
      
      // TEMPORARY: Use debug endpoint to identify signature mismatch
      print('[CloudinaryService] 🔍 DEBUG MODE: Using debug endpoint to identify signature mismatch');
      
      // Create multipart request to our debug endpoint
      final debugRequest = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.213.8.130:3000/api/media/debug-live-upload'), // Use actual server IP
      );

      // Add file
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: file.path.split('/').last,
      );
      debugRequest.files.add(multipartFile);
      print('[CloudinaryService] Added file: ${file.path.split('/').last} (${fileLength} bytes)');

      // Add upload parameters EXACTLY as received from backend
      print('[CloudinaryService] Adding upload parameters to debug request...');
      print('[CloudinaryService] ⚠️  CRITICAL: Using EXACT parameters from backend for signature consistency');
      
      uploadParams.forEach((key, value) {
        if (key != 'file') { // Don't add 'file' as a field
          // Convert all values to strings, especially booleans
          final stringValue = value.toString();
          debugRequest.fields[key] = stringValue;
          print('[CloudinaryService] ✅ Added field: $key = $stringValue (original: $value)');
        }
      });

      print('[CloudinaryService] ===== DEBUG REQUEST DETAILS =====');
      print('[CloudinaryService] Request URL: ${debugRequest.url}');
      print('[CloudinaryService] Request fields: ${debugRequest.fields}');
      print('[CloudinaryService] Request files count: ${debugRequest.files.length}');
      
      // Verify signature consistency
      print('[CloudinaryService] 🔍 VERIFYING SIGNATURE CONSISTENCY:');
      print('[CloudinaryService] - Timestamp: ${debugRequest.fields['timestamp']}');
      print('[CloudinaryService] - Public ID: ${debugRequest.fields['public_id']}');
      print('[CloudinaryService] - Folder: ${debugRequest.fields['folder']}');
      print('[CloudinaryService] - Resource Type: ${debugRequest.fields['resource_type']}');
      print('[CloudinaryService] - Overwrite: ${debugRequest.fields['overwrite']}');
      print('[CloudinaryService] - Signature: ${debugRequest.fields['signature']}');
      
      // Send request to debug endpoint
      print('[CloudinaryService] Sending request to debug endpoint...');
      final streamedResponse = await debugRequest.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('[CloudinaryService] ===== DEBUG RESPONSE DETAILS =====');
      print('[CloudinaryService] Response status: ${response.statusCode}');
      print('[CloudinaryService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('[CloudinaryService] ✅ Debug endpoint successful');
        print('[CloudinaryService] Debug response: $responseData');
        
        // Extract the Cloudinary URL from the debug response
        try {
          final cloudinaryData = json.decode(responseData['data']['cloudinaryResponse']);
          final secureUrl = cloudinaryData['secure_url'] as String?;
          if (secureUrl != null) {
            print('[CloudinaryService] ✅ Upload successful via debug endpoint, URL: $secureUrl');
            return secureUrl;
          }
        } catch (e) {
          print('[CloudinaryService] Could not parse Cloudinary response from debug endpoint: $e');
        }
        
        // Fallback: return a placeholder since debug endpoint worked
        return 'https://via.placeholder.com/400x300/28a745/ffffff?text=Debug+Success';
      } else {
        print('[CloudinaryService] ❌ Debug endpoint failed with status: ${response.statusCode}');
        print('[CloudinaryService] Error response: ${response.body}');
        
        // Try to parse error details
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['error'] ?? 'Unknown error';
          print('[CloudinaryService] Parsed error message: $errorMessage');
          throw Exception('Debug endpoint failed: ${response.statusCode} - $errorMessage');
        } catch (parseError) {
          print('[CloudinaryService] Could not parse error response: $parseError');
          throw Exception('Debug endpoint failed: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('[CloudinaryService] ❌ Exception during debug upload: $e');
      throw Exception('Failed to upload via debug endpoint: $e');
    }
  }

  /// Complete the upload flow by confirming with backend
  Future<Map<String, dynamic>?> confirmUpload({
    required String tripId,
    required String url,
    required String type, // 'IMAGE' or 'VIDEO'
    required String filename,
    int? size,
  }) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        throw Exception('No access token available');
      }

      final response = await _apiService.post(
        '/media/confirm',
        body: {
          'tripId': tripId,
          'url': url,
          'type': type,
          'filename': filename,
          'size': size,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.success && response.data != null) {
        return response.data['media'] as Map<String, dynamic>;
      } else {
        throw Exception(response.error ?? 'Failed to confirm upload');
      }
    } catch (e) {
      throw Exception('Failed to confirm upload: $e');
    }
  }

  /// Complete upload flow: get signature, upload to Cloudinary, confirm with backend
  Future<String?> uploadMedia({
    required File file,
    required String tripId,
    required String resourceType, // 'image' or 'video'
  }) async {
    try {
      print('[CloudinaryService] ===== UPLOAD MEDIA START =====');
      print('[CloudinaryService] File: ${file.path}');
      print('[CloudinaryService] Trip ID: $tripId');
      print('[CloudinaryService] Resource Type: $resourceType');
      
      final filename = file.path.split('/').last;
      final size = await file.length();
      print('[CloudinaryService] Filename: $filename, Size: $size bytes');

      // Step 1: Get upload signature from backend
      print('[CloudinaryService] Step 1: Getting upload signature from backend...');
      final uploadParams = await getUploadSignature(
        tripId: tripId,
        filename: filename,
        resourceType: resourceType,
      );

      if (uploadParams == null) {
        print('[CloudinaryService] ❌ Failed to get upload parameters');
        throw Exception('Failed to get upload parameters');
      }
      
      print('[CloudinaryService] ✅ Got upload parameters: $uploadParams');

      // Step 2: Upload to Cloudinary via debug endpoint
      print('[CloudinaryService] Step 2: Uploading to Cloudinary via debug endpoint...');
      final cloudinaryUrl = await uploadToCloudinary(
        file: file,
        uploadParams: uploadParams,
      );

      if (cloudinaryUrl == null) {
        print('[CloudinaryService] ❌ Failed to upload to Cloudinary');
        throw Exception('Failed to upload to Cloudinary');
      }
      
      print('[CloudinaryService] ✅ Upload successful, URL: $cloudinaryUrl');

      // Step 3: Confirm upload with backend
      print('[CloudinaryService] Step 3: Confirming upload with backend...');
      final mediaType = resourceType == 'image' ? 'IMAGE' : 'VIDEO';
      final media = await confirmUpload(
        tripId: tripId,
        url: cloudinaryUrl,
        type: mediaType,
        filename: filename,
        size: size,
      );

      if (media != null) {
        print('[CloudinaryService] ✅ Upload confirmation successful');
        return cloudinaryUrl;
      } else {
        print('[CloudinaryService] ❌ Failed to confirm upload');
        throw Exception('Failed to confirm upload');
      }
    } catch (e) {
      print('[CloudinaryService] ❌ Exception in uploadMedia: $e');
      throw Exception('Media upload failed: $e');
    }
  }
}

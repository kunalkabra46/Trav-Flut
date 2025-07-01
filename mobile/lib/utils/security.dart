import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class SecurityUtils {
  // Generate secure random string
  static String generateSecureToken({int length = 32}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Hash sensitive data
  static String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Validate password strength
  static PasswordStrength validatePasswordStrength(String password) {
    int score = 0;
    List<String> feedback = [];

    // Length check
    if (password.length >= 8) {
      score += 1;
    } else {
      feedback.add('Password should be at least 8 characters long');
    }

    if (password.length >= 12) {
      score += 1;
    }

    // Character variety checks
    if (RegExp(r'[a-z]').hasMatch(password)) {
      score += 1;
    } else {
      feedback.add('Include lowercase letters');
    }

    if (RegExp(r'[A-Z]').hasMatch(password)) {
      score += 1;
    } else {
      feedback.add('Include uppercase letters');
    }

    if (RegExp(r'\d').hasMatch(password)) {
      score += 1;
    } else {
      feedback.add('Include numbers');
    }

    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      score += 1;
    } else {
      feedback.add('Include special characters');
    }

    // Common password check
    final commonPasswords = ['password', '123456', 'qwerty', 'abc123', 'password123'];
    if (commonPasswords.contains(password.toLowerCase())) {
      score = 0;
      feedback.add('Avoid common passwords');
    }

    return PasswordStrength(
      isValid: score >= 4,
      score: score,
      feedback: feedback,
    );
  }

  // Sanitize user input
  static String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[<>]'), '') // Remove potential HTML tags
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '') // Remove javascript: protocol
        .replaceAll(RegExp(r'on\w+=', caseSensitive: false), ''); // Remove event handlers
  }

  // Validate file upload security
  static FileValidationResult validateFileUpload({
    required String filename,
    required String mimeType,
    required int fileSize,
  }) {
    List<String> errors = [];

    // File size limits (50MB)
    const maxSize = 50 * 1024 * 1024;
    if (fileSize > maxSize) {
      errors.add('File size exceeds 50MB limit');
    }

    // Allowed file types
    const allowedTypes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'video/mp4',
      'video/mov',
      'video/avi'
    ];

    if (!allowedTypes.contains(mimeType)) {
      errors.add('File type not allowed');
    }

    // File name validation
    final fileNamePattern = RegExp(r'^[a-zA-Z0-9._-]+$');
    if (!fileNamePattern.hasMatch(filename)) {
      errors.add('Invalid file name format');
    }

    // Check for double extensions
    final extensionCount = '.'.allMatches(filename).length;
    if (extensionCount > 1) {
      errors.add('Multiple file extensions not allowed');
    }

    return FileValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  // Rate limiting helper
  static bool checkRateLimit({
    required String key,
    required int maxRequests,
    required Duration window,
    required Map<String, RateLimitData> store,
  }) {
    final now = DateTime.now();
    final data = store[key];

    if (data == null) {
      store[key] = RateLimitData(count: 1, resetTime: now.add(window));
      return true;
    }

    if (now.isAfter(data.resetTime)) {
      // Reset window
      store[key] = RateLimitData(count: 1, resetTime: now.add(window));
      return true;
    }

    if (data.count >= maxRequests) {
      return false; // Rate limit exceeded
    }

    data.count++;
    return true;
  }
}

class PasswordStrength {
  final bool isValid;
  final int score;
  final List<String> feedback;

  PasswordStrength({
    required this.isValid,
    required this.score,
    required this.feedback,
  });
}

class FileValidationResult {
  final bool isValid;
  final List<String> errors;

  FileValidationResult({
    required this.isValid,
    required this.errors,
  });
}

class RateLimitData {
  int count;
  DateTime resetTime;

  RateLimitData({
    required this.count,
    required this.resetTime,
  });
}
// lib/services/storage_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

/**
 * storage_service.dart
 * 
 * Provides a centralized service for file storage operations using Supabase Storage.
 * Handles file uploads, downloads, validation, and management for different file types.
 * 
 * Features:
 * - Avatar image upload and management
 * - Pitch deck file upload and management
 * - File validation with size and type restrictions
 * - Secure file naming with user isolation
 * - File metadata handling
 * - Error handling with custom exceptions
 * - File listing and organization
 */

/**
 * StorageService - Utility class for managing file storage operations.
 * Provides static methods for interacting with Supabase Storage buckets.
 */
class StorageService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /**
   * Bucket name for avatar images storage.
   */
  static const String avatarsBucket = 'avatars';

  /**
   * Bucket name for pitch deck files storage.
   */
  static const String pitchDecksBucket = 'pitch-deck-files';

  /**
   * Maximum allowed size for avatar images (5MB).
   */
  static const int maxAvatarSize = 5 * 1024 * 1024; // 5MB

  /**
   * Maximum allowed size for pitch deck files (100MB).
   */
  static const int maxPitchDeckSize = 100 * 1024 * 1024; // 100MB

  /**
   * List of allowed file extensions for avatar images.
   */
  static const List<String> avatarExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  /**
   * List of allowed file extensions for pitch deck files.
   */
  static const List<String> pitchDeckExtensions = [
    'pdf',
    'mp4',
    'avi',
    'mov',
    'mkv',
    'wmv',
  ];

  /**
   * Uploads an avatar image to Supabase storage.
   * Validates the file, creates a unique filename, and returns the public URL.
   * 
   * @param file The avatar image file to upload
   * @param userId The user ID for folder organization
   * @return The public URL of the uploaded avatar
   * @throws StorageException if validation or upload fails
   */
  static Future<String> uploadAvatar({
    required File file,
    required String userId,
  }) async {
    try {
      // Validate file
      validateAvatarFile(file);

      // Generate unique filename with user folder structure
      final extension = path
          .extension(file.path)
          .toLowerCase()
          .replaceAll('.', '');
      final fileName =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Read file bytes
      final bytes = await file.readAsBytes();

      // Upload to Supabase storage
      await _supabase.storage
          .from(avatarsBucket)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _getContentType(extension),
            ),
          );

      // Get and return public URL
      final publicUrl = _supabase.storage
          .from(avatarsBucket)
          .getPublicUrl(fileName);

      debugPrint('✅ Avatar uploaded successfully: $fileName');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading avatar: $e');
      throw StorageException('Failed to upload avatar: ${e.toString()}');
    }
  }

  /**
   * Uploads multiple pitch deck files to Supabase storage.
   * Validates each file, creates unique filenames, and returns URLs and metadata.
   * 
   * @param files List of pitch deck files to upload
   * @param userId The user ID for folder organization
   * @param pitchDeckId Optional pitch deck ID for file grouping
   * @return Map containing file URLs, names, original names, and count
   * @throws StorageException if validation or upload fails
   */
  static Future<Map<String, dynamic>> uploadPitchDeckFiles({
    required List<File> files,
    required String userId,
    String? pitchDeckId,
  }) async {
    try {
      if (files.isEmpty) {
        throw StorageException('No files provided for upload');
      }

      List<String> fileUrls = [];
      List<String> fileNames = [];
      List<String> originalNames = [];

      for (int i = 0; i < files.length; i++) {
        final file = files[i];

        // Validate each file
        validatePitchDeckFile(file);

        // Generate unique filename with user folder structure
        final extension = path
            .extension(file.path)
            .toLowerCase()
            .replaceAll('.', '');
        final originalName = path.basename(file.path);
        final fileName =
            '$userId/${pitchDeckId ?? 'temp'}_${i}_${DateTime.now().millisecondsSinceEpoch}.$extension';

        // Read file bytes
        final bytes = await file.readAsBytes();

        // Upload to Supabase storage
        await _supabase.storage
            .from(pitchDecksBucket)
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(
                upsert: true,
                contentType: _getContentType(extension),
              ),
            );

        // Get public URL
        final publicUrl = _supabase.storage
            .from(pitchDecksBucket)
            .getPublicUrl(fileName);

        fileUrls.add(publicUrl);
        fileNames.add(fileName);
        originalNames.add(originalName);

        debugPrint('✅ Pitch deck file uploaded: $fileName');
      }

      return {
        'file_urls': fileUrls,
        'file_names': fileNames,
        'original_names': originalNames,
        'file_count': files.length,
      };
    } catch (e) {
      debugPrint('❌ Error uploading pitch deck files: $e');
      throw StorageException(
        'Failed to upload pitch deck files: ${e.toString()}',
      );
    }
  }

  /**
   * Deletes an avatar from Supabase storage.
   * 
   * @param fileName The filename of the avatar to delete
   * @throws StorageException if deletion fails
   */
  static Future<void> deleteAvatar({required String fileName}) async {
    try {
      await _supabase.storage.from(avatarsBucket).remove([fileName]);

      debugPrint('✅ Avatar deleted successfully: $fileName');
    } catch (e) {
      debugPrint('❌ Error deleting avatar: $e');
      throw StorageException('Failed to delete avatar: ${e.toString()}');
    }
  }

  /**
   * Deletes multiple pitch deck files from Supabase storage.
   * 
   * @param fileNames List of filenames to delete
   * @throws StorageException if deletion fails
   */
  static Future<void> deletePitchDeckFiles({
    required List<String> fileNames,
  }) async {
    try {
      if (fileNames.isEmpty) return;

      await _supabase.storage.from(pitchDecksBucket).remove(fileNames);

      debugPrint(
        '✅ Pitch deck files deleted successfully: ${fileNames.length} files',
      );
    } catch (e) {
      debugPrint('❌ Error deleting pitch deck files: $e');
      throw StorageException(
        'Failed to delete pitch deck files: ${e.toString()}',
      );
    }
  }

  /**
   * Gets file information from Supabase storage.
   * 
   * @param bucketName The storage bucket name
   * @param fileName The filename to get info for
   * @return File object with metadata or null if not found
   */
  static Future<FileObject?> getFileInfo({
    required String bucketName,
    required String fileName,
  }) async {
    try {
      final files = await _supabase.storage
          .from(bucketName)
          .list(path: path.dirname(fileName));

      return files.firstWhere(
        (file) => file.name == path.basename(fileName),
        orElse: () => throw StorageException('File not found'),
      );
    } catch (e) {
      debugPrint('❌ Error getting file info: $e');
      return null;
    }
  }

  /**
   * Downloads a file from Supabase storage.
   * 
   * @param bucketName The storage bucket name
   * @param fileName The filename to download
   * @return The file contents as bytes
   * @throws StorageException if download fails
   */
  static Future<Uint8List> downloadFile({
    required String bucketName,
    required String fileName,
  }) async {
    try {
      final bytes = await _supabase.storage.from(bucketName).download(fileName);

      debugPrint('✅ File downloaded successfully: $fileName');
      return bytes;
    } catch (e) {
      debugPrint('❌ Error downloading file: $e');
      throw StorageException('Failed to download file: ${e.toString()}');
    }
  }

  /**
   * Lists all files for a user in a specific storage bucket.
   * 
   * @param bucketName The storage bucket name
   * @param userId The user ID to list files for
   * @return List of file objects in the user's folder
   * @throws StorageException if listing fails
   */
  static Future<List<FileObject>> listUserFiles({
    required String bucketName,
    required String userId,
  }) async {
    try {
      final files = await _supabase.storage.from(bucketName).list(path: userId);

      return files;
    } catch (e) {
      debugPrint('❌ Error listing user files: $e');
      throw StorageException('Failed to list user files: ${e.toString()}');
    }
  }

  /**
   * Validates an avatar file for size and type constraints.
   * 
   * @param file The avatar file to validate
   * @throws StorageException if validation fails
   */
  static void validateAvatarFile(File file) {
    // Check if file exists
    if (!file.existsSync()) {
      throw StorageException('Avatar file does not exist');
    }

    // Check file size
    final fileSize = file.lengthSync();
    if (fileSize > maxAvatarSize) {
      throw StorageException(
        'Avatar file too large. Maximum size is ${maxAvatarSize ~/ (1024 * 1024)}MB',
      );
    }

    // Check file extension
    final extension = path
        .extension(file.path)
        .toLowerCase()
        .replaceAll('.', '');
    if (!avatarExtensions.contains(extension)) {
      throw StorageException(
        'Invalid avatar file type. Allowed: ${avatarExtensions.join(', ')}',
      );
    }
  }

  /**
   * Validates a pitch deck file for size and type constraints.
   * 
   * @param file The pitch deck file to validate
   * @throws StorageException if validation fails
   */
  static void validatePitchDeckFile(File file) {
    // Check if file exists
    if (!file.existsSync()) {
      throw StorageException('Pitch deck file does not exist');
    }

    // Check file size
    final fileSize = file.lengthSync();
    if (fileSize > maxPitchDeckSize) {
      throw StorageException(
        'Pitch deck file too large. Maximum size is ${maxPitchDeckSize ~/ (1024 * 1024)}MB',
      );
    }

    // Check file extension
    final extension = path
        .extension(file.path)
        .toLowerCase()
        .replaceAll('.', '');
    if (!pitchDeckExtensions.contains(extension)) {
      throw StorageException(
        'Invalid pitch deck file type. Allowed: ${pitchDeckExtensions.join(', ')}',
      );
    }
  }

  /**
   * Determines the appropriate MIME content type based on file extension.
   * 
   * @param extension The file extension without dot
   * @return The corresponding MIME content type
   */
  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';
      case 'mkv':
        return 'video/x-matroska';
      case 'wmv':
        return 'video/x-ms-wmv';
      default:
        return 'application/octet-stream';
    }
  }

  /**
   * Formats a file size in bytes to a human-readable string.
   * 
   * @param bytes The file size in bytes
   * @return Formatted string with appropriate units (B, KB, MB, GB)
   */
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /**
   * Extracts the filename from a storage URL.
   * 
   * @param url The storage URL
   * @return The extracted filename
   */
  static String extractFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    return path.basename(uri.path);
  }
}

/**
 * StorageException - Custom exception for storage operations.
 * Provides detailed error messages for storage-related failures.
 */
class StorageException implements Exception {
  final String message;

  /**
   * Creates a new storage exception with the specified message.
   * 
   * @param message The error message
   */
  const StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}

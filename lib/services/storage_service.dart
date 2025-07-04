import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Bucket names - make sure these match your Supabase bucket names
  static const String avatarsBucket = 'avatars';
  static const String pitchDecksBucket =
      'pitch-deck-files'; // Updated to match your bucket

  // Maximum file sizes (in bytes)
  static const int maxAvatarSize = 5 * 1024 * 1024; // 5MB
  static const int maxPitchDeckSize = 100 * 1024 * 1024; // 100MB

  // Allowed file extensions
  static const List<String> avatarExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];
  static const List<String> pitchDeckExtensions = [
    'pdf',
    'mp4',
    'avi',
    'mov',
    'mkv',
    'wmv',
  ];

  /// Upload avatar to Supabase storage
  /// Returns the public URL of the uploaded file
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

  /// Upload multiple pitch deck files to Supabase storage
  /// Returns a map with file URLs and names
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

  /// Delete avatar from storage
  static Future<void> deleteAvatar({required String fileName}) async {
    try {
      await _supabase.storage.from(avatarsBucket).remove([fileName]);

      debugPrint('✅ Avatar deleted successfully: $fileName');
    } catch (e) {
      debugPrint('❌ Error deleting avatar: $e');
      throw StorageException('Failed to delete avatar: ${e.toString()}');
    }
  }

  /// Delete pitch deck files from storage
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

  /// Get file info from storage
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

  /// Download file from storage
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

  /// List all files for a user in a specific bucket
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

  /// Validate avatar file (public method)
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

  /// Validate pitch deck file (public method)
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

  /// Get appropriate content type for file extension
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

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Extract filename from storage URL
  static String extractFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    return path.basename(uri.path);
  }
}

/// Custom exception for storage operations
class StorageException implements Exception {
  final String message;

  const StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}

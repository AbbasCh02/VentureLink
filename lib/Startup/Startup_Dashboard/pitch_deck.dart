// lib/Startup/Startup_Dashboard/enhanced_pitch_deck.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:pdfx/pdfx.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../Providers/startup_profile_provider.dart';
import '../services/storage_service.dart';

class PitchDeck extends StatelessWidget {
  final Logger logger = Logger();

  PitchDeck({super.key});

  /// Upload pitch deck files with enhanced error handling and validation
  Future<void> _uploadPitchDeckFiles(BuildContext context) async {
    if (!context.mounted) return;

    final provider = Provider.of<StartupProfileProvider>(
      context,
      listen: false,
    );

    try {
      // Show loading indicator
      if (context.mounted) {
        _showLoadingDialog(context, 'Selecting files...');
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: StorageService.pitchDeckExtensions,
      );

      // Hide loading indicator
      if (context.mounted) Navigator.pop(context);

      if (result != null && context.mounted) {
        // Validate file types and sizes
        List<File> validFiles = [];
        List<String> errors = [];

        for (var platformFile in result.files) {
          try {
            final file = File(platformFile.path!);

            // Validate using our storage service
            StorageService.validatePitchDeckFile(file);
            validFiles.add(file);
          } catch (e) {
            errors.add('${platformFile.name}: ${e.toString()}');
          }
        }

        // Show validation errors if any
        if (errors.isNotEmpty && context.mounted) {
          _showErrorDialog(context, 'File Validation Errors', errors);
        }

        if (validFiles.isNotEmpty && context.mounted) {
          await _processAndUploadFiles(context, validFiles, provider);
        }
      }
    } catch (e) {
      // Hide any open dialogs
      if (context.mounted) Navigator.pop(context);

      logger.e('Error selecting files: $e');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Error selecting files. Please try again.');
      }
    }
  }

  /// Process files and generate thumbnails before upload
  Future<void> _processAndUploadFiles(
    BuildContext context,
    List<File> validFiles,
    StartupProfileProvider provider,
  ) async {
    if (!context.mounted) return;

    try {
      // Show processing indicator
      if (context.mounted) {
        _showLoadingDialog(
          context,
          'Processing ${validFiles.length} file(s)...',
        );
      }

      List<Widget> newThumbnails = [];
      List<File> allFiles = List.from(provider.pitchDeckFiles);

      // Process each file for thumbnails
      for (var file in validFiles) {
        try {
          final extension = file.path.split('.').last.toLowerCase();

          if (extension == 'pdf') {
            final controller = PdfController(
              document: PdfDocument.openFile(file.path),
            );
            // Generate PDF thumbnail
            newThumbnails.add(
              _buildFileCard(context, file, controller: controller),
            );
          } else if (['mp4', 'avi', 'mov', 'mkv', 'wmv'].contains(extension)) {
            final thumbPath = await VideoThumbnail.thumbnailFile(
              video: file.path,
              imageFormat: ImageFormat.PNG,
              maxWidth: 200,
              quality: 75,
            );
            if (!context.mounted) continue;
            newThumbnails.add(
              _buildFileCard(context, file, thumbnailPath: thumbPath),
            );
          } else {
            newThumbnails.add(_buildFileCard(context, file));
          }

          allFiles.add(file);
        } catch (e) {
          logger.e('Error processing file ${file.path}: $e');
          newThumbnails.add(_buildFileCard(context, file));
          allFiles.add(file);
        }
      }

      // Hide processing indicator
      if (context.mounted) Navigator.pop(context);

      // Update provider with all files
      List<Widget> allThumbnails = List.from(provider.pitchDeckThumbnails);
      allThumbnails.addAll(newThumbnails);

      provider.setPitchDeckFiles(allFiles, allThumbnails);

      // Show success message
      if (context.mounted) {
        _showSuccessSnackBar(
          context,
          'Successfully uploaded ${validFiles.length} file(s)! Click "Submit Pitch Deck" when ready.',
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      logger.e('Error processing files: $e');
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Error processing files. Please try again.',
        );
      }
    }
  }

  /// Submit pitch deck files
  Future<void> _submitPitchDeckFiles(BuildContext context) async {
    if (!context.mounted) return;

    final provider = Provider.of<StartupProfileProvider>(
      context,
      listen: false,
    );

    if (provider.pitchDeckFiles.isEmpty) {
      if (context.mounted) {
        _showWarningSnackBar(
          context,
          'Please upload at least one file before submitting.',
        );
      }
      return;
    }

    try {
      // Show submission loading
      if (context.mounted) {
        _showLoadingDialog(
          context,
          'Submitting ${provider.pitchDeckFiles.length} file(s)...',
        );
      }

      // Call provider method to handle submission
      await provider.submitPitchDeckFiles();

      // Hide loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show success message
      if (context.mounted) {
        _showSuccessSnackBar(
          context,
          'Successfully submitted ${provider.pitchDeckFiles.length} file(s)!',
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      logger.e('Error submitting files: $e');
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Failed to submit files. Please try again.',
        );
      }
    }
  }

  /// Delete individual file
  Future<void> _deleteIndividualFile(BuildContext context, File file) async {
    if (!context.mounted) return;

    final provider = Provider.of<StartupProfileProvider>(
      context,
      listen: false,
    );

    // Show confirmation dialog
    if (context.mounted) {
      final confirmed = await _showConfirmationDialog(
        context,
        'Delete File',
        'Are you sure you want to delete "${file.path.split('/').last}"?',
      );

      if (confirmed != true || !context.mounted) return;
    }

    try {
      // Show deletion loading
      if (context.mounted) {
        _showLoadingDialog(context, 'Deleting file...');
      }

      // Call provider method to delete individual file
      await provider.deleteIndividualPitchDeckFile(file);

      // Hide loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show success message
      if (context.mounted) {
        _showSuccessSnackBar(context, 'File deleted successfully!');
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      logger.e('Error deleting file: $e');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to delete file. Please try again.');
      }
    }
  }

  /// Show confirmation dialog
  Future<bool?> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Text(message, style: TextStyle(color: Colors.grey[300])),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  /// Build file card widget for thumbnails with delete button
  Widget _buildFileCard(
    BuildContext context,
    File file, {
    PdfController? controller,
    String? thumbnailPath,
  }) {
    final fileName = file.path.split('/').last;
    final fileSize = StorageService.formatFileSize(file.lengthSync());
    final extension = file.path.split('.').last.toLowerCase();

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail area
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: _buildThumbnailContent(
                  extension,
                  controller,
                  thumbnailPath,
                ),
              ),

              // File info
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fileSize,
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFffa500).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        extension.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFffa500),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Delete button overlay
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _deleteIndividualFile(context, file),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red[600],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build thumbnail content based on file type
  Widget _buildThumbnailContent(
    String extension,
    PdfController? controller,
    String? thumbnailPath,
  ) {
    if (extension == 'pdf' && controller != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: PdfView(
          controller: controller,
          onDocumentLoaded: (document) {},
          onPageChanged: (page) {},
        ),
      );
    } else if (thumbnailPath != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Image.file(
          File(thumbnailPath),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else {
      return Center(
        child: Icon(
          _getFileIcon(extension),
          color: const Color(0xFFffa500),
          size: 40,
        ),
      );
    }
  }

  /// Get appropriate icon for file type
  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
      case 'wmv':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Build styled button
  /// Build styled button
  Widget _buildStyledButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    bool isFullWidth = false,
    bool isSubmitted = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      height: 56,
      decoration: BoxDecoration(
        gradient:
            isSubmitted
                ? LinearGradient(
                  colors: [Colors.green, Colors.green[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : const LinearGradient(
                  colors: [Color(0xFFffa500), Color(0xFFff8c00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                isSubmitted
                    ? Colors.green.withValues(alpha: 0.4)
                    : const Color(0xFFffa500).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSubmitted) ...[
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ] else ...[
                  Icon(icon, color: Colors.black, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  isSubmitted ? 'Submitted Successfully' : text,
                  style: TextStyle(
                    color: isSubmitted ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show loading dialog
  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFFffa500)),
                const SizedBox(height: 16),
                Text(message, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(
    BuildContext context,
    String title,
    List<String> errors,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children:
                    errors
                        .map(
                          (error) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              '• $error',
                              style: TextStyle(color: Colors.red[300]),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Color(0xFFffa500)),
                ),
              ),
            ],
          ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFFffa500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show warning snackbar
  void _showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StartupProfileProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload button (always visible) - not full width
            _buildStyledButton(
              text: 'Upload Files',
              icon: Icons.upload_file,
              onPressed: () => _uploadPitchDeckFiles(context),
              isFullWidth: false, // Changed to false
            ),

            // Only show file-related UI when files exist
            if (provider.pitchDeckFiles.isNotEmpty) ...[
              const SizedBox(height: 16),

              // File count badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      provider.isPitchDeckSubmitted
                          ? Colors.green.withValues(alpha: 0.2)
                          : const Color(0xFFffa500).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        provider.isPitchDeckSubmitted
                            ? Colors.green.withValues(alpha: 0.5)
                            : const Color(0xFFffa500).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  '${provider.pitchDeckFiles.length} files uploaded',
                  style: TextStyle(
                    color:
                        provider.isPitchDeckSubmitted
                            ? Colors.green
                            : const Color(0xFFffa500),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Files list label
              Text(
                'Uploaded Files:',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Files preview container
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: provider.pitchDeckThumbnails),
                ),
              ),

              const SizedBox(height: 16),

              // Submit button (only show when files exist)
              _buildStyledButton(
                text: 'Submit Pitch Deck',
                icon: Icons.send,
                onPressed: () => _submitPitchDeckFiles(context),
                isSubmitted: provider.isPitchDeckSubmitted,
              ),

              // Submission date (only show when submitted)
              if (provider.isPitchDeckSubmitted) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[400],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Submitted on ${provider.pitchDeckSubmissionDate?.toString().split(' ')[0] ?? 'Unknown date'}',
                          style: TextStyle(
                            color: Colors.green[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // Show "no files" message when no files uploaded
            if (provider.pitchDeckFiles.isEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[800]!.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[600]!.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.upload_file, size: 48, color: Colors.grey[500]),
                    const SizedBox(height: 12),
                    Text(
                      'No pitch deck files uploaded yet',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload PDF documents and video files for your pitch deck',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            // Error display
            if (provider.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[400], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.error!,
                        style: TextStyle(color: Colors.red[400]),
                      ),
                    ),
                    TextButton(
                      onPressed: provider.clearError,
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

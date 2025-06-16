// lib/Startup_Dashboard/pitch_deck.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:pdfx/pdfx.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../Providers/startup_profile_provider.dart';

class PitchDeck extends StatelessWidget {
  final Logger logger = Logger();

  PitchDeck({super.key});

  Future<void> _uploadPitchDeckFiles(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: CircularProgressIndicator(color: Color(0xFFffa500)),
            ),
      );

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'mp4', 'avi', 'mov', 'mkv', 'wmv'],
      );

      // Hide loading indicator
      if (context.mounted) Navigator.pop(context);

      if (result != null) {
        final provider = Provider.of<StartupProfileProvider>(
          context,
          listen: false,
        );

        // Validate file types
        List<File> validFiles = [];
        List<String> invalidFiles = [];

        for (var platformFile in result.files) {
          String extension = platformFile.extension?.toLowerCase() ?? '';
          if (['pdf', 'mp4', 'avi', 'mov', 'mkv', 'wmv'].contains(extension)) {
            validFiles.add(File(platformFile.path!));
          } else {
            invalidFiles.add(platformFile.name);
          }
        }

        // Show error for invalid files
        if (invalidFiles.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Invalid file types: ${invalidFiles.join(", ")}. Only PDF and video files are allowed.',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }

        if (validFiles.isNotEmpty) {
          // Show processing indicator
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
                      Text(
                        'Processing ${validFiles.length} file(s)...',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
          );

          // Process files and generate thumbnails
          List<Widget> newThumbnails = [];
          List<File> allFiles = List.from(
            provider.pitchDeckFiles,
          ); // Keep existing files

          for (var file in validFiles) {
            try {
              String extension = file.path.split('.').last.toLowerCase();

              if (extension == 'pdf') {
                // Generate PDF thumbnail
                final controller = PdfController(
                  document: PdfDocument.openFile(file.path),
                );

                newThumbnails.add(
                  _buildFileCard(context, file, controller: controller),
                );
              } else if ([
                'mp4',
                'avi',
                'mov',
                'mkv',
                'wmv',
              ].contains(extension)) {
                // Generate video thumbnail
                final thumbPath = await VideoThumbnail.thumbnailFile(
                  video: file.path,
                  imageFormat: ImageFormat.PNG,
                  maxWidth: 200,
                  quality: 75,
                );

                newThumbnails.add(
                  _buildFileCard(context, file, thumbnailPath: thumbPath),
                );
              }

              allFiles.add(file); // Add to existing files
            } catch (e) {
              logger.e('Error processing file ${file.path}: $e');
              // Add fallback card for failed thumbnails
              newThumbnails.add(_buildFileCard(context, file));
              allFiles.add(file);
            }
          }

          // Hide processing indicator
          if (context.mounted) Navigator.pop(context);

          // Update provider with all files (existing + new)
          List<Widget> allThumbnails = List.from(provider.pitchDeckThumbnails);
          allThumbnails.addAll(newThumbnails);

          provider.setPitchDeckFiles(allFiles, allThumbnails);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully added ${validFiles.length} file(s) to pitch deck!',
                style: const TextStyle(color: Colors.black),
              ),
              backgroundColor: const Color(0xFFffa500),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      // Hide any open dialogs
      if (context.mounted) Navigator.pop(context);

      logger.e('Error uploading files: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Error uploading files. Please try again.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _submitPitchDeckFiles(BuildContext context) async {
    final provider = Provider.of<StartupProfileProvider>(
      context,
      listen: false,
    );

    if (provider.pitchDeckFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please upload at least one file before submitting.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    try {
      // Show submission loading
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
                  Text(
                    'Submitting ${provider.pitchDeckFiles.length} file(s)...',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
      );

      // Call provider method to handle submission
      await provider.submitPitchDeckFiles();

      // Hide loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully submitted ${provider.pitchDeckFiles.length} file(s)!',
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: const Color(0xFFffa500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      // Hide loading dialog
      if (context.mounted) Navigator.pop(context);

      logger.e('Error submitting files: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to submit files. Please try again.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Widget _buildFileCard(
    BuildContext context,
    File file, {
    PdfController? controller,
    String? thumbnailPath,
  }) {
    String fileName = file.path.split('/').last;
    String extension = file.path.split('.').last.toLowerCase();

    return Container(
      width: 120,
      height: 140,
      margin: const EdgeInsets.all(8),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFffa500).withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Thumbnail section
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: _buildThumbnailContent(
                        extension,
                        controller,
                        thumbnailPath,
                      ),
                    ),
                  ),
                ),

                // File info section
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          extension == 'pdf'
                              ? Icons.picture_as_pdf
                              : Icons.videocam,
                          color:
                              extension == 'pdf'
                                  ? Colors.red
                                  : const Color(0xFFffa500),
                          size: 16,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fileName.length > 15
                              ? '${fileName.substring(0, 12)}...'
                              : fileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removePitchDeckFile(context, file),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailContent(
    String extension,
    PdfController? controller,
    String? thumbnailPath,
  ) {
    if (extension == 'pdf' && controller != null) {
      return PdfView(
        controller: controller,
        onDocumentLoaded: (document) {},
        onPageChanged: (page) {},
      );
    } else if (thumbnailPath != null && File(thumbnailPath).existsSync()) {
      return Image.file(
        File(thumbnailPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackThumbnail(extension);
        },
      );
    } else {
      return _buildFallbackThumbnail(extension);
    }
  }

  Widget _buildFallbackThumbnail(String extension) {
    return Container(
      color: Colors.grey[700],
      child: Center(
        child: Icon(
          extension == 'pdf' ? Icons.picture_as_pdf : Icons.videocam,
          color: extension == 'pdf' ? Colors.red : const Color(0xFFffa500),
          size: 40,
        ),
      ),
    );
  }

  void _removePitchDeckFile(BuildContext context, File fileToRemove) {
    final provider = Provider.of<StartupProfileProvider>(
      context,
      listen: false,
    );

    // Find the index of the file to remove
    int fileIndex = provider.pitchDeckFiles.indexWhere(
      (file) => file.path == fileToRemove.path,
    );

    if (fileIndex != -1) {
      // Remove from both lists
      List<File> updatedFiles = List.from(provider.pitchDeckFiles);
      List<Widget> updatedThumbnails = List.from(provider.pitchDeckThumbnails);

      updatedFiles.removeAt(fileIndex);
      updatedThumbnails.removeAt(fileIndex);

      provider.setPitchDeckFiles(updatedFiles, updatedThumbnails);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'File removed successfully!',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: const Color(0xFFffa500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Widget _buildStyledButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFffa500), Color(0xFFff8c00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFffa500).withValues(alpha: 0.4),
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
                if (icon != null) ...[
                  Icon(icon, color: Colors.black, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.black,
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

  Widget _buildSubmitButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isSubmitted = false,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isSubmitted
                  ? [Colors.green[600]!, Colors.green[500]!]
                  : [const Color(0xFF4CAF50), const Color(0xFF45a049)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isSubmitted ? Colors.green : const Color(0xFF4CAF50))
                .withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSubmitted ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    isSubmitted ? Icons.check_circle : icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  isSubmitted ? 'Submitted Successfully' : text,
                  style: const TextStyle(
                    color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Consumer<StartupProfileProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload button
            _buildStyledButton(
              text: 'Upload Files',
              icon: Icons.upload_file,
              onPressed: () => _uploadPitchDeckFiles(context),
              isFullWidth: true,
            ),

            if (provider.pitchDeckFiles.isNotEmpty) ...[
              const SizedBox(height: 16),

              // File count badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFffa500).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFffa500).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  '${provider.pitchDeckFiles.length} files uploaded',
                  style: const TextStyle(
                    color: Color(0xFFffa500),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Files list
              Text(
                'Uploaded Files:',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: provider.pitchDeckThumbnails),
                ),
              ),

              const SizedBox(height: 20),

              // Submit button
              _buildSubmitButton(
                text: 'Submit Pitch Deck',
                icon: Icons.send,
                onPressed: () => _submitPitchDeckFiles(context),
                isSubmitted: provider.isPitchDeckSubmitted,
              ),

              if (provider.isPitchDeckSubmitted) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pitch deck submitted successfully!',
                              style: TextStyle(
                                color: Colors.green[400],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (provider.pitchDeckSubmissionDate != null)
                              Text(
                                'Submitted on ${provider.pitchDeckSubmissionDate!.day}/${provider.pitchDeckSubmissionDate!.month}/${provider.pitchDeckSubmissionDate!.year}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[800]!.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[600]!.withValues(alpha: 0.5),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No files uploaded yet',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
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
          ],
        );
      },
    );
  }
}

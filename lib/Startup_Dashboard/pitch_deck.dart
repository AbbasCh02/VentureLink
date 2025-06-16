// lib/Startup_Dashboard/pitch_deck.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:pdfx/pdfx.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../Providers/startup_profile_provider.dart';

class PitchDeck extends StatefulWidget {
  const PitchDeck({super.key});

  @override
  State<PitchDeck> createState() => _PitchDeckState();
}

class _PitchDeckState extends State<PitchDeck> {
  final Logger logger = Logger();

  Future<void> _uploadPitchDeckFiles(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => const Center(
              child: CircularProgressIndicator(color: Color(0xFFffa500)),
            ),
      );

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'mp4', 'avi', 'mov', 'mkv', 'wmv'],
      );

      // Hide loading indicator
      if (mounted) Navigator.pop(context);

      if (result != null && mounted) {
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
        if (invalidFiles.isNotEmpty && mounted) {
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

        // Process valid files
        if (validFiles.isNotEmpty && mounted) {
          await _processFiles(context, validFiles, provider);
        }
      }
    } catch (e) {
      // Hide any open dialogs
      if (mounted) Navigator.pop(context);

      logger.e('Error uploading files: $e');
      if (mounted) {
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
  }

  Future<void> _processFiles(
    BuildContext context,
    List<File> validFiles,
    StartupProfileProvider provider,
  ) async {
    try {
      // Show processing indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (dialogContext) => AlertDialog(
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
      }

      List<File> allFiles = List.from(provider.pitchDeckFiles);
      List<Widget> newThumbnails = [];

      // Generate thumbnails for each file
      for (File file in validFiles) {
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
          } else if (['mp4', 'avi', 'mov', 'mkv', 'wmv'].contains(extension)) {
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
      if (mounted) Navigator.pop(context);

      // Update provider with all files (existing + new)
      List<Widget> allThumbnails = List.from(provider.pitchDeckThumbnails);
      allThumbnails.addAll(newThumbnails);

      provider.setPitchDeckFiles(allFiles, allThumbnails);

      // Show success message
      if (mounted) {
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
    } catch (e) {
      if (mounted) Navigator.pop(context);
      logger.e('Error processing files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Error processing files. Please try again.',
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
  }

  Future<void> _submitPitchDeckFiles(BuildContext context) async {
    final provider = Provider.of<StartupProfileProvider>(
      context,
      listen: false,
    );

    if (provider.pitchDeckFiles.isEmpty) {
      if (mounted) {
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
      }
      return;
    }

    try {
      // Show submission loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (dialogContext) => AlertDialog(
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
      }

      // Call provider method to handle submission
      provider.submitPitchDeck();

      // Hide loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
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
      }
    } catch (e) {
      // Hide loading dialog
      if (mounted) Navigator.pop(context);

      logger.e('Error submitting files: $e');
      if (mounted) {
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFffa500).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // File thumbnail/icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: extension == 'pdf' ? Colors.red[100] : Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                thumbnailPath != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(thumbnailPath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            extension == 'pdf'
                                ? Icons.picture_as_pdf
                                : Icons.videocam,
                            color:
                                extension == 'pdf' ? Colors.red : Colors.blue,
                            size: 30,
                          );
                        },
                      ),
                    )
                    : Icon(
                      extension == 'pdf'
                          ? Icons.picture_as_pdf
                          : Icons.videocam,
                      color: extension == 'pdf' ? Colors.red : Colors.blue,
                      size: 30,
                    ),
          ),
          const SizedBox(width: 16),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName.length > 25
                      ? '${fileName.substring(0, 22)}...'
                      : fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  extension.toUpperCase(),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),

          // Remove button
          IconButton(
            onPressed: () {
              if (mounted) {
                final provider = Provider.of<StartupProfileProvider>(
                  context,
                  listen: false,
                );
                final index = provider.pitchDeckFiles.indexOf(file);
                if (index != -1) {
                  provider.removePitchDeckFile(index);
                }
              }
            },
            icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isSubmitted,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isSubmitted
                  ? [Colors.green[600]!, Colors.green[500]!]
                  : [const Color(0xFFffa500), const Color(0xFFff8c00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isSubmitted ? Colors.green : const Color(0xFFffa500))
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isSubmitted ? null : onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSubmitted ? Icons.check_circle : icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  isSubmitted ? 'Submitted' : text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Consumer<StartupProfileProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFffa500).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.slideshow,
                        color: Color(0xFFffa500),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pitch Deck',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFffa500),
                            ),
                          ),
                          Text(
                            'Upload your presentation files',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    // Upload button
                    ElevatedButton.icon(
                      onPressed: () => _uploadPitchDeckFiles(context),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Upload'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFffa500),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Files Section
                Expanded(
                  child:
                      provider.pitchDeckFiles.isNotEmpty
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Files header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFffa500,
                                      ).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFffa500,
                                        ).withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.folder,
                                          color: Color(0xFFffa500),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${provider.pitchDeckFiles.length} files uploaded',
                                          style: const TextStyle(
                                            color: Color(0xFFffa500),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Files list
                              Expanded(
                                child: ListView.builder(
                                  itemCount: provider.pitchDeckFiles.length,
                                  itemBuilder: (context, index) {
                                    return _buildFileCard(
                                      context,
                                      provider.pitchDeckFiles[index],
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 24),

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
                                      color: Colors.green.withValues(
                                        alpha: 0.3,
                                      ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Pitch deck submitted successfully!',
                                              style: TextStyle(
                                                color: Colors.green[400],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (provider
                                                    .pitchDeckSubmissionDate !=
                                                null)
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
                            ],
                          )
                          : Center(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(48),
                              decoration: BoxDecoration(
                                color: Colors.grey[800]!.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey[600]!.withValues(
                                    alpha: 0.5,
                                  ),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 64,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No files uploaded yet',
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Upload PDF documents and video files for your pitch deck',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed:
                                        () => _uploadPitchDeckFiles(context),
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('Choose Files'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFffa500),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

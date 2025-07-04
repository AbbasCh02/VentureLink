// lib/widgets/avatar_upload_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../Providers/startup_profile_provider.dart';
import '../../services/storage_service.dart';

class AvatarUploadWidget extends StatelessWidget {
  final double size;
  final bool showEditButton;
  final VoidCallback? onImageChanged;

  const AvatarUploadWidget({
    super.key,
    this.size = 120,
    this.showEditButton = true,
    this.onImageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<StartupProfileProvider>(
      builder: (context, provider, child) {
        return Stack(
          children: [
            // Avatar container
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFffa500), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFffa500).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(child: _buildAvatarContent(provider)),
            ),

            // Edit button
            if (showEditButton)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showImagePickerDialog(context, provider),
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    decoration: BoxDecoration(
                      color: const Color(0xFFffa500),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.black,
                      size: size * 0.12,
                    ),
                  ),
                ),
              ),

            // Loading indicator
            if (provider.isSaving)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFffa500),
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Build avatar content (image or placeholder)
  Widget _buildAvatarContent(StartupProfileProvider provider) {
    if (provider.profileImage != null) {
      // Show local file
      return Image.file(
        provider.profileImage!,
        fit: BoxFit.cover,
        width: size,
        height: size,
      );
    } else if (provider.profileImageUrl != null &&
        provider.profileImageUrl!.isNotEmpty) {
      // Show network image
      return Image.network(
        provider.profileImageUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              color: const Color(0xFFffa500),
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      // Show placeholder
      return _buildPlaceholder();
    }
  }

  /// Build placeholder avatar
  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[800]!, Colors.grey[900]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Icon(Icons.person, color: Colors.grey[400], size: size * 0.5),
    );
  }

  /// Show image picker dialog
  void _showImagePickerDialog(
    BuildContext context,
    StartupProfileProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Update Profile Picture',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Camera option
                      _buildPickerOption(
                        context: context,
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        onTap: () async {
                          Navigator.pop(context);
                          await _pickImage(
                            context,
                            provider,
                            ImageSource.camera,
                          );
                        },
                      ),

                      // Gallery option
                      _buildPickerOption(
                        context: context,
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onTap: () async {
                          Navigator.pop(context);
                          await _pickImage(
                            context,
                            provider,
                            ImageSource.gallery,
                          );
                        },
                      ),

                      // Remove option (if image exists)
                      if (provider.profileImage != null ||
                          (provider.profileImageUrl != null &&
                              provider.profileImageUrl!.isNotEmpty))
                        _buildPickerOption(
                          context: context,
                          icon: Icons.delete,
                          label: 'Remove',
                          color: Colors.red,
                          onTap: () async {
                            Navigator.pop(context);
                            await _removeImage(context, provider);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  /// Build picker option widget
  Widget _buildPickerOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final optionColor = color ?? const Color(0xFFffa500);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: optionColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: optionColor.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: optionColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: optionColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Pick image from camera or gallery
  Future<void> _pickImage(
    BuildContext context,
    StartupProfileProvider provider,
    ImageSource source,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null && context.mounted) {
        final File imageFile = File(pickedFile.path);

        // Validate file using storage service
        try {
          StorageService.validateAvatarFile(imageFile);
        } catch (e) {
          if (context.mounted) {
            _showErrorSnackBar(context, e.toString());
          }
          return;
        }

        // Set the image (this will trigger upload automatically)
        provider.updateProfileImage(imageFile);

        // Call callback if provided
        onImageChanged?.call();

        if (context.mounted) {
          _showSuccessSnackBar(
            context,
            'Profile picture updated successfully!',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to pick image: ${e.toString()}');
      }
    }
  }

  /// Remove current image
  Future<void> _removeImage(
    BuildContext context,
    StartupProfileProvider provider,
  ) async {
    try {
      // Show confirmation dialog
      if (!context.mounted) return;

      final confirmed = await _showConfirmationDialog(
        context,
        'Remove Profile Picture',
        'Are you sure you want to remove your profile picture?',
      );

      if (confirmed == true && context.mounted) {
        // Remove the image (this will trigger database update)
        provider.updateProfileImage(null);

        // Call callback if provided
        onImageChanged?.call();

        if (context.mounted) {
          _showSuccessSnackBar(
            context,
            'Profile picture removed successfully!',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to remove image: ${e.toString()}');
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
                  'Remove',
                  style: TextStyle(color: Colors.red),
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
}

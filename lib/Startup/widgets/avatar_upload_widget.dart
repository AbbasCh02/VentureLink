// lib/widgets/avatar_upload_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../Providers/startup_profile_provider.dart';
import '../../services/storage_service.dart';

/**
 * Implements a comprehensive avatar upload widget for profile image management.
 * Provides complete functionality for uploading, editing, and managing user profile pictures.
 * 
 * Features:
 * - Interactive circular avatar display with professional styling and orange theme (#FFa500)
 * - Multiple image source options (camera and gallery) with modal bottom sheet selection
 * - Real-time image validation using StorageService integration
 * - Automatic upload functionality with progress indicators and loading states
 * - Priority-based image display (local file > network URL > placeholder)
 * - Professional edit button overlay with camera icon and shadow effects
 * - Image removal functionality with confirmation dialogs
 * - Comprehensive error handling with user-friendly feedback notifications
 * - Customizable size and edit button visibility for different use cases
 * - Auto-save integration with StartupProfileProvider for seamless data persistence
 * - Professional gradient placeholder with person icon for empty states
 * - Network image loading with progress indicators and error fallbacks
 * - Responsive design with proportional sizing and shadow effects
 * - Callback integration for parent component notifications on image changes
 */

/**
 * AvatarUploadWidget - Reusable widget component for comprehensive profile image management.
 * Integrates with StartupProfileProvider and StorageService for complete avatar functionality.
 */
class AvatarUploadWidget extends StatelessWidget {
  /**
   * The size of the avatar widget (width and height).
   * Determines the overall dimensions of the circular avatar container.
   */
  final double size;

  /**
   * Whether to show the edit button overlay for image modification.
   * When true, displays a camera icon button for image selection/editing.
   */
  final bool showEditButton;

  /**
   * Optional callback function triggered when the avatar image changes.
   * Called after successful image upload, removal, or update operations.
   */
  final VoidCallback? onImageChanged;

  const AvatarUploadWidget({
    super.key,
    this.size = 120,
    this.showEditButton = true,
    this.onImageChanged,
  });

  /**
   * Builds the main avatar upload widget with provider integration.
   * Uses Consumer pattern to listen to StartupProfileProvider changes and update UI accordingly.
   * 
   * @return Widget containing the complete avatar upload interface
   */
  @override
  Widget build(BuildContext context) {
    return Consumer<StartupProfileProvider>(
      builder: (context, provider, child) {
        return Stack(
          children: [
            // Main avatar container with circular border and shadow effects
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

            // Edit button overlay positioned at bottom-right
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

            // Loading indicator overlay during upload operations
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

  /**
   * Builds avatar content with priority handling for different image sources.
   * Implements priority system: local file > network URL > placeholder.
   * Handles loading states and error fallbacks for network images.
   * 
   * @param provider The StartupProfileProvider instance for image data access
   * @return Widget containing the appropriate avatar content
   */
  Widget _buildAvatarContent(StartupProfileProvider provider) {
    if (provider.profileImage != null) {
      // Display local file (newly selected image with highest priority)
      return Image.file(
        provider.profileImage!,
        fit: BoxFit.cover,
        width: size,
        height: size,
      );
    } else if (provider.profileImageUrl != null &&
        provider.profileImageUrl!.isNotEmpty) {
      // Display network image (loaded from database with progress indicator)
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
      // Display placeholder when no image is available
      return _buildPlaceholder();
    }
  }

  /**
   * Builds the default avatar placeholder with gradient background and person icon.
   * Provides visual cue for users to upload their profile picture.
   * 
   * @return Widget containing the styled avatar placeholder
   */
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

  /**
   * Shows modal bottom sheet with image picker options.
   * Provides camera, gallery, and remove options with professional styling.
   * Dynamically shows remove option only when an image exists.
   * 
   * @param context The BuildContext for modal presentation
   * @param provider The StartupProfileProvider instance for image operations
   */
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
                  // Modal sheet header with drag indicator
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

                  // Image picker options in horizontal layout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Camera option for taking new photos
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

                      // Gallery option for selecting existing photos
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

                      // Remove option (conditionally shown when image exists)
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

  /**
   * Builds individual picker option widgets with consistent styling.
   * Creates circular buttons with icons and labels for different image operations.
   * 
   * @param context The BuildContext for widget building
   * @param icon The icon to display for the option
   * @param label The text label for the option
   * @param onTap The callback function when option is tapped
   * @param color Optional custom color (defaults to orange theme)
   * @return Widget containing the styled picker option
   */
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

  /**
   * Handles image selection from camera or gallery with comprehensive validation.
   * Validates file using StorageService, updates provider, and provides user feedback.
   * Automatically triggers upload and calls optional callback on success.
   * 
   * @param context The BuildContext for error/success feedback
   * @param provider The StartupProfileProvider instance for image operations
   * @param source The ImageSource (camera or gallery) for image selection
   */
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

        // Validate file using storage service before processing
        try {
          StorageService.validateAvatarFile(imageFile);
        } catch (e) {
          if (context.mounted) {
            _showErrorSnackBar(context, e.toString());
          }
          return;
        }

        // Set the image (triggers automatic upload via provider)
        provider.updateProfileImage(imageFile);

        // Execute callback if provided for parent component notification
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

  /**
   * Handles removal of current profile image with confirmation dialog.
   * Shows confirmation dialog, removes image via provider, and provides user feedback.
   * Triggers database update and calls optional callback on successful removal.
   * 
   * @param context The BuildContext for dialog presentation and feedback
   * @param provider The StartupProfileProvider instance for image operations
   */
  Future<void> _removeImage(
    BuildContext context,
    StartupProfileProvider provider,
  ) async {
    try {
      // Show confirmation dialog before removal
      if (!context.mounted) return;

      final confirmed = await _showConfirmationDialog(
        context,
        'Remove Profile Picture',
        'Are you sure you want to remove your profile picture?',
      );

      if (confirmed == true && context.mounted) {
        // Remove the image (triggers database update via provider)
        provider.updateProfileImage(null);

        // Execute callback if provided for parent component notification
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

  /**
   * Shows confirmation dialog for destructive operations.
   * Provides clear warning with custom title and message for user confirmation.
   * 
   * @param context The BuildContext for dialog presentation
   * @param title The dialog title text
   * @param message The confirmation message text
   * @return Future bool? user's confirmation choice (true = confirm, false = cancel)
   */
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

  /**
   * Shows success notification with orange theme styling.
   * Displays floating SnackBar with success message and professional appearance.
   * 
   * @param context The BuildContext for SnackBar presentation
   * @param message The success message to display
   */
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

  /**
   * Shows error notification with red theme styling.
   * Displays floating SnackBar with error message and appropriate warning appearance.
   * 
   * @param context The BuildContext for SnackBar presentation
   * @param message The error message to display
   */
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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import '../Providers/startup_profile_provider.dart';
import 'Business_Model_Canvas/business_model_canvas.dart';
import 'package:venturelink/Startup/Startup_Dashboard/team_members_page.dart';
import 'funding_progress.dart';
import 'package:venturelink/Startup/Startup_Dashboard/profile_overview.dart';
import 'pitch_deck.dart';
import '../../auth/unified_authentication_provider.dart';
import '../../services/storage_service.dart';

/**
 * Implements a comprehensive startup profile management interface for complete entrepreneurial data collection.
 * Provides centralized hub for managing all aspects of a startup profile from idea to funding.
 * 
 * Features:
 * - Complete startup profile management with animated scrollable interface
 * - Interactive profile image selection with validation and auto-save functionality
 * - Comprehensive idea description form with multi-line text support
 * - Seamless navigation to specialized profile sections (overview, pitch deck, business canvas, team)
 * - Integrated funding information collection with real-time validation
 * - Professional authentication management with secure logout functionality
 * - Dynamic form validation with detailed error feedback and user guidance
 * - Responsive design with gradient styling and orange theme (#FFa500)
 * - Advanced error handling with user-friendly notification system
 * - Auto-save capabilities for profile image uploads
 * - Data persistence and callback integration for parent components
 * - Storage service integration for file validation and management
 * - Logger integration for debugging and monitoring profile operations
 */

/**
 * StartupProfilePage - Main profile management widget for comprehensive startup data collection.
 * Integrates all startup profile components into a unified management interface with navigation.
 */
class StartupProfilePage extends StatefulWidget {
  /**
   * Optional callback function to handle data saving operations.
   * Called with funding goal amount and selected funding phase when profile is saved.
   */
  final Function(int?, String?)? onDataSaved;

  const StartupProfilePage({super.key, this.onDataSaved});

  @override
  State<StartupProfilePage> createState() => _StartupProfilePageState();
}

/**
 * _StartupProfilePageState - State management for the comprehensive startup profile interface.
 * Manages form validation, animations, image selection, navigation, and authentication operations.
 */
class _StartupProfilePageState extends State<StartupProfilePage>
    with TickerProviderStateMixin {
  /**
   * Global form key for coordinating validation across all profile form fields.
   */
  final _formKey = GlobalKey<FormState>();

  /**
   * Animation controllers for smooth page transitions and visual feedback.
   */
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  /**
   * Logger instance for debugging and monitoring profile operations.
   */
  final logger = Logger();

  /**
   * Initializes the profile page state with animation controllers and configurations.
   * Sets up fade and slide animations for enhanced user experience.
   */
  @override
  void initState() {
    super.initState();
    // Initialize fade animation controller for opacity transitions
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    // Initialize slide animation controller for position transitions
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Configure fade animation from transparent to opaque
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Configure slide animation from bottom to center with elastic effect
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    // Start animations immediately on page load
    _fadeController.forward();
    _slideController.forward();
  }

  /**
   * Disposes animation controllers to prevent memory leaks.
   */
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /**
   * Handles profile image selection with validation and auto-save functionality.
   * Integrates with ImagePicker for gallery access and StorageService for validation.
   * Provides comprehensive error handling and user feedback through SnackBar notifications.
   */
  Future<void> _pickImage() async {
    final provider = Provider.of<StartupProfileProvider>(
      context,
      listen: false,
    );

    try {
      // Launch image picker with optimized settings for profile photos
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // Validate the selected image file before processing
        try {
          StorageService.validateAvatarFile(imageFile);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid image: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Set the profile image - triggers auto-save functionality
        provider.updateProfileImage(imageFile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /**
   * Handles profile saving with comprehensive validation and user feedback.
   * Validates both form fields and provider state before saving profile data.
   * Provides detailed error messages and success notifications to guide users.
   */
  void _saveProfile() {
    final provider = Provider.of<StartupProfileProvider>(
      context,
      listen: false,
    );

    // Perform dual validation: form validation and provider validation
    bool isFormValid = _formKey.currentState!.validate();
    bool isProviderValid = provider.isProfileComplete;

    if (isFormValid && isProviderValid) {
      final profileData = provider.getProfileData();
      logger.i('Profile Data: $profileData');

      // Execute callback if provided for parent component integration
      if (widget.onDataSaved != null) {
        widget.onDataSaved!(
          provider.fundingGoalAmount,
          provider.selectedFundingPhase,
        );
      }

      // Display success notification with professional styling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Profile saved successfully!',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Navigate back with profile data after showing success message
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context, {
            'fundingGoalAmount': provider.fundingGoalAmount,
            'selectedFundingPhase': provider.selectedFundingPhase,
          });
        }
      });
    } else {
      // Handle validation errors with detailed feedback
      final validationErrors = provider.getValidationErrors();
      String errorMessage = 'Please fix the following issues:';

      if (validationErrors.isNotEmpty) {
        errorMessage += '\n${validationErrors.join('\n')}';
      } else {
        errorMessage = 'Please fill all required fields correctly';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /**
   * Builds reusable section cards with consistent styling and orange theme branding.
   * Provides structured layout for different profile sections with gradient backgrounds.
   * 
   * @param title The section title to display
   * @param child The widget content for the section
   * @return Widget containing the styled section card
   */
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.grey[850]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFffa500).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFffa500),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFffa500),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  /**
   * Builds styled action buttons with gradient backgrounds and interactive effects.
   * Provides consistent button styling across the profile interface.
   * 
   * @param text The button text to display
   * @param onPressed The callback function when button is pressed
   * @param icon Optional icon to display alongside text
   * @param isFullWidth Whether button should span full width
   * @return Widget containing the styled button with gradient and shadow effects
   */
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

  /**
   * Builds styled text form fields with consistent appearance and validation support.
   * Provides professional input styling with orange theme integration.
   * 
   * @param controller The TextEditingController for the field
   * @param labelText The label text for the field
   * @param validator The validation function for input validation
   * @param maxLines Maximum number of lines for text input
   * @param keyboardType The keyboard type for input optimization
   * @return Widget containing the styled text form field
   */
  Widget _buildStyledTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String? Function(String?) validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        cursorColor: const Color(0xFFffa500),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.grey[800]!.withValues(alpha: 0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFffa500), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  /**
   * Builds logout button with red gradient styling for destructive actions.
   * Provides distinct visual styling to indicate logout functionality.
   * 
   * @param text The button text to display
   * @param onPressed The callback function when button is pressed
   * @param icon Optional icon to display alongside text
   * @param isFullWidth Whether button should span full width
   * @return Widget containing the styled logout button with red gradient
   */
  Widget _buildLogoutButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[600]!, Colors.red[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.4),
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
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
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

  /**
   * Handles logout process with confirmation dialog and navigation management.
   * Integrates with UnifiedAuthProvider for secure authentication management.
   * Clears navigation stack and redirects to welcome page after successful logout.
   */
  Future<void> _handleLogout() async {
    // Display confirmation dialog with professional styling
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFffa500),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;
    try {
      // Execute logout through authentication provider
      final authProvider = context.read<UnifiedAuthProvider>();
      await authProvider.signOut();

      // Navigate to welcome page and clear entire navigation stack
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/welcome',
          (route) => false, // Clears the entire navigation stack
        );
      }
    } catch (e) {
      // Display error notification if logout fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /**
   * Builds the main profile page interface with all sections and navigation.
   * Integrates Consumer pattern for real-time provider updates and animated scrolling.
   * 
   * @return Widget containing the complete startup profile management interface
   */
  @override
  Widget build(BuildContext context) {
    return Consumer<StartupProfileProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0a0a0a),
          body: CustomScrollView(
            slivers: [
              // Expandable app bar with gradient background
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.grey[900],
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Startup Profile',
                    style: TextStyle(
                      color: Color(0xFFffa500),
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[900]!, Colors.black],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Profile Image Selection Section
                            Container(
                              margin: const EdgeInsets.only(bottom: 32),
                              child: Center(
                                child: Consumer<StartupProfileProvider>(
                                  builder: (context, provider, child) {
                                    return GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        width: 140,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFffa500),
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFffa500,
                                              ).withValues(alpha: 0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: _buildProfileImageContent(
                                            provider,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Idea Description Section
                            _buildSectionCard(
                              title: 'Idea Description',
                              child: _buildStyledTextFormField(
                                controller: provider.ideaDescriptionController,
                                labelText: 'Describe your innovative idea',
                                maxLines: 4,
                                validator: provider.validateIdeaDescription,
                              ),
                            ),

                            // Profile Overview Navigation Section
                            _buildSectionCard(
                              title: 'Profile Overview',
                              child: _buildStyledButton(
                                text: 'Add Profile Overview',
                                icon: Icons.person_outline,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const ProfileOverview(),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Pitch Deck Management Section
                            _buildSectionCard(
                              title: 'Pitch Deck',
                              child: PitchDeck(),
                            ),

                            // Business Canvas Navigation Section
                            _buildSectionCard(
                              title: 'Business Canvas',
                              child: _buildStyledButton(
                                text: 'Create Business Canvas',
                                icon: Icons.business_center_outlined,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => BusinessModelCanvas(),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Team Members Navigation Section
                            _buildSectionCard(
                              title: 'Team Members',
                              child: _buildStyledButton(
                                text: 'Add Team Members',
                                icon: Icons.group_outlined,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const TeamMembersPage(),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Funding Information Section with integrated widget
                            _buildSectionCard(
                              title: 'Funding Information',
                              child: const Funding(),
                            ),

                            const SizedBox(height: 32),

                            // Save Profile Action Button
                            _buildStyledButton(
                              text: 'Save Profile',
                              icon: Icons.save_outlined,
                              isFullWidth: true,
                              onPressed: _saveProfile,
                            ),

                            const SizedBox(height: 24),

                            // Logout Action Button
                            _buildLogoutButton(
                              text: 'Logout',
                              icon: Icons.logout,
                              isFullWidth: true,
                              onPressed: _handleLogout,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/**
 * Builds profile image content with priority handling for different image sources.
 * Handles local files, network URLs, and fallback to default placeholder with loading states.
 * 
 * @param provider The StartupProfileProvider instance for image data access
 * @return Widget containing the profile image or default placeholder
 */
Widget _buildProfileImageContent(StartupProfileProvider provider) {
  // Priority handling: Local file > Network URL > Placeholder
  if (provider.profileImage != null) {
    // Display local file (newly selected image)
    return Image.file(
      provider.profileImage!,
      fit: BoxFit.cover,
      width: 140,
      height: 140,
    );
  } else if (provider.profileImageUrl != null &&
      provider.profileImageUrl!.isNotEmpty) {
    // Display network image (loaded from database)
    return Image.network(
      provider.profileImageUrl!,
      fit: BoxFit.cover,
      width: 140,
      height: 140,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value:
                loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
            color: const Color(0xFFffa500),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildProfileImagePlaceholder();
      },
    );
  } else {
    // Display placeholder when no image is available
    return _buildProfileImagePlaceholder();
  }
}

/**
 * Builds the default profile image placeholder with gradient background and upload icon.
 * Provides visual cue for users to upload their profile photo.
 * 
 * @return Widget containing the styled profile image placeholder
 */
Widget _buildProfileImagePlaceholder() {
  return Container(
    width: 140,
    height: 140,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.grey[800]!, Colors.grey[900]!],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: const Icon(
      Icons.add_a_photo_outlined,
      size: 40,
      color: Color(0xFFffa500),
    ),
  );
}

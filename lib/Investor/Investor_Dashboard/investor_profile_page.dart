// lib/Investor/investor_profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:venturelink/Investor/Investor_Dashboard/investor_bio.dart';
import '../Providers/investor_profile_provider.dart';
import '../../auth/unified_authentication_provider.dart';
import '../../services/storage_service.dart';
import 'investor_preference_page.dart';

/**
 * investor_profile_page.dart
 * 
 * Implements a comprehensive profile management interface for investors to update
 * their personal information, professional details, and investment preferences.
 * 
 * Features:
 * - Profile image upload and management
 * - Personal information editing (name, age, location)
 * - Navigation to Bio and Investment Preferences screens
 * - Profile completeness validation
 * - Form validation with error feedback
 * - Animated UI transitions
 * - User authentication management (logout)
 * - Integration with multiple providers for data persistence
 */

/**
 * InvestorProfilePage - Main stateful widget for the investor profile management.
 * Allows investors to view and edit their complete profile information.
 */
class InvestorProfilePage extends StatefulWidget {
  /**
   * Optional callback function that triggers when profile is updated.
   * Passes updated portfolio size and other relevant information.
   */
  final Function(int?, String?)? onProfileUpdate;

  const InvestorProfilePage({super.key, this.onProfileUpdate});

  @override
  State<InvestorProfilePage> createState() => _InvestorProfilePageState();
}

/**
 * State class for InvestorProfilePage that manages animations,
 * form validation, and integration with providers.
 */
class _InvestorProfilePageState extends State<InvestorProfilePage>
    with TickerProviderStateMixin {
  final Logger _logger = Logger();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  /**
   * Initializes state, sets up animations and initializes provider.
   */
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeProvider();
  }

  /**
   * Sets up fade and slide animations for UI elements.
   */
  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  /**
   * Initializes the investor profile provider if not already initialized.
   * Handles errors with snackbar notifications.
   */
  void _initializeProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final provider = context.read<InvestorProfileProvider>();
        if (!provider.isInitialized) {
          await provider.initialize();
        }
      } catch (e) {
        _logger.e('Failed to initialize investor profile: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  /**
   * Cleans up animation controllers when widget is removed.
   */
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /**
   * Handles the profile image selection from gallery.
   * Validates, processes, and updates the image with error handling.
   */
  Future<void> _pickImage() async {
    final provider = Provider.of<InvestorProfileProvider>(
      context,
      listen: false,
    );

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // Validate the file first
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

        // Set the profile image - this will trigger auto-save
        provider.updateProfileImage(imageFile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Color(0xFF65c6f4),
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
   * Validates and saves the profile information.
   * Checks for completeness and displays specific errors for missing fields.
   * Triggers callback on successful save.
   */
  Future<void> _saveProfile() async {
    try {
      final provider = context.read<InvestorProfileProvider>();

      // Validate form
      if (_formKey.currentState?.validate() != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fix the validation errors'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if profile is complete
      if (!provider.isProfileComplete) {
        // Show specific validation errors - INCLUDING full name
        List<String> missingFields = [];

        // Check Full Name (was missing before)
        if (provider.fullName == null || provider.fullName!.trim().isEmpty) {
          missingFields.add('Full Name');
        }

        // Check Professional Bio
        if (provider.bio == null || provider.bio!.trim().isEmpty) {
          missingFields.add('Professional Bio');
        }

        // Check Preferred Industries
        if (provider.selectedIndustries.isEmpty) {
          missingFields.add('Preferred Industries');
        }

        // Check Geographic Focus
        if (provider.selectedGeographicFocus.isEmpty) {
          missingFields.add('Geographic Focus');
        }

        // Only show error if there are actually missing fields
        if (missingFields.isNotEmpty) {
          String errorMessage =
              'Please complete the following fields:\n• ${missingFields.join('\n• ')}';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
      }

      // Save profile
      await provider.saveProfile();

      // Call callback if provided
      widget.onProfileUpdate?.call(
        provider.portfolioSize,
        null, // No longer passing company name since it's in companies table
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _logger.e('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /**
   * Handles user logout with confirmation dialog.
   * Signs out and redirects to welcome page on confirmation.
   */
  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1a1a1a),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Get auth provider and sign out
      final authProvider = context.read<UnifiedAuthProvider>();
      await authProvider.signOut();

      // Navigate to the welcome page and clear all routes
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/welcome',
          (route) => false, // This clears the entire navigation stack
        );
      }
    } catch (e) {
      // Show error if still mounted
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
   * Builds the main widget structure with sections.
   */
  @override
  Widget build(BuildContext context) {
    return Consumer<InvestorProfileProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0a0a0a),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.grey[900],
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Investor Profile',
                    style: TextStyle(
                      color: Color(0xFF65c6f4),
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
                            // Profile Image Section
                            Container(
                              margin: const EdgeInsets.only(bottom: 32),
                              child: Center(
                                child: Consumer<InvestorProfileProvider>(
                                  builder: (context, provider, child) {
                                    return GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        width: 140,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF65c6f4),
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF65c6f4,
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

                            const SizedBox(height: 32),

                            // Professional Bio Section
                            _buildSectionCard(
                              title: 'Professional Bio',
                              child: _buildStyledButton(
                                text: 'Add Bio',
                                icon: Icons.add,
                                isFullWidth: true,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const InvestorBio(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Personal Info Section
                            _buildSectionCard(
                              title: 'Personal Info',
                              child: Column(
                                children: [
                                  _buildActualFullNameField(provider),
                                  const SizedBox(height: 20),
                                  _buildAgeSelector(provider),
                                  const SizedBox(height: 20),
                                  _buildCountryField(provider),
                                ],
                              ),
                            ),

                            // Investment Preferences Section
                            const SizedBox(height: 24),
                            _buildInvestmentPreferencesCard(provider),

                            const SizedBox(height: 32),

                            // Save Button
                            _buildStyledButton(
                              text: 'Save Profile',
                              icon: Icons.save_outlined,
                              isFullWidth: true,
                              onPressed: _saveProfile,
                            ),

                            const SizedBox(height: 24),

                            // Logout Button
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

  /**
   * Builds the age selector field with validation.
   * 
   * @param provider The InvestorProfileProvider for state access
   * @return A form field for age input
   */
  Widget _buildAgeSelector(InvestorProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue:
              provider.age?.toString() ??
              '', // FIXED: Use age instead of portfolioSize
          keyboardType: TextInputType.number,
          cursorColor: const Color(0xFF65c6f4),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Enter your age',
            labelStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            hintText: 'e.g., 28',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
            prefixIcon: const Icon(
              Icons.cake,
              color: Color(0xFF65c6f4),
              size: 20,
            ),
            filled: true,
            fillColor: Colors.grey[800]!.withAlpha(204),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF65c6f4), width: 2),
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
          validator: provider.validateAge,
          onChanged: (value) {
            final age = int.tryParse(value);
            provider.updateAge(age); // This will save automatically
          },
        ),
      ],
    );
  }

  /**
   * Builds the country/origin field with validation.
   * 
   * @param provider The InvestorProfileProvider for state access
   * @return A form field for country/origin input
   */
  Widget _buildCountryField(InvestorProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Place of Residence',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller:
                provider
                    .originController, // CRITICAL: Use the correct controller
            keyboardType: TextInputType.text,
            cursorColor: const Color(0xFF65c6f4),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Enter your location',
              labelStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              hintText: 'e.g., New York, USA',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              prefixIcon: const Icon(
                Icons.location_on,
                color: Color(0xFF65c6f4),
                size: 20,
              ),
              filled: true,
              fillColor: Colors.grey[800]!.withAlpha(204),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF65c6f4),
                  width: 2,
                ),
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
            validator: provider.validateorigin,
          ),
        ),
      ],
    );
  }

  /**
   * Builds the full name field with validation.
   * 
   * @param provider The InvestorProfileProvider for state access
   * @return A form field for full name input
   */
  Widget _buildActualFullNameField(InvestorProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Full Name',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller:
                provider
                    .fullNameController, // CRITICAL: Use the correct controller
            keyboardType: TextInputType.text,
            cursorColor: const Color(0xFF65c6f4),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Enter your full name',
              labelStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              hintText: 'e.g., John Doe',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              prefixIcon: const Icon(
                Icons.person,
                color: Color(0xFF65c6f4),
                size: 20,
              ),
              filled: true,
              fillColor: Colors.grey[800]!.withAlpha(204),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF65c6f4),
                  width: 2,
                ),
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
            validator:
                provider.validateFullName, // Use the provider's validation
          ),
        ),
      ],
    );
  }

  /**
   * Determines and builds the appropriate profile image content.
   * Prioritizes local file > network image > placeholder.
   * 
   * @param provider The InvestorProfileProvider for state access
   * @return A widget displaying the appropriate profile image
   */
  Widget _buildProfileImageContent(InvestorProfileProvider provider) {
    // Priority: Local file > Network URL > Placeholder
    if (provider.profileImage != null) {
      // Show local file (newly picked)
      return Image.file(
        provider.profileImage!,
        fit: BoxFit.cover,
        width: 140,
        height: 140,
      );
    } else if (provider.profileImageUrl != null &&
        provider.profileImageUrl!.isNotEmpty) {
      // Show network image (loaded from database)
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
              color: const Color(0xFF65c6f4),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildProfileImagePlaceholder();
        },
      );
    } else {
      // Show placeholder
      return _buildProfileImagePlaceholder();
    }
  }

  /**
   * Creates a placeholder for when no profile image is available.
   * 
   * @return A styled image placeholder widget
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
        color: Color(0xFF65c6f4),
      ),
    );
  }

  /**
   * Creates a styled section card with title and content.
   * 
   * @param title The section title
   * @param child The content widget to display
   * @return A styled container with title and content
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
          color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
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
                    color: const Color(0xFF65c6f4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF65c6f4),
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
   * Creates a styled button with gradient background and icon.
   * 
   * @param text The button text
   * @param icon The icon to display
   * @param onPressed Callback when button is pressed
   * @param isFullWidth Whether the button should fill its parent width
   * @return A styled button widget
   */
  Widget _buildStyledButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF65c6f4), Color(0xFF2476C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.black, size: 20),
                const SizedBox(width: 8),
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
   * Creates a styled logout button with red gradient background.
   * 
   * @param text The button text
   * @param onPressed Callback when button is pressed
   * @param icon Optional icon to display
   * @param isFullWidth Whether the button should fill its parent width
   * @return A styled logout button widget
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
   * Builds the investment preferences card with summary and navigation.
   * 
   * @param provider The InvestorProfileProvider for state access
   * @return A section card with investment preferences information
   */
  Widget _buildInvestmentPreferencesCard(InvestorProfileProvider provider) {
    final selectedCount =
        provider.selectedIndustries.length +
        provider.selectedGeographicFocus.length +
        provider.selectedPreferredStages.length;

    return _buildSectionCard(
      title: 'Investment Preferences',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and action button row
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedCount > 0
                      ? '$selectedCount preferences configured'
                      : 'Set your preferred industries, regions, and investment stages to help startups find you',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[300],
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF65c6f4), Color(0xFF2476C9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      // Navigate to preferences page
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InvestorPreferencesPage(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selectedCount > 0 ? Icons.edit : Icons.add,
                            size: 16,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedCount > 0 ? 'Edit' : 'Set Up',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Show summary if preferences are set
          if (selectedCount > 0) ...[
            const SizedBox(height: 20),
            _buildPreferencesSummary(provider),
          ],

          // Show empty state if no preferences
          if (selectedCount == 0) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800]!.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.tune, color: Colors.grey[400], size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'No preferences set',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "Set Up" to configure your investment preferences',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /**
   * Builds a summary of all investment preferences.
   * Displays industries, geographic regions, and investment stages.
   * 
   * @param provider The InvestorProfileProvider for state access
   * @return A widget with organized preference categories
   */
  Widget _buildPreferencesSummary(InvestorProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Industries Section
        if (provider.selectedIndustries.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.business_center, color: Colors.grey[500], size: 16),
              const SizedBox(width: 8),
              Text(
                'Industries (${provider.selectedIndustries.length}):',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children:
                provider.selectedIndustries.map((industry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF65c6f4).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      industry,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF65c6f4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(), // REMOVED .take(3) and "+X more" logic
          ),
          const SizedBox(height: 12),
        ],

        // Geographic Focus Section
        if (provider.selectedGeographicFocus.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.public, color: Colors.grey[500], size: 16),
              const SizedBox(width: 8),
              Text(
                'Regions (${provider.selectedGeographicFocus.length}):',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children:
                provider.selectedGeographicFocus.map((region) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      region,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.lightBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(), // REMOVED .take(3) and "+X more" logic
          ),
          const SizedBox(height: 12),
        ],

        // Investment Stages Section
        if (provider.selectedPreferredStages.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.grey[500], size: 16),
              const SizedBox(width: 8),
              Text(
                'Investment Stages (${provider.selectedPreferredStages.length}):',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children:
                provider.selectedPreferredStages.map((stage) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      stage,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.lightGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(), // REMOVED .take(3) and "+X more" logic
          ),
        ],
      ],
    );
  }
}

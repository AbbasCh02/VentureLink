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

class InvestorProfilePage extends StatefulWidget {
  final Function(int?, String?)? onProfileUpdate;

  const InvestorProfilePage({super.key, this.onProfileUpdate});

  @override
  State<InvestorProfilePage> createState() => _InvestorProfilePageState();
}

class _InvestorProfilePageState extends State<InvestorProfilePage>
    with TickerProviderStateMixin {
  final Logger _logger = Logger();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeProvider();
  }

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

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Profile image picking with enhanced source selection
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

  // Save profile
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
        // Show specific validation errors
        List<String> missingFields = [];
        if (provider.bio == null) missingFields.add('Professional Bio');
        if (provider.companyName == null) missingFields.add('Company Name');
        if (provider.title == null) missingFields.add('Job Title');
        if (provider.selectedIndustries.isEmpty) {
          missingFields.add('Preferred Industries');
        }
        if (provider.selectedGeographicFocus.isEmpty) {
          missingFields.add('Geographic Focus');
        }

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

      // Save profile
      await provider.saveProfile();

      // Call callback if provided
      widget.onProfileUpdate?.call(
        provider.portfolioSize,
        provider.companyName,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
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

  // Handle logout
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

                            // Investment Preferences Section
                            _buildSectionCard(
                              title: 'Investment Preferences',
                              child: Column(
                                children: [
                                  _buildStyledTextFormField(
                                    controller: provider.companyNameController,
                                    labelText: 'Preferred Industries',
                                    validator: provider.validateCompanyName,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildStyledTextFormField(
                                    controller: provider.titleController,
                                    labelText: 'Geographic Focus',
                                    validator: provider.validateTitle,
                                  ),
                                ],
                              ),
                            ),

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
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        cursorColor: const Color(0xFF65c6f4),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.grey[800]!.withAlpha(204), // same as 0.8
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
        validator: validator,
      ),
    );
  }

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
}

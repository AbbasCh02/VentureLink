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
import '../Providers/startup_authentication_provider.dart';
import '../../homepage.dart';

class StartupProfilePage extends StatefulWidget {
  final Function(int?, String?)? onDataSaved;

  const StartupProfilePage({super.key, this.onDataSaved});

  @override
  State<StartupProfilePage> createState() => _StartupProfilePageState();
}

class _StartupProfilePageState extends State<StartupProfilePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final logger = Logger();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final provider = Provider.of<StartupProfileProvider>(
      context,
      listen: false,
    );
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      provider.setProfileImage(File(pickedFile.path));
    }
  }

  void _saveProfile() {
    final provider = Provider.of<StartupProfileProvider>(
      context,
      listen: false,
    );

    // Use both form validation and provider validation
    bool isFormValid = _formKey.currentState!.validate();
    bool isProviderValid = provider.isProfileValid();

    if (isFormValid && isProviderValid) {
      final profileData = provider.getProfileData();
      logger.i('Profile Data: $profileData');

      // Call the callback if provided
      if (widget.onDataSaved != null) {
        widget.onDataSaved!(
          provider.fundingGoalAmount,
          provider.selectedFundingPhase,
        );
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Profile saved successfully!',
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

      // Wait a moment for the snackbar to show, then return the data
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context, {
            'fundingGoalAmount': provider.fundingGoalAmount,
            'selectedFundingPhase': provider.selectedFundingPhase,
          });
        }
      });
    } else {
      // Show specific validation errors
      final validationErrors = provider.getValidationErrors();
      String errorMessage = 'Please fix the following issues:';

      if (validationErrors.isNotEmpty) {
        errorMessage += '\n${validationErrors.values.join('\n')}';
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

  // Add this method to your _StartupProfilePageState class in startup_profile_page.dart

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

  // Add this method to your _StartupProfilePageState class in startup_profile_page.dart

  Future<void> _handleLogout() async {
    // Show confirmation dialog
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
      // Get auth provider and sign out
      final authProvider = context.read<StartupAuthProvider>();
      await authProvider.signOut();

      // Navigate to the home page (first page) if still mounted
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
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
    return Consumer<StartupProfileProvider>(
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
                            // Profile Image Section
                            Container(
                              margin: const EdgeInsets.only(bottom: 32),
                              child: Center(
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient:
                                          provider.profileImage == null
                                              ? LinearGradient(
                                                colors: [
                                                  Colors.grey[800]!,
                                                  Colors.grey[700]!,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                              : null,
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
                                    child:
                                        provider.profileImage != null
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(70),
                                              child: Image.file(
                                                provider.profileImage!,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                            : const Icon(
                                              Icons.add_a_photo_outlined,
                                              size: 40,
                                              color: Color(0xFFffa500),
                                            ),
                                  ),
                                ),
                              ),
                            ),

                            // Idea Description
                            _buildSectionCard(
                              title: 'Idea Description',
                              child: _buildStyledTextFormField(
                                controller: provider.ideaDescriptionController,
                                labelText: 'Describe your innovative idea',
                                maxLines: 4,
                                validator: provider.validateIdeaDescription,
                              ),
                            ),

                            // Profile Overview
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

                            // Pitch Deck - Now using the separate widget consistently
                            _buildSectionCard(
                              title: 'Pitch Deck',
                              child: PitchDeck(),
                            ),

                            // Business Canvas
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

                            // Team Members
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

                            // Funding Section - Now using simplified widget
                            _buildSectionCard(
                              title: 'Funding Information',
                              child: const Funding(),
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
}

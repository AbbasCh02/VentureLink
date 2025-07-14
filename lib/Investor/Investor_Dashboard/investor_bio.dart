/**
 * investor_bio.dart
 * 
 * Implements a form-based interface for investors to create and edit their
 * professional bio, portfolio information, and LinkedIn profile.
 * 
 * Features:
 * - Animated UI with entrance effects
 * - Form validation
 * - Styled input fields and sections
 * - Integration with InvestorProfileProvider for state management
 * - Navigation to company management page
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:venturelink/Investor/Investor_Dashboard/investor_company_page.dart';
import '../Providers/investor_profile_provider.dart';

/**
 * InvestorBio - Main stateful widget for the investor bio page.
 * Allows investors to enter and update their professional information.
 */
class InvestorBio extends StatefulWidget {
  const InvestorBio({super.key});

  @override
  State<InvestorBio> createState() => _InvestorBioState();
}

/**
 * State class for InvestorBio that manages animations and form state.
 */
class _InvestorBioState extends State<InvestorBio>
    with TickerProviderStateMixin {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  /**
   * Initializes state and sets up animations.
   */
  @override
  void initState() {
    super.initState();
    // Initialize fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    // Initialize slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Create slide animation with elastic bounce effect
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
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
   * Builds the main widget structure with form and sections.
   */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: _buildAppBar(),
      body: Consumer<InvestorProfileProvider>(
        builder: (context, provider, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _buildHeader(provider),
                      const SizedBox(height: 32),

                      // Professional Bio Section
                      _buildBioSection(provider),
                      const SizedBox(height: 24),

                      // Company Information Section
                      _buildCompanyInfoSection(provider),
                      const SizedBox(height: 24),

                      // Portfolio Information Section
                      _buildPortfolioSection(provider),
                      const SizedBox(height: 24),

                      // Save Button
                      _buildSaveButton(provider),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /**
   * Builds the app bar with back button and title.
   * 
   * @return A styled AppBar widget
   */
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.grey[900],
      elevation: 0,
      title: const Text(
        'Professional Bio',
        style: TextStyle(
          color: Color(0xFF65c6f4),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF65c6f4).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF65c6f4)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /**
   * Builds the header section with title and description.
   * 
   * @param provider The InvestorProfileProvider for state access
   * @return A styled header widget
   */
  Widget _buildHeader(InvestorProfileProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF65c6f4), Color(0xFF2476C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle, color: Colors.black, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Professional Bio',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            provider.isProfileComplete
                ? 'Your professional profile is complete. Update any information as needed.'
                : 'Complete your professional bio to showcase your expertise and attract quality startups.',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /**
   * Creates a styled button with gradient background, icon and text.
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
   * Builds the professional bio input section.
   * 
   * @param provider The InvestorProfileProvider for form state
   * @return A section card with bio text field
   */
  Widget _buildBioSection(InvestorProfileProvider provider) {
    return _buildSectionCard(
      title: 'Professional Bio',
      child: _buildStyledTextFormField(
        controller: provider.bioController,
        labelText: 'Tell us about yourself',
        maxLines: 6,
        validator: provider.validateBio,
      ),
    );
  }

  /**
   * Builds the company information section with an "Add Companies" button.
   * 
   * @param provider The InvestorProfileProvider for state
   * @return A section card with company management button
   */
  Widget _buildCompanyInfoSection(InvestorProfileProvider provider) {
    return _buildSectionCard(
      title: 'Companies Information',
      child: Column(
        children: [
          _buildStyledButton(
            text: 'Add Companies',
            icon: Icons.add_business,
            isFullWidth: true,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InvestorCompanyPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /**
   * Builds the portfolio information section with portfolio size and LinkedIn inputs.
   * 
   * @param provider The InvestorProfileProvider for state
   * @return A section card with portfolio fields
   */
  Widget _buildPortfolioSection(InvestorProfileProvider provider) {
    return _buildSectionCard(
      title: 'Portfolio Information',
      child: Column(
        children: [
          _buildPortfolioSizeSelector(provider),
          const SizedBox(height: 20),
          _buildLinkedInProfileSelector(provider),
        ],
      ),
    );
  }

  /**
   * Builds the LinkedIn profile URL input field with validation.
   * 
   * @param provider The InvestorProfileProvider for state
   * @return A form field for LinkedIn URL input
   */
  Widget _buildLinkedInProfileSelector(InvestorProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LinkedIn Profile',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: provider.linkedinUrl ?? '',
          keyboardType: TextInputType.url,
          cursorColor: const Color(0xFF65c6f4),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Enter your LinkedIn profile URL',
            labelStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            hintText: 'https://linkedin.com/in/username',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
            prefixIcon: const Icon(
              Icons.link,
              color: Color(0xFF65c6f4),
              size: 20,
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return null; // LinkedIn is optional
            }

            final trimmedValue = value.trim();

            // Check if it's a valid URL
            final Uri? uri = Uri.tryParse(trimmedValue);
            if (uri == null) {
              return 'Please enter a valid URL';
            }

            // Check if it's a LinkedIn URL
            if (!trimmedValue.toLowerCase().contains('linkedin.com')) {
              return 'Please enter a valid LinkedIn URL';
            }

            // Check for valid scheme
            if (uri.scheme != 'http' && uri.scheme != 'https') {
              return 'URL must start with http:// or https://';
            }

            return null;
          },
          onChanged: (value) {
            provider.updateLinkedinUrl(value.trim());
          },
        ),
      ],
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
   * Creates a styled text form field with validation.
   * 
   * @param controller The text controller
   * @param labelText The field label
   * @param validator The validation function
   * @param maxLines Number of lines for text input
   * @param keyboardType The keyboard type to display
   * @return A styled text input field
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

  /**
   * Builds the portfolio size input field with numeric validation.
   * 
   * @param provider The InvestorProfileProvider for state
   * @return A form field for portfolio size input
   */
  Widget _buildPortfolioSizeSelector(InvestorProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portfolio Size',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: provider.portfolioSize?.toString() ?? '',
          keyboardType: TextInputType.number,
          cursorColor: const Color(0xFF65c6f4),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            labelText: 'How Many Investments Done',
            labelStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.numbers,
              color: Color(0xFF65c6f4),
              size: 20,
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the number of companies in your portfolio';
            }
            final number = int.tryParse(value);
            if (number == null) {
              return 'Please enter a valid number';
            }
            if (number < 0) {
              return 'Portfolio size cannot be negative';
            }
            if (number > 1000) {
              return 'Portfolio size seems too large. Please verify.';
            }
            return null;
          },
          onChanged: (value) {
            final number = int.tryParse(value);
            if (number != null) {
              provider.updatePortfolioSize(number);
            }
          },
        ),
      ],
    );
  }

  /**
   * Builds the save button with gradient styling.
   * 
   * @param provider The InvestorProfileProvider for state
   * @return A styled save button widget
   */
  Widget _buildSaveButton(InvestorProfileProvider provider) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF65c6f4), Color(0xFF2476C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        onPressed: _saveBio,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_outlined, size: 20),
            SizedBox(width: 8),
            Text(
              'Save Professional Bio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /**
   * Handles the save action with validation, persistence, and feedback.
   */
  Future<void> _saveBio() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final provider = context.read<InvestorProfileProvider>();
      await provider.saveProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Professional bio saved successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to save bio: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

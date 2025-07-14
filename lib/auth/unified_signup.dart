// ignore_for_file: dangling_library_doc_comments, slash_for_doc_comments

/**
 * unified_signup.dart
 * 
 * Implements a polished signup screen with animations, form validation,
 * user type selection (startup/investor), and account creation flow.
 * 
 * Features:
 * - Animated entrance effects (fade, slide)
 * - Dynamic color transitions between startup/investor themes
 * - User type selection with visual feedback
 * - Password strength indicator
 * - Real-time form validation
 * - Smart routing to appropriate dashboard after signup
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'unified_authentication_provider.dart';
import 'unified_login.dart';

/**
 * UnifiedSignupPage - Stateful widget that provides the signup interface.
 * Uses TickerProviderStateMixin for animations.
 */
class UnifiedSignupPage extends StatefulWidget {
  const UnifiedSignupPage({super.key});

  @override
  State<UnifiedSignupPage> createState() => _UnifiedSignupPageState();
}

class _UnifiedSignupPageState extends State<UnifiedSignupPage>
    with TickerProviderStateMixin {
  // Animation controllers for various visual effects
  late AnimationController _fadeController; // Controls fade-in animation
  late AnimationController _slideController; // Controls slide-up animation
  late AnimationController _pulseController; // Controls pulsing effect
  late AnimationController _colorController; // Controls color transitions

  // Animation objects linked to controllers
  late Animation<double> _fadeAnimation; // Fade effect from 0 to 1
  late Animation<Offset> _slideAnimation; // Slide from below
  late Animation<double> _pulseAnimation; // Subtle size pulsing
  late Animation<Color?> _colorAnimation; // Color cycling animation

  /**
   * Initializes the page state, sets up animations, and configures the
   * authentication provider form type to signup mode.
   */
  @override
  void initState() {
    super.initState();
    _setupAnimations();

    // Set the form type to signup when this page loads
    // Uses a post-frame callback to ensure the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<UnifiedAuthProvider>(
        context,
        listen: false,
      );
      authProvider.setFormType(FormType.signup);
      debugPrint('🔍 Signup page initialized - form type set to signup');
    });
  }

  /**
   * Sets up all animations used in the signup screen.
   * Configures controllers, curves, and animation parameters.
   */
  void _setupAnimations() {
    // Initialize animation controllers with their durations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Create fade animation (opacity 0->1)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Create slide animation (moves content up from below)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Create pulse animation (subtle size change)
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Create color animation (cycles between orange and blue)
    _colorAnimation = ColorTween(
      begin: const Color(0xFFffa500), // Orange (startup color)
      end: const Color(0xFF65c6f4), // Blue (investor color)
    ).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward(); // Run once (fade in)
    _slideController.forward(); // Run once (slide up)
    _pulseController.repeat(reverse: true); // Continuously pulse
    _colorController.repeat(reverse: true); // Continuously cycle colors
  }

  /**
   * Disposes of animation controllers to prevent memory leaks.
   */
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  /**
   * Helper method to get the current theme color based on user type selection.
   * Returns a static color for selected user type, or the animated color.
   * 
   * @return The appropriate Color to use for theming
   */
  Color _getCurrentThemeColor() {
    final authProvider = Provider.of<UnifiedAuthProvider>(
      context,
      listen: false,
    );
    if (authProvider.selectedUserType == UserType.startup) {
      return const Color(0xFFffa500); // Orange for startup
    } else if (authProvider.selectedUserType == UserType.investor) {
      return const Color(0xFF65c6f4); // Blue for investor
    } else {
      // Default to animated color when no selection
      return _colorAnimation.value ?? const Color(0xFFffa500);
    }
  }

  /**
   * Builds the main widget structure with background, animations, and content.
   */
  @override
  Widget build(BuildContext context) {
    // Main scaffold with dark background
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Stack(
        children: [
          // Background gradient decoration
          _buildBackgroundDecoration(),

          // Main content with animations
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 2.0,
                  ),
                  child: Column(
                    children: [
                      // Back button at the top left
                      _buildBackButton(),

                      // App logo with pulsing effect
                      _buildLogo(),
                      const SizedBox(height: 5),

                      // Page header text
                      _buildHeader(),
                      const SizedBox(height: 20),

                      // Main signup form
                      _buildSignupForm(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /**
   * Creates a back button in the top-left corner for navigation.
   */
  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!, width: 1),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white70,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /**
   * Builds the animated app logo with dynamic glow effects.
   * Adapts colors based on user type selection.
   */
  Widget _buildLogo() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, _) {
        return AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _colorAnimation]),
          builder: (context, __) {
            // Determine current color (static for selection or animated)
            final currentColor =
                authProvider.selectedUserType != null
                    ? _getCurrentThemeColor() // Static color based on selection
                    : (_colorAnimation.value ??
                        const Color(0xFFffa500)); // Animated color

            // Logo with subtle pulsing and color-themed glow
            return ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 140,
                height: 140,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF222222), Color(0xFF111111)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  // Border and glow use the current theme color
                  border: Border.all(color: currentColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: currentColor.withValues(alpha: 0.3),
                      blurRadius: 35,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/VentureLink LogoAlone 2.0.png',
                    fit: BoxFit.contain,
                    errorBuilder:
                        (_, __, ___) => Icon(
                          Icons.business_center,
                          size: 55,
                          color: currentColor,
                        ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /**
   * Creates the radial gradient background.
   */
  Widget _buildBackgroundDecoration() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [Color(0xFF1a1a1a), Color(0xFF0a0a0a)], // Dark gradient
        ),
      ),
    );
  }

  /**
   * Builds the page header with color-themed text.
   * Adapts colors based on user type selection.
   */
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Consumer<UnifiedAuthProvider>(
          builder: (context, authProvider, child) {
            // Color handling based on user selection
            if (authProvider.selectedUserType != null) {
              // Static colored text when user type is selected
              final currentColor = _getCurrentThemeColor();
              return Text(
                'Join VentureLink',
                style: TextStyle(
                  color: currentColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: currentColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              );
            }

            // Animated colored text when no selection
            return AnimatedBuilder(
              animation: _colorAnimation,
              builder: (context, child) {
                final animatedColor =
                    _colorAnimation.value ?? const Color(0xFFffa500);
                return Text(
                  'Join VentureLink',
                  style: TextStyle(
                    color: animatedColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: animatedColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 4),
        // Subtitle
        Text(
          'Connect with the startup ecosystem',
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /**
   * Builds the complete signup form with all fields and validation.
   * Includes user type selection, name, email, password fields, and buttons.
   */
  Widget _buildSignupForm() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        return Form(
          key: authProvider.signupFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Type Selection (Startup or Investor)
              _buildCompactUserTypeSelector(),
              const SizedBox(height: 12),

              // Full Name Field
              _buildInputField(
                label: "Full Name",
                controller: authProvider.nameController,
                focusNode: authProvider.nameFocusNode,
                validator: authProvider.validateFullName,
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                errorText: authProvider.nameError,
              ),
              const SizedBox(height: 5),

              // Email Field
              _buildInputField(
                label: "Email",
                controller: authProvider.emailController,
                focusNode: authProvider.emailFocusNode,
                validator: authProvider.validateEmail,
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email_outlined,
                errorText: authProvider.emailError,
              ),
              const SizedBox(height: 5),

              // Password Field
              _buildInputField(
                label: "Password",
                controller: authProvider.passwordController,
                focusNode: authProvider.passwordFocusNode,
                validator: authProvider.validatePassword,
                isPassword: true,
                icon: Icons.lock_outline,
                errorText: authProvider.passwordError,
              ),

              // Password Strength Indicator
              _buildPasswordStrengthIndicator(),
              const SizedBox(height: 5),

              // Confirm Password Field
              _buildInputField(
                label: "Confirm Password",
                controller: authProvider.confirmPasswordController,
                focusNode: authProvider.confirmPasswordFocusNode,
                validator:
                    (value) => authProvider.validateConfirmPassword(
                      authProvider.password,
                      value,
                    ),
                isPassword: true,
                icon: Icons.lock_outline,
                errorText: authProvider.confirmPasswordError,
              ),
              const SizedBox(height: 15),

              // Sign Up Button
              _buildSignUpButton(),
              const SizedBox(height: 12),

              // Error Message (conditionally shown)
              if (authProvider.error != null) _buildErrorMessage(),

              // Login Link (for existing users)
              _buildLoginLink(),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  /**
   * Builds the user type selection section with startup and investor options.
   * Shows error message if no type selected but form is submitted.
   */
  Widget _buildCompactUserTypeSelector() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with two user type options
            Row(
              children: [
                // Startup option
                Expanded(
                  child: _buildCompactUserTypeCard(
                    userType: UserType.startup,
                    title: 'Startup',
                    icon: Icons.rocket_launch,
                    color: const Color(0xFFffa500), // Orange
                    isSelected:
                        authProvider.selectedUserType == UserType.startup,
                    onTap: () {
                      authProvider.setUserType(UserType.startup);
                      authProvider.clearError();
                      setState(() {}); // Refresh UI for color updates
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Investor option
                Expanded(
                  child: _buildCompactUserTypeCard(
                    userType: UserType.investor,
                    title: 'Investor',
                    icon: Icons.account_balance,
                    color: const Color(0xFF65c6f4), // Blue
                    isSelected:
                        authProvider.selectedUserType == UserType.investor,
                    onTap: () {
                      authProvider.setUserType(UserType.investor);
                      authProvider.clearError();
                      setState(() {}); // Refresh UI for color updates
                    },
                  ),
                ),
              ],
            ),

            // Error message if no user type selected
            if (authProvider.selectedUserType == null &&
                authProvider.error != null) ...[
              const SizedBox(height: 6),
              Text(
                'Please select whether you are a startup or investor',
                style: const TextStyle(color: Colors.red, fontSize: 11),
              ),
            ],
          ],
        );
      },
    );
  }

  /**
   * Builds a user type selection card with appropriate styling.
   * Shows selection state with color and visual effects.
   * 
   * @param userType The UserType represented by this card
   * @param title The display text for the card
   * @param icon The icon to display
   * @param color The theme color for this user type
   * @param isSelected Whether this type is currently selected
   * @param onTap Callback when card is tapped
   */
  Widget _buildCompactUserTypeCard({
    required UserType userType,
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          // Change background color when selected
          color:
              isSelected
                  ? color.withValues(alpha: 0.1)
                  : const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(10),
          // Highlight border when selected
          border: Border.all(
            color: isSelected ? color : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
          // Add glow effect when selected
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey[400], size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[300],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /**
   * Builds a form input field with validation and theme-colored styling.
   * Adapts to password fields with visibility toggle.
   * 
   * @param label The field label
   * @param controller The text controller
   * @param focusNode The focus node
   * @param validator The validation function
   * @param keyboardType The keyboard type
   * @param icon The leading icon
   * @param isPassword Whether this is a password field
   * @param errorText The error text to display
   */
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    bool isPassword = false,
    String? errorText,
  }) {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        final hasError = errorText != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Field label
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),

            // Animated field with dynamic colors
            AnimatedBuilder(
              animation: _colorAnimation,
              builder: (context, child) {
                // Get current theme color based on selection or animation
                Color currentColor;
                if (authProvider.selectedUserType != null) {
                  currentColor = _getCurrentThemeColor(); // Static color
                } else {
                  currentColor =
                      _colorAnimation.value ??
                      const Color(0xFFffa500); // Animated
                }

                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  validator: validator,
                  keyboardType: keyboardType,
                  // Handle password visibility toggling
                  obscureText:
                      isPassword &&
                      (label.contains('Confirm')
                          ? !authProvider.isConfirmPasswordVisible
                          : !authProvider.isPasswordVisible),
                  style: const TextStyle(color: Colors.white),
                  cursorColor: hasError ? Colors.red : currentColor,

                  // Real-time validation
                  onChanged: (value) {
                    if (authProvider.validateRealTime) {
                      authProvider.validateForm();
                    }
                  },

                  // Field styling and decoration
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    // Field icon
                    prefixIcon:
                        icon != null
                            ? Icon(
                              icon,
                              color: hasError ? Colors.red : Colors.grey[400],
                              size: 18,
                            )
                            : null,
                    // Toggle visibility icon for password fields
                    suffixIcon:
                        isPassword
                            ? IconButton(
                              icon: Icon(
                                label.contains('Confirm')
                                    ? (authProvider.isConfirmPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility)
                                    : (authProvider.isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility),
                                color: Colors.grey[400],
                                size: 18,
                              ),
                              onPressed:
                                  label.contains('Confirm')
                                      ? authProvider
                                          .toggleConfirmPasswordVisibility
                                      : authProvider.togglePasswordVisibility,
                            )
                            : null,
                    hintText: 'Enter your ${label.toLowerCase()}',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF1a1a1a),

                    // Border styling with color theming
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: hasError ? Colors.red : Colors.grey[800]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: hasError ? Colors.red : Colors.grey[800]!,
                      ),
                    ),
                    // Highlight with theme color when focused
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: hasError ? Colors.red : currentColor,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                );
              },
            ),

            // Error message display
            if (hasError) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  errorText,
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /**
   * Visual indicator for password strength with color and text feedback.
   * Shows strength level based on password complexity.
   */
  Widget _buildPasswordStrengthIndicator() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        final password = authProvider.password;
        final strength = _calculatePasswordStrength(password);
        final currentColor = _getCurrentThemeColor();

        // Set color and text based on password strength
        Color color;
        String text;
        switch (strength) {
          case PasswordStrength.weak:
            color = Colors.red;
            text = 'Weak';
            break;
          case PasswordStrength.medium:
            color = Colors.orange;
            text = 'Medium';
            break;
          case PasswordStrength.strong:
            color = currentColor; // Use theme color for strong passwords
            text = 'Strong';
            break;
          default:
            color = Colors.grey;
            text = '';
        }

        if (password.isEmpty) return const SizedBox.shrink();

        // Strength bar with appropriate width and color
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.grey[800],
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        // Width based on strength
                        widthFactor:
                            strength == PasswordStrength.weak
                                ? 0.3
                                : strength == PasswordStrength.medium
                                ? 0.6
                                : 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /**
   * Calculates password strength based on length and character diversity.
   * 
   * @param password The password to evaluate
   * @return PasswordStrength enum value (weak, medium, strong)
   */
  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.length < 6) return PasswordStrength.weak;
    if (password.length < 8) return PasswordStrength.medium;

    // Check for different character types
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    // Calculate score based on character variety
    int score = 0;
    if (hasUpper) score++;
    if (hasLower) score++;
    if (hasDigit) score++;
    if (hasSpecial) score++;

    // Determine strength based on score and length
    if (score >= 3 && password.length >= 8) return PasswordStrength.strong;
    if (score >= 2) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  /**
   * Builds the sign-up button with theme-colored styling.
   * Shows loading indicator during authentication.
   */
  Widget _buildSignUpButton() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        // Static color when user type selected
        if (authProvider.selectedUserType != null) {
          final currentColor = _getCurrentThemeColor();
          return SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: authProvider.isAuthenticating ? null : _handleSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: currentColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child:
                  authProvider.isAuthenticating
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            authProvider.selectedUserType == UserType.startup
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          );
        }

        // Animated color when no selection
        return AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            final animatedColor =
                _colorAnimation.value ?? const Color(0xFFffa500);
            return SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: authProvider.isAuthenticating ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: animatedColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child:
                    authProvider.isAuthenticating
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                        : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            );
          },
        );
      },
    );
  }

  /**
  * Builds the error message container with dismiss option.
  * Displayed when authentication errors occur.
  */
  Widget _buildErrorMessage() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  authProvider.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                onPressed: authProvider.clearError,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        );
      },
    );
  }

  /**
  * Builds the "Already have an account" link to login page.
  * Uses theme colors for the link text.
  */
  Widget _buildLoginLink() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!, width: 1),
        ),
        child: TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const UnifiedLoginPage()),
            );
          },
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Consumer<UnifiedAuthProvider>(
            builder: (context, authProvider, child) {
              // Static colored text for selected user type
              if (authProvider.selectedUserType != null) {
                final currentColor = _getCurrentThemeColor();
                return RichText(
                  text: TextSpan(
                    text: "Already have an account? ",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    children: [
                      TextSpan(
                        text: "Sign In",
                        style: TextStyle(
                          color: currentColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          shadows: [
                            Shadow(
                              color: currentColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Animated colored text when no selection
              return AnimatedBuilder(
                animation: _colorAnimation,
                builder: (context, child) {
                  final animatedColor =
                      _colorAnimation.value ?? const Color(0xFFffa500);
                  return RichText(
                    text: TextSpan(
                      text: "Already have an account? ",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: "Sign In",
                          style: TextStyle(
                            color: animatedColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            shadows: [
                              Shadow(
                                color: animatedColor.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /**
  * Handles the signup process when the form is submitted.
  * Validates input, attempts signup, and navigates to the appropriate
  * dashboard on success.
  */
  Future<void> _handleSignUp() async {
    final authProvider = Provider.of<UnifiedAuthProvider>(
      context,
      listen: false,
    );

    // Enable real-time validation for immediate feedback
    authProvider.enableRealTimeValidation();

    // Attempt signup
    final success = await authProvider.signUp();

    if (success && mounted) {
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Welcome to VentureLink! Redirecting to your dashboard...',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to appropriate dashboard based on user type
      final user = authProvider.currentUser;
      if (user != null) {
        debugPrint('🚀 Navigating to ${user.userType.name} dashboard');

        switch (user.userType) {
          case UserType.startup:
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/startup-dashboard',
                (route) => false, // Clear navigation stack
              );
            }
            break;
          case UserType.investor:
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/investor-dashboard',
                (route) => false, // Clear navigation stack
              );
            }
            break;
        }
      }
    } else if (!success && mounted) {
      // Show error snackbar if signup failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  authProvider.error ?? 'Signup failed. Please try again.',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

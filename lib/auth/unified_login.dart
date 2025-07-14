/**
 * unified_login_page.dart
 * 
 * Implements a polished login screen with animations, form validation,
 * and authentication flow for the application.
 * 
 * Features:
 * - Animated entrance effects (fade, slide)
 * - Dynamic color transitions between startup/investor themes
 * - Real-time form validation
 * - Remember me functionality
 * - User type detection for appropriate routing
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/unified_authentication_provider.dart';
import 'unified_signup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/**
 * UnifiedLoginPage - Stateful widget that provides the login interface.
 * Uses TickerProviderStateMixin for animations.
 */
class UnifiedLoginPage extends StatefulWidget {
  const UnifiedLoginPage({super.key});

  @override
  State<UnifiedLoginPage> createState() => _UnifiedLoginPageState();
}

class _UnifiedLoginPageState extends State<UnifiedLoginPage>
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
   * authentication provider form type to login mode.
   */
  @override
  void initState() {
    super.initState();
    _setupAnimations();

    // Set the form type to login when this page loads
    // Using post-frame callback to ensure widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<UnifiedAuthProvider>(
        context,
        listen: false,
      );
      authProvider.setFormType(FormType.login);
      debugPrint('🔍 Login page initialized - form type set to login');
    });
  }

  /**
   * Sets up all animations used in the login screen.
   * Configures controllers, curves, and animation parameters.
   */
  void _setupAnimations() {
    // Create animation controllers with specified durations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Configure fade animation (0.0 to 1.0 opacity)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Configure slide animation (moves content up from below)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Configure pulse animation (subtle size change effect)
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Configure color animation (cycles between orange and blue)
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
   * Builds the main widget structure with background, animations, and content.
   */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Stack(
        children: [
          // Background with grid pattern
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
                      // Back navigation button
                      _buildBackButton(),
                      const SizedBox(height: 12),

                      // App logo and welcome text
                      _buildLogoSection(),
                      const SizedBox(height: 28),

                      // Login form with fields
                      _buildLoginForm(),
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
   * Creates the background with gradient and subtle grid pattern.
   * Uses a CustomPainter for the grid lines.
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
      // Add subtle grid pattern using custom painter
      child: CustomPaint(
        painter: BackgroundPatternPainter(),
        size: Size.infinite,
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
   * Builds the logo section with animations, glow effects, and welcome text.
   */
  Widget _buildLogoSection() {
    return Column(
      children: [
        // Animated logo with glow effect and pulsing
        AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            final currentColor =
                _colorAnimation.value ?? const Color(0xFFffa500);
            return ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 160,
                height: 160,
                padding: const EdgeInsets.all(12),
                // Container styling with gradient and glow
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey[900]!,
                      Colors.grey[850]!,
                      Colors.grey[800]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: currentColor, width: 2),
                  // Multiple shadow layers for depth and glow effect
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 0),
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: currentColor.withValues(alpha: 0.3),
                      blurRadius: 35,
                      offset: const Offset(0, 0),
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                // App logo
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/VentureLink LogoAlone 2.0.png',
                    width: 106,
                    height: 106,
                    fit: BoxFit.contain,
                    // Fallback icon if image fails to load
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.business_center,
                        size: 55,
                        color: Color(0xFFffa500),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // "Welcome Back" text with animated color
        AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            final currentColor =
                _colorAnimation.value ?? const Color(0xFFffa500);
            return Text(
              'Welcome Back',
              style: TextStyle(
                color: currentColor,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                // Text shadow for glow effect
                shadows: [
                  Shadow(
                    color: currentColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),

        // Subtitle text
        Text(
          'Sign in to continue your journey',
          style: TextStyle(color: Colors.grey[400], fontSize: 15),
        ),
      ],
    );
  }

  /**
   * Builds the login form with email, password fields, and buttons.
   * Uses the authentication provider for form state and validation.
   */
  Widget _buildLoginForm() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        return Form(
          key: authProvider.loginFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 10),

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
              const SizedBox(height: 10),

              // Remember Me checkbox and Forgot Password link
              _buildRememberMeAndForgotPassword(),
              const SizedBox(height: 18),

              // Sign In Button
              _buildSignInButton(),
              const SizedBox(height: 16),

              // Error Message (shown conditionally)
              if (authProvider.error != null) _buildErrorMessage(),

              // Sign Up Link for new users
              _buildSignUpLink(),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  /**
   * Builds a styled input field with validation, animated colors,
   * and custom error display.
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
        // Check if this field has a validation error
        bool hasError = errorText != null && errorText.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Field label
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),

            // Input field with animated color accents
            AnimatedBuilder(
              animation: _colorAnimation,
              builder: (context, child) {
                final currentColor =
                    _colorAnimation.value ?? const Color(0xFFffa500);
                return Container(
                  // Subtle shadow for depth
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    cursorColor: currentColor, // Animated cursor color
                    controller: controller,
                    focusNode: focusNode,
                    validator: validator,
                    keyboardType: keyboardType,
                    // Handle password visibility
                    obscureText: isPassword && !authProvider.isPasswordVisible,
                    // Real-time validation
                    onChanged: (value) {
                      if (authProvider.validateRealTime) {
                        authProvider.validateForm();
                      }
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    // Field styling and decoration
                    decoration: InputDecoration(
                      // Leading icon
                      prefixIcon:
                          icon != null
                              ? Container(
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  icon,
                                  color:
                                      hasError ? Colors.red : Colors.grey[400],
                                  size: 20,
                                ),
                              )
                              : null,
                      // Password visibility toggle icon
                      suffixIcon:
                          isPassword
                              ? IconButton(
                                icon: Icon(
                                  authProvider.isPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color:
                                      hasError ? Colors.red : Colors.grey[400],
                                  size: 20,
                                ),
                                onPressed:
                                    authProvider.togglePasswordVisibility,
                              )
                              : null,
                      hintText: 'Enter your ${label.toLowerCase()}',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1a1a1a),

                      // Border styling based on validation state
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: hasError ? Colors.red : Colors.grey[800]!,
                          width: hasError ? 2 : 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: hasError ? Colors.red : Colors.grey[800]!,
                          width: hasError ? 2 : 1,
                        ),
                      ),
                      // Theme-colored focus border
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: hasError ? Colors.red : currentColor,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),

                      // Hide default error text since we show custom version below
                      errorText: null,
                    ),
                  ),
                );
              },
            ),

            // Custom error message display
            if (hasError) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorText,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  /**
   * Builds the "Remember Me" checkbox and "Forgot Password" link row.
   * Uses animated colors for interactive elements.
   */
  Widget _buildRememberMeAndForgotPassword() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Remember Me checkbox with animated colors
            Row(
              children: [
                AnimatedBuilder(
                  animation: _colorAnimation,
                  builder: (context, child) {
                    final currentColor =
                        _colorAnimation.value ?? const Color(0xFFffa500);
                    return SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: authProvider.rememberMe,
                        onChanged:
                            (value) =>
                                authProvider.setRememberMe(value ?? false),
                        activeColor: currentColor, // Animated checkbox color
                        checkColor: Colors.black,
                        side: BorderSide(
                          color: currentColor.withValues(alpha: 0.7),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                Text(
                  'Remember me',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Forgot Password link with animated color
            TextButton(
              onPressed: _handleForgotPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              ),
              child: AnimatedBuilder(
                animation: _colorAnimation,
                builder: (context, child) {
                  final currentColor =
                      _colorAnimation.value ?? const Color(0xFFffa500);
                  return Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: currentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: currentColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /**
   * Builds a gradient sign-in button with animation and loading state.
   * Uses dynamic color animation for the gradient.
   */
  Widget _buildSignInButton() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        return AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            // Create gradient colors based on animation
            final currentColor =
                _colorAnimation.value ?? const Color(0xFFffa500);
            final lightShade =
                Color.lerp(currentColor, Colors.white, 0.1) ?? currentColor;
            final darkShade =
                Color.lerp(currentColor, Colors.black, 0.2) ?? currentColor;

            return Container(
              width: double.infinity,
              height: 56,
              // Gradient container with glow effect
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [lightShade, currentColor, darkShade],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: currentColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: currentColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: authProvider.isAuthenticating ? null : _handleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.transparent, // Use container's gradient
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                // Show loading indicator or button content
                child:
                    authProvider.isAuthenticating
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.login,
                              color: Colors.black,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
              ),
            );
          },
        );
      },
    );
  }

  /**
   * Builds an error message container for displaying auth errors.
   * Includes a dismiss button to clear the error.
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  authProvider.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
              // Close button to dismiss error
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
   * Builds the "Sign Up" link for new users with animated colors.
   */
  Widget _buildSignUpLink() {
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
            // Navigate to signup page
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const UnifiedSignupPage(),
              ),
            );
          },
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          // Animated colored text
          child: AnimatedBuilder(
            animation: _colorAnimation,
            builder: (context, child) {
              final currentColor =
                  _colorAnimation.value ?? const Color(0xFFffa500);
              return RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  children: [
                    TextSpan(
                      text: "Sign Up",
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
            },
          ),
        ),
      ),
    );
  }

  /**
   * Handles the sign-in process, including validation and user type detection.
   * Routes to the appropriate dashboard based on user type after successful login.
   */
  Future<void> _handleSignIn() async {
    final authProvider = context.read<UnifiedAuthProvider>();

    // Validate form first
    if (!authProvider.loginFormKey.currentState!.validate()) return;

    final email = authProvider.emailController.text.trim();
    final password = authProvider.passwordController.text.trim();

    try {
      // Check which user type this email belongs to (startup or investor)
      final userType = await _checkUserType(email);

      if (userType == null && mounted) {
        // Email not found in either table
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email not found. Please check your email or sign up.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Proceed with authentication
      final success = await authProvider.signIn(
        email: email,
        password: password,
        rememberMe: authProvider.rememberMe,
      );

      if (success && mounted) {
        // Navigate to appropriate dashboard based on user type
        if (userType == 'investor') {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/investor-dashboard', (route) => false);
        } else if (userType == 'startup') {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/startup-dashboard', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /**
   * Checks which database table contains the user's email.
   * Used to determine the user type (startup or investor).
   * 
   * @param email The email to check
   * @return String representing user type ('investor' or 'startup') or null if not found
   */
  Future<String?> _checkUserType(String email) async {
    try {
      final supabase = Supabase.instance.client;

      // Check investors table first
      final investorResult =
          await supabase
              .from('investors')
              .select('email')
              .eq('email', email)
              .maybeSingle();

      if (investorResult != null) {
        return 'investor';
      }

      // Check startups table
      final userResult =
          await supabase
              .from('startups')
              .select('email')
              .eq('email', email)
              .maybeSingle();

      if (userResult != null) {
        return 'startup';
      }

      return null; // Email not found in either table
    } catch (e) {
      debugPrint('Error checking user type: $e');
      return null;
    }
  }

  /**
   * Handles the "Forgot Password" functionality.
   * Currently shows a placeholder dialog until functionality is implemented.
   */
  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a1a),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Forgot Password',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Password reset functionality will be available in a future update. Please contact support if you need assistance.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFFffa500),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/**
* CustomPainter implementation that draws a subtle grid pattern background.
* Creates a professional design element with minimal visual weight.
*/
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.02) // Very subtle lines
          ..strokeWidth = 1;

    // Draw a grid of horizontal and vertical lines
    const spacing = 50.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

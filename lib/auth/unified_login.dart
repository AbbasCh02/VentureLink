// lib/auth/unified_login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/unified_authentication_provider.dart';
import 'unified_signup.dart';

class UnifiedLoginPage extends StatefulWidget {
  const UnifiedLoginPage({super.key});

  @override
  State<UnifiedLoginPage> createState() => _UnifiedLoginPageState();
}

class _UnifiedLoginPageState extends State<UnifiedLoginPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _colorController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    // Set the form type to login when this page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<UnifiedAuthProvider>(
        context,
        listen: false,
      );
      authProvider.setFormType(FormType.login);
      debugPrint('🔍 Login page initialized - form type set to login');
    });
  }

  void _setupAnimations() {
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Color animation between orange and blue
    _colorAnimation = ColorTween(
      begin: const Color(0xFFffa500), // Orange
      end: const Color(0xFF65c6f4), // Blue
    ).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
    _colorController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Stack(
        children: [
          _buildBackgroundDecoration(),
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
                      // Back button
                      _buildBackButton(),
                      const SizedBox(height: 12), // Reduced from 20
                      // Logo section
                      _buildLogoSection(),
                      const SizedBox(height: 28), // Reduced from 40
                      // Login form
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

  Widget _buildBackgroundDecoration() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [Color(0xFF1a1a1a), Color(0xFF0a0a0a)],
        ),
      ),
      child: CustomPaint(
        painter: BackgroundPatternPainter(),
        size: Size.infinite,
      ),
    );
  }

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

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Animated logo with glow (bigger size)
        AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            final currentColor =
                _colorAnimation.value ?? const Color(0xFFffa500);
            return ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 160, // Increased from 100
                height: 160, // Increased from 100
                padding: const EdgeInsets.all(12), // Increased from 10
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
                  borderRadius: BorderRadius.circular(28), // Increased from 20
                  border: Border.all(color: currentColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withValues(alpha: 0.5),
                      blurRadius: 20, // Increased from 15
                      offset: const Offset(0, 0),
                      spreadRadius: 3, // Increased from 2
                    ),
                    BoxShadow(
                      color: currentColor.withValues(alpha: 0.3),
                      blurRadius: 35, // Increased from 25
                      offset: const Offset(0, 0),
                      spreadRadius: 5, // Increased from 3
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 15, // Increased from 12
                      offset: const Offset(0, 8), // Increased from 6
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18), // Increased from 12
                  child: Image.asset(
                    'assets/VentureLink LogoAlone 2.0.png',
                    width: 106, // Increased from 80
                    height: 106, // Increased from 80
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.business_center,
                        size: 55, // Increased from 40
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

        // Welcome back text
        AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            final currentColor =
                _colorAnimation.value ?? const Color(0xFFffa500);
            return Text(
              'Welcome Back',
              style: TextStyle(
                color: currentColor,
                fontSize: 26, // Increased from 24
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: currentColor.withValues(alpha: 0.3),
                    blurRadius: 8, // Increased from 6
                    offset: const Offset(0, 2), // Increased from 1
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),

        Text(
          'Sign in to continue your journey',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 15, // Increased from 14
          ),
        ),
      ],
    );
  }

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
              const SizedBox(height: 10), // Reduced from 20
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
              const SizedBox(height: 10), // Reduced from 16
              // Remember Me and Forgot Password Row
              _buildRememberMeAndForgotPassword(),
              const SizedBox(height: 18), // Reduced from 32
              // Sign In Button
              _buildSignInButton(),
              const SizedBox(height: 16), // Reduced from 24
              // Error Message
              if (authProvider.error != null) _buildErrorMessage(),

              // Sign Up Link
              _buildSignUpLink(),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

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
        // Check if there's a validation error for this field
        bool hasError = errorText != null && errorText.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedBuilder(
              animation: _colorAnimation,
              builder: (context, child) {
                final currentColor =
                    _colorAnimation.value ?? const Color(0xFFffa500);
                return Container(
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
                    controller: controller,
                    focusNode: focusNode,
                    validator: validator,
                    keyboardType: keyboardType,
                    obscureText: isPassword && !authProvider.isPasswordVisible,
                    onChanged: (value) {
                      // Trigger real-time validation
                      if (authProvider.validateRealTime) {
                        authProvider.validateForm();
                      }
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
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

                      // CRITICAL: Different borders based on validation state
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

                      // Hide the default error text since we show it below
                      errorText: null,
                    ),
                  ),
                );
              },
            ),

            // Show custom error message below the field
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

  Widget _buildRememberMeAndForgotPassword() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Remember Me Checkbox with animated colors
            Row(
              children: [
                AnimatedBuilder(
                  animation: _colorAnimation,
                  builder: (context, child) {
                    final currentColor =
                        _colorAnimation.value ?? const Color(0xFFffa500);
                    return SizedBox(
                      width: 22, // Slightly smaller
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
                        ), // Animated border
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10), // Reduced from 12
                Text(
                  'Remember me',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 13, // Reduced from 14
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Forgot Password Link
            TextButton(
              onPressed: _handleForgotPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ), // Reduced padding
              ),
              child: AnimatedBuilder(
                animation: _colorAnimation,
                builder: (context, child) {
                  final currentColor =
                      _colorAnimation.value ?? const Color(0xFFffa500);
                  return Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: currentColor, // Animated color
                      fontSize: 13, // Reduced from 14
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

  Widget _buildSignInButton() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        return AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            final currentColor =
                _colorAnimation.value ?? const Color(0xFFffa500);
            final lightShade =
                Color.lerp(currentColor, Colors.white, 0.1) ?? currentColor;
            final darkShade =
                Color.lerp(currentColor, Colors.black, 0.2) ?? currentColor;

            return Container(
              width: double.infinity,
              height: 56,
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
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child:
                    authProvider.isAuthenticating
                        ? const SizedBox(
                          width: 22, // Reduced from 24
                          height: 22, // Reduced from 24
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.login,
                              color: Colors.white,
                              size: 18, // Reduced from 20
                            ),
                            const SizedBox(width: 10), // Reduced from 12
                            const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16, // Reduced from 18
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

  Widget _buildSignUpLink() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 1,
        ), // Reduced padding
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!, width: 1),
        ),
        child: TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const UnifiedSignupPage(),
              ),
            );
          },
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: AnimatedBuilder(
            animation: _colorAnimation,
            builder: (context, child) {
              final currentColor =
                  _colorAnimation.value ?? const Color(0xFFffa500);
              return RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ), // Reduced from 15
                  children: [
                    TextSpan(
                      text: "Sign Up",
                      style: TextStyle(
                        color: currentColor, // Animated color
                        fontWeight: FontWeight.w600,
                        fontSize: 12, // Reduced from 15
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

  Future<void> _handleSignIn() async {
    final authProvider = Provider.of<UnifiedAuthProvider>(
      context,
      listen: false,
    );

    // Enable real-time validation
    authProvider.enableRealTimeValidation();

    // Validate form first
    if (!authProvider.validateForm()) {
      // If validation fails, show errors but don't proceed
      return;
    }

    try {
      final success = await authProvider.signIn();

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Welcome back! Redirecting to your dashboard...',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Get the current user after successful authentication
        final user = authProvider.currentUser;

        if (user != null) {
          debugPrint(
            '🚀 User authenticated: ${user.email} (${user.userType.name})',
          );
          debugPrint('🔄 Routing to ${user.userType.name} dashboard');

          // Navigate to the appropriate dashboard based on user type
          switch (user.userType) {
            case UserType.startup:
              debugPrint('📱 Navigating to StartupDashboard');
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/startup_dashboard',
                (route) => false, // Remove all previous routes
              );
              break;

            case UserType.investor:
              debugPrint('📱 Navigating to InvestorDashboard');
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/investor_dashboard',
                (route) => false, // Remove all previous routes
              );
              break;
          }
        }
      } else if (!success && mounted) {
        // Show error message if sign-in failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    authProvider.error ??
                        'Sign-in failed. Please check your credentials.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      // Handle any unexpected errors
      debugPrint('❌ Unexpected error during sign-in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'An unexpected error occurred. Please try again.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

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

// Custom painter for background pattern
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.02)
          ..strokeWidth = 1;

    // Draw subtle grid pattern
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

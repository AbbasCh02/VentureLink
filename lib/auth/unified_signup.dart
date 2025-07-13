// lib/auth/unified_signup.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'unified_authentication_provider.dart';
import 'unified_login.dart';

class UnifiedSignupPage extends StatefulWidget {
  const UnifiedSignupPage({super.key});

  @override
  State<UnifiedSignupPage> createState() => _UnifiedSignupPageState();
}

class _UnifiedSignupPageState extends State<UnifiedSignupPage>
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

    // Set the form type to signup when this page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<UnifiedAuthProvider>(
        context,
        listen: false,
      );
      authProvider.setFormType(FormType.signup);
      debugPrint('🔍 Signup page initialized - form type set to signup');
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
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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

    // Color animation between orange and blue (will be overridden by user selection)
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

  // Get current theme color based on selected user type
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

                      // Logo
                      _buildLogo(),
                      const SizedBox(height: 5),

                      // Header
                      _buildHeader(),
                      const SizedBox(height: 20),

                      // Signup Form
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

  Widget _buildLogo() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, _) {
        return AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _colorAnimation]),
          builder: (context, __) {
            final currentColor =
                authProvider.selectedUserType != null
                    ? _getCurrentThemeColor() // orange / blue
                    : (_colorAnimation.value ?? const Color(0xFFffa500));

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
                  // ← border & glow now use currentColor
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

  Widget _buildBackgroundDecoration() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [Color(0xFF1a1a1a), Color(0xFF0a0a0a)],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Consumer<UnifiedAuthProvider>(
          builder: (context, authProvider, child) {
            // When user type is selected, show static colored text
            if (authProvider.selectedUserType != null) {
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

            // When no selection, show animated text
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
        Text(
          'Connect with the startup ecosystem',
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        return Form(
          key: authProvider.signupFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Type Selection - Compact Version
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

              // Error Message
              if (authProvider.error != null) _buildErrorMessage(),

              // Login Link
              _buildLoginLink(),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactUserTypeSelector() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact User type buttons
            Row(
              children: [
                // Startup option
                Expanded(
                  child: _buildCompactUserTypeCard(
                    userType: UserType.startup,
                    title: 'Startup',
                    icon: Icons.rocket_launch,
                    color: const Color(0xFFffa500),
                    isSelected:
                        authProvider.selectedUserType == UserType.startup,
                    onTap: () {
                      authProvider.setUserType(UserType.startup);
                      authProvider.clearError();
                      setState(() {}); // Trigger rebuild to update colors
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
                    color: const Color(0xFF65c6f4),
                    isSelected:
                        authProvider.selectedUserType == UserType.investor,
                    onTap: () {
                      authProvider.setUserType(UserType.investor);
                      authProvider.clearError();
                      setState(() {}); // Trigger rebuild to update colors
                    },
                  ),
                ),
              ],
            ),

            // Error text
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
          color:
              isSelected
                  ? color.withValues(alpha: 0.1)
                  : const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
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

  // Complete _buildInputField method with animated colors
  // Replace your existing _buildInputField method with this complete version:

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
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),

            // 🔥 ANIMATED BUILDER FOR DYNAMIC COLORS
            AnimatedBuilder(
              animation: _colorAnimation,
              builder: (context, child) {
                // 🔥 Get current color based on user selection or animation
                Color currentColor;
                if (authProvider.selectedUserType != null) {
                  // User has made a selection - use static color
                  currentColor = _getCurrentThemeColor();
                } else {
                  // No selection - use animated color
                  currentColor =
                      _colorAnimation.value ?? const Color(0xFFffa500);
                }

                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  validator: validator,
                  keyboardType: keyboardType,
                  obscureText:
                      isPassword &&
                      (label.contains('Confirm')
                          ? !authProvider.isConfirmPasswordVisible
                          : !authProvider.isPasswordVisible),
                  style: const TextStyle(color: Colors.white),

                  // 🔥 ADD CURSOR COLOR - animated!
                  cursorColor: hasError ? Colors.red : currentColor,

                  onChanged: (value) {
                    // Trigger real-time validation
                    if (authProvider.validateRealTime) {
                      authProvider.validateForm();
                    }
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    prefixIcon:
                        icon != null
                            ? Icon(
                              icon,
                              color: hasError ? Colors.red : Colors.grey[400],
                              size: 18,
                            )
                            : null,
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

                    // 🔥 UPDATED BORDER COLORS WITH ANIMATION
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color:
                            hasError
                                ? Colors.red
                                : currentColor, // 🔥 ANIMATED COLOR
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

  Widget _buildPasswordStrengthIndicator() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        final password = authProvider.password;
        final strength = _calculatePasswordStrength(password);
        final currentColor = _getCurrentThemeColor();

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
            color = currentColor;
            text = 'Strong';
            break;
          default:
            color = Colors.grey;
            text = '';
        }

        if (password.isEmpty) return const SizedBox.shrink();

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

  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.length < 6) return PasswordStrength.weak;
    if (password.length < 8) return PasswordStrength.medium;

    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int score = 0;
    if (hasUpper) score++;
    if (hasLower) score++;
    if (hasDigit) score++;
    if (hasSpecial) score++;

    if (score >= 3 && password.length >= 8) return PasswordStrength.strong;
    if (score >= 2) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  Widget _buildSignUpButton() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        // Show animated colors when no selection, fixed color when selected
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

        // When no selection, show animated button
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
              // Show animated colors when no selection, fixed color when selected
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

              // When no selection, show animated text
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

  Future<void> _handleSignUp() async {
    final authProvider = Provider.of<UnifiedAuthProvider>(
      context,
      listen: false,
    );

    // Enable real-time validation
    authProvider.enableRealTimeValidation();

    final success = await authProvider.signUp();

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

      // Get the current user type and navigate directly to appropriate dashboard
      final user = authProvider.currentUser;
      if (user != null) {
        debugPrint('🚀 Navigating to ${user.userType.name} dashboard');

        // Navigate to the appropriate dashboard based on user type
        switch (user.userType) {
          case UserType.startup:
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/startup-dashboard',
                (route) => false, // Remove all previous routes
              );
            }
            break;
          case UserType.investor:
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/investor-dashboard',
                (route) => false, // Remove all previous routes
              );
            }
            break;
        }
      }
    } else if (!success && mounted) {
      // Show error message if signup failed
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

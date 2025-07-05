// lib/auth/unified_signup_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'unified_authentication_provider.dart';
import '../components/user_type_selection.dart';
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
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBackgroundDecoration(),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Create Account',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
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
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Join VentureLink',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect with the startup ecosystem',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
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
              // User Type Selection
              UserTypeSelector(
                errorText:
                    authProvider.selectedUserType == null &&
                            authProvider.error != null
                        ? 'Please select whether you are a startup or investor'
                        : null,
                onUserTypeSelected: (userType) {
                  authProvider.clearError();
                },
              ),
              const SizedBox(height: 24),

              // Full Name Field
              _buildInputField(
                label: "Full Name",
                controller: authProvider.nameController,
                focusNode: authProvider.nameFocusNode,
                validator: authProvider.validateFullName,
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),

              // Email Field
              _buildInputField(
                label: "Email",
                controller: authProvider.emailController,
                focusNode: authProvider.emailFocusNode,
                validator: authProvider.validateEmail,
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),

              // Password Field
              _buildInputField(
                label: "Password",
                controller: authProvider.passwordController,
                focusNode: authProvider.passwordFocusNode,
                validator: authProvider.validatePassword,
                isPassword: true,
                icon: Icons.lock_outline,
              ),

              // Password Strength Indicator
              _buildPasswordStrengthIndicator(),
              const SizedBox(height: 16),

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
              ),
              const SizedBox(height: 24),

              // Remember Me Checkbox
              _buildRememberMeCheckbox(),
              const SizedBox(height: 24),

              // Sign Up Button
              _buildSignUpButton(),
              const SizedBox(height: 24),

              // Error Message
              if (authProvider.error != null) _buildErrorMessage(),

              // Login Link
              _buildLoginLink(),
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
  }) {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
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
              decoration: InputDecoration(
                prefixIcon:
                    icon != null
                        ? Icon(icon, color: Colors.grey[400], size: 20)
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
                            size: 20,
                          ),
                          onPressed:
                              label.contains('Confirm')
                                  ? authProvider.toggleConfirmPasswordVisibility
                                  : authProvider.togglePasswordVisibility,
                        )
                        : null,
                hintText: 'Enter your $label',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF1a1a1a),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFffa500)),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                if (authProvider.validateRealTime) {
                  authProvider.validateForm();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.password.isEmpty) return const SizedBox.shrink();

        final strength = authProvider.getPasswordStrength(
          authProvider.password,
        );
        final color = authProvider.getPasswordStrengthColor(strength);
        final text = authProvider.getPasswordStrengthText(strength);

        return Container(
          margin: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(2),
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

  Widget _buildRememberMeCheckbox() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        return Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: authProvider.rememberMe,
                onChanged:
                    (value) => authProvider.setRememberMe(value ?? false),
                activeColor: const Color(0xFFffa500),
                checkColor: Colors.black,
                side: BorderSide(color: Colors.grey[600]!),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Remember me',
              style: TextStyle(color: Colors.grey[300], fontSize: 14),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSignUpButton() {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: authProvider.isAuthenticating ? null : _handleSignUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffa500),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                    : const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const UnifiedLoginPage()),
          );
        },
        child: RichText(
          text: const TextSpan(
            text: "Already have an account? ",
            style: TextStyle(color: Colors.white70, fontSize: 14),
            children: [
              TextSpan(
                text: "Sign In",
                style: TextStyle(
                  color: Color(0xFFffa500),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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

    if (success) {
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Account created successfully! Welcome to VentureLink.',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigation will be handled automatically by the UnifiedAuthWrapper
        // based on the user type in the auth state
      }
    }
  }
}

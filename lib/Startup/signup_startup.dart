import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Startup_Dashboard/startup_dashboard.dart';
import "login_startup.dart";
import 'Providers/startup_authentication_provider.dart';

class StartupSignupPage extends StatefulWidget {
  const StartupSignupPage({super.key});

  @override
  State<StartupSignupPage> createState() => _StartupSignupPageState();
}

class _StartupSignupPageState extends State<StartupSignupPage>
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

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: const Color(0xFFffa500),
      end: const Color(0xFFff8c00),
    ).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
    _colorController.repeat(reverse: true);

    // Initialize form for signup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<StartupAuthProvider>();
      authProvider.setFormType(FormType.signup);
      authProvider.clearForm();
      authProvider.enableRealTimeValidation();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _colorController.dispose();
    super.dispose();
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
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFffa500).withValues(alpha: 0.1),
              Colors.transparent,
              const Color(0xFFff8c00).withValues(alpha: 0.05),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildEnhancedAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a1a).withValues(alpha: 0.8),
              const Color(0xFF0a0a0a).withValues(alpha: 0.9),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFffa500).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFffa500).withValues(alpha: 0.15),
                    const Color(0xFFff8c00).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFffa500).withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFffa500).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFFffa500),
                size: 20,
              ),
            ),
          ),
        ),
      ),
      centerTitle: true,
      title: ShaderMask(
        shaderCallback:
            (bounds) => const LinearGradient(
              colors: [Color(0xFFffa500), Color(0xFFff8c00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
        child: const Text(''),
      ),
    );
  }

  Widget _buildCompactLogo() {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _colorAnimation.value!.withValues(alpha: 0.3),
                    blurRadius: 25,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
            // Logo container
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 140,
                height: 140,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[900]!, Colors.grey[850]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _colorAnimation.value!.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _colorAnimation.value!.withValues(alpha: 0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/VentureLink LogoAlone 2.0.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactHeaderText() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [Color(0xFFffa500), Color(0xFFff8c00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
          child: const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Start your entrepreneurial journey',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // Progress indicator
        Container(
          width: 200,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFffa500), Color(0xFFff8c00)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String? Function(String?) validator,
    bool isPassword = false,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return Consumer<StartupAuthProvider>(
      builder: (context, authProvider, child) {
        final hasContent = controller.text.isNotEmpty;
        final hasFocus = focusNode.hasFocus;
        final hasError =
            controller.text.isNotEmpty &&
            validator(controller.text) != null &&
            authProvider.validateRealTime;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFffa500).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText:
                isPassword &&
                ((label.contains('Password') &&
                        !label.contains('Confirm') &&
                        !authProvider.isPasswordVisible) ||
                    (label.contains('Confirm') &&
                        !authProvider.isConfirmPasswordVisible)),
            keyboardType: keyboardType,
            cursorColor: const Color(0xFFffa500),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            onSubmitted: (_) {
              if (label.contains('Name')) {
                authProvider.emailFocusNode.requestFocus();
              } else if (label.contains('Email')) {
                authProvider.passwordFocusNode.requestFocus();
              } else if (label.contains('Password') &&
                  !label.contains('Confirm')) {
                authProvider.confirmPasswordFocusNode.requestFocus();
              } else {
                _handleSignup();
              }
            },
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color:
                    hasError
                        ? Colors.red
                        : hasFocus
                        ? const Color(0xFFffa500)
                        : Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              errorText: hasError ? validator(controller.text) : null,
              errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
              prefixIcon:
                  icon != null
                      ? Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color:
                              hasError
                                  ? Colors.red.withValues(alpha: 0.2)
                                  : const Color(
                                    0xFFffa500,
                                  ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color:
                              hasError ? Colors.red : const Color(0xFFffa500),
                          size: 18,
                        ),
                      )
                      : null,
              suffixIcon:
                  isPassword
                      ? IconButton(
                        onPressed: () {
                          if (label.contains('Confirm')) {
                            authProvider.toggleConfirmPasswordVisibility();
                          } else {
                            authProvider.togglePasswordVisibility();
                          }
                        },
                        icon: Icon(
                          (label.contains('Confirm')
                                  ? authProvider.isConfirmPasswordVisible
                                  : authProvider.isPasswordVisible)
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                      )
                      : hasContent
                      ? Icon(
                        hasError ? Icons.error : Icons.check_circle,
                        color: hasError ? Colors.red : Colors.green,
                        size: 20,
                      )
                      : null,
              filled: true,
              fillColor: Colors.grey[900]!.withValues(alpha: 0.6),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: hasError ? Colors.red : Colors.grey[800]!,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: hasError ? Colors.red : const Color(0xFFffa500),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(14),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Consumer<StartupAuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.passwordController.text.isEmpty) {
          return const SizedBox.shrink();
        }

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
                  Text(
                    'Password strength: ',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  Text(
                    text,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value:
                    strength == PasswordStrength.none
                        ? 0
                        : strength == PasswordStrength.weak
                        ? 0.33
                        : strength == PasswordStrength.medium
                        ? 0.66
                        : 1.0,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignUpButton() {
    return Consumer<StartupAuthProvider>(
      builder: (context, authProvider, child) {
        final isLoading = authProvider.isAuthenticating;
        final isFormValid = authProvider.isFormValid;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFffa500).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: (isFormValid && !isLoading) ? _handleSignup : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFFffa500),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child:
                isLoading
                    ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Creating Account...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(
                            Icons.person_add,
                            color: Colors.black,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color:
                                isFormValid ? Colors.black : Colors.grey[400],
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
          ),
        );
      },
    );
  }

  Future<void> _handleSignup() async {
    final authProvider = context.read<StartupAuthProvider>();

    // Validate form
    if (!authProvider.validateForm()) {
      return;
    }

    // Unfocus all fields
    authProvider.nameFocusNode.unfocus();
    authProvider.emailFocusNode.unfocus();
    authProvider.passwordFocusNode.unfocus();
    authProvider.confirmPasswordFocusNode.unfocus();

    // Attempt signup
    final success = await authProvider.signUp(
      fullName: authProvider.fullName,
      email: authProvider.email,
      password: authProvider.password,
      confirmPassword: authProvider.confirmPassword,
    );

    if (mounted) {
      if (success) {
        // Check if user needs email confirmation
        final currentUser = authProvider.currentUser;
        if (currentUser != null && !currentUser.isVerified) {
          // Show confirmation message instead of success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Account created! Please check your email to confirm your account before logging in.',
                style: TextStyle(color: Colors.black),
              ),
              backgroundColor: const Color(0xFFffa500),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 5),
            ),
          );

          // Navigate to login page instead of dashboard
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StartupLoginPage()),
            );
          }
        } else {
          // Email confirmation disabled - proceed normally
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Account created successfully! Welcome to VentureLink!',
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

          // Navigate to dashboard
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StartupDashboard()),
            );
          }
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.error ?? 'Signup failed. Please try again.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: _buildEnhancedAppBar(),
      body: Stack(
        children: [
          _buildBackgroundDecoration(),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          kToolbarHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // Compact Logo
                          _buildCompactLogo(),
                          const SizedBox(height: 16),

                          // Compact Header text
                          _buildCompactHeaderText(),
                          const SizedBox(height: 24),

                          // Error Display
                          Consumer<StartupAuthProvider>(
                            builder: (context, authProvider, child) {
                              if (authProvider.error != null) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          authProvider.error!,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: authProvider.clearError,
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),

                          // Form fields
                          Consumer<StartupAuthProvider>(
                            builder: (context, authProvider, child) {
                              return Form(
                                key: authProvider.signupFormKey,
                                child: Column(
                                  children: [
                                    _buildInputField(
                                      label: "Full Name",
                                      controller: authProvider.nameController,
                                      focusNode: authProvider.nameFocusNode,
                                      validator: authProvider.validateFullName,
                                      icon: Icons.person_outline,
                                      keyboardType: TextInputType.name,
                                    ),
                                    const SizedBox(height: 12),

                                    _buildInputField(
                                      label: "Email",
                                      controller: authProvider.emailController,
                                      focusNode: authProvider.emailFocusNode,
                                      validator: authProvider.validateEmail,
                                      keyboardType: TextInputType.emailAddress,
                                      icon: Icons.email_outlined,
                                    ),
                                    const SizedBox(height: 12),

                                    _buildInputField(
                                      label: "Password",
                                      controller:
                                          authProvider.passwordController,
                                      focusNode: authProvider.passwordFocusNode,
                                      validator: authProvider.validatePassword,
                                      isPassword: true,
                                      icon: Icons.lock_outline,
                                    ),

                                    // Password strength indicator
                                    _buildPasswordStrengthIndicator(),

                                    const SizedBox(height: 12),

                                    _buildInputField(
                                      label: "Confirm Password",
                                      controller:
                                          authProvider
                                              .confirmPasswordController,
                                      focusNode:
                                          authProvider.confirmPasswordFocusNode,
                                      validator:
                                          (value) => authProvider
                                              .validateConfirmPassword(
                                                authProvider.password,
                                                value,
                                              ),
                                      isPassword: true,
                                      icon: Icons.lock_outline,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // Sign Up Button
                          _buildSignUpButton(),
                          const SizedBox(height: 16),

                          // Login Link
                          Consumer<StartupAuthProvider>(
                            builder: (context, authProvider, child) {
                              return TextButton(
                                onPressed: () {
                                  authProvider.setFormType(FormType.login);
                                  authProvider.clearForm();
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const StartupLoginPage(),
                                    ),
                                  );
                                },
                                child: RichText(
                                  text: TextSpan(
                                    text: "Already have an account? ",
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: "Log In",
                                        style: TextStyle(
                                          color: Color(0xFFffa500),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

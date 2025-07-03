// lib/Investor/investor_signup_page.dart
import 'package:flutter/material.dart';
// import 'investor_dashboard.dart'; // You'll create this later
import 'login_investor.dart';
// import 'Providers/investor_authentication_provider.dart'; // You'll create this later

class InvestorSignupPage extends StatefulWidget {
  const InvestorSignupPage({super.key});

  @override
  State<InvestorSignupPage> createState() => _InvestorSignupPageState();
}

class _InvestorSignupPageState extends State<InvestorSignupPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _colorController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;

  // Form controllers for demo purposes
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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
      begin: const Color(0xFF65c6f4),
      end: const Color(0xFF4fa8d8),
    ).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
    _colorController.repeat(reverse: true);

    // Add listeners for real-time validation
    _nameController.addListener(_onFormFieldChanged);
    _emailController.addListener(_onFormFieldChanged);
    _passwordController.addListener(_onFormFieldChanged);
    _confirmPasswordController.addListener(_onFormFieldChanged);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _colorController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _onFormFieldChanged() {
    setState(() {}); // Trigger rebuild for form validation
  }

  bool get _isFormValid {
    return _nameController.text.length >= 2 &&
        _emailController.text.contains('@') &&
        _passwordController.text.length >= 6 &&
        _confirmPasswordController.text == _passwordController.text;
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
              const Color(0xFF65c6f4).withValues(alpha: 0.1),
              Colors.transparent,
              const Color(0xFF4fa8d8).withValues(alpha: 0.05),
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
                color: const Color(0xFF65c6f4).withValues(alpha: 0.2),
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
                    const Color(0xFF65c6f4).withValues(alpha: 0.15),
                    const Color(0xFF4fa8d8).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF65c6f4).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF65c6f4),
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
              colors: [Color(0xFF65c6f4), Color(0xFF4fa8d8)],
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
                    color: _colorAnimation.value!.withValues(alpha: 0.4),
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
                      offset: const Offset(0, 6),
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
                colors: [Color(0xFF65c6f4), Color(0xFF4fa8d8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
          child: const Text(
            'Join as Investor',
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
          'Start your investment journey',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 200,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF65c6f4), Color(0xFF4fa8d8)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool isPassword = false,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    final hasContent = controller.text.isNotEmpty;
    final hasFocus = focusNode.hasFocus;
    final hasError =
        hasContent && _getFieldError(label, controller.text) != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF65c6f4).withValues(alpha: 0.1),
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
            ((label == 'Password' && !_isPasswordVisible) ||
                (label == 'Confirm Password' && !_isConfirmPasswordVisible)),
        keyboardType: keyboardType,
        cursorColor: const Color(0xFF65c6f4),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        onSubmitted: (_) {
          if (label == 'Full Name') {
            _emailFocusNode.requestFocus();
          } else if (label == 'Email') {
            _passwordFocusNode.requestFocus();
          } else if (label == 'Password') {
            _confirmPasswordFocusNode.requestFocus();
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
                    ? const Color(0xFF65c6f4)
                    : Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          errorText: hasError ? _getFieldError(label, controller.text) : null,
          errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
          prefixIcon:
              icon != null
                  ? Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color:
                          hasError
                              ? Colors.red.withValues(alpha: 0.1)
                              : hasFocus
                              ? const Color(0xFF65c6f4).withValues(alpha: 0.15)
                              : Colors.grey[800]!.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color:
                          hasError
                              ? Colors.red
                              : hasFocus
                              ? const Color(0xFF65c6f4)
                              : Colors.grey[400],
                      size: 16,
                    ),
                  )
                  : null,
          suffixIcon:
              isPassword
                  ? GestureDetector(
                    onTap: () {
                      setState(() {
                        if (label == 'Password') {
                          _isPasswordVisible = !_isPasswordVisible;
                        } else {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      child: Icon(
                        (label == 'Password' && _isPasswordVisible) ||
                                (label == 'Confirm Password' &&
                                    _isConfirmPasswordVisible)
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                    ),
                  )
                  : null,
          filled: true,
          fillColor: Colors.grey[850]!.withValues(alpha: 0.9),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.grey[800]!,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: hasError ? Colors.red : const Color(0xFF65c6f4),
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
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  String? _getFieldError(String label, String value) {
    switch (label) {
      case 'Full Name':
        if (value.length < 2) return 'Name must be at least 2 characters';
        break;
      case 'Email':
        if (!value.contains('@')) return 'Please enter a valid email';
        break;
      case 'Password':
        if (value.length < 6) return 'Password must be at least 6 characters';
        break;
      case 'Confirm Password':
        if (value != _passwordController.text) return 'Passwords do not match';
        break;
    }
    return null;
  }

  Widget _buildPasswordStrengthIndicator() {
    if (_passwordController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    final password = _passwordController.text;
    int score = 0;

    // Calculate password strength
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    String strengthText;
    Color color;
    double progress;

    if (score <= 2) {
      strengthText = 'Weak';
      color = Colors.red;
      progress = 0.33;
    } else if (score <= 4) {
      strengthText = 'Medium';
      color = Colors.orange;
      progress = 0.66;
    } else {
      strengthText = 'Strong';
      color = Colors.green;
      progress = 1.0;
    }

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
                strengthText,
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
            value: progress,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF65c6f4,
            ).withValues(alpha: _isFormValid ? 0.3 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isFormValid ? _handleSignup : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor:
              _isFormValid ? const Color(0xFF65c6f4) : Colors.grey[700],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
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
                color: _isFormValid ? Colors.black : Colors.grey[400],
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
        gradient: LinearGradient(
          colors: [
            Colors.grey[900]!.withValues(alpha: 0.3),
            Colors.grey[800]!.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: TextButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const InvestorLoginPage()),
          );
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: RichText(
          text: TextSpan(
            text: 'Already have an account? ',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
            children: const [
              TextSpan(
                text: 'Log In',
                style: TextStyle(
                  color: Color(0xFF65c6f4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    // TODO: Implement actual signup logic with InvestorAuthProvider

    // Unfocus fields
    _nameFocusNode.unfocus();
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();
    _confirmPasswordFocusNode.unfocus();

    // Show loading state
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Creating account...'),
          ],
        ),
        backgroundColor: const Color(0xFF65c6f4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );

    // Simulate signup delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Signup functionality will be implemented with InvestorAuthProvider',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: const Color(0xFF65c6f4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
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
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildCompactLogo(),
                      const SizedBox(height: 12),
                      _buildCompactHeaderText(),
                      const SizedBox(height: 12),

                      Form(
                        child: Column(
                          children: [
                            _buildInputField(
                              label: "Full Name",
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              icon: Icons.person_outline,
                              keyboardType: TextInputType.name,
                            ),
                            const SizedBox(height: 12),

                            _buildInputField(
                              label: "Email",
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 12),

                            _buildInputField(
                              label: "Password",
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              isPassword: true,
                              icon: Icons.lock_outline,
                            ),

                            // Password strength indicator
                            _buildPasswordStrengthIndicator(),

                            const SizedBox(height: 12),

                            _buildInputField(
                              label: "Confirm Password",
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocusNode,
                              isPassword: true,
                              icon: Icons.lock_outline,
                            ),
                            const SizedBox(height: 20),

                            _buildSignUpButton(),
                            const SizedBox(height: 20),

                            _buildLoginLink(),
                            const SizedBox(height: 10),
                          ],
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
    );
  }
}

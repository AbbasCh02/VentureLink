// lib/Investor/investor_page.dart
import 'package:flutter/material.dart';
import '../auth/unified_signup.dart';
import '../auth/unified_login.dart';
import '../auth/unified_authentication_provider.dart';
import 'package:provider/provider.dart';

class InvestorPage extends StatefulWidget {
  const InvestorPage({super.key});

  @override
  State<InvestorPage> createState() => _InvestorPageState();
}

class _InvestorPageState extends State<InvestorPage>
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
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _colorController = AnimationController(
      duration: const Duration(milliseconds: 4000),
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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
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

    // Check if user is already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  void _checkLoginStatus() {
    final authProvider = context.read<UnifiedAuthProvider>();
    if (authProvider.isLoggedIn &&
        authProvider.currentUser?.userType == UserType.investor) {
      // Navigate to investor dashboard if already logged in as investor
      Navigator.pushReplacementNamed(context, '/investor_dashboard');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  // Enhanced AppBar builder
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
                  width: 1,
                ),
                color: const Color(0xFF1a1a1a).withValues(alpha: 0.8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF65c6f4),
                size: 18,
              ),
            ),
          ),
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF65c6f4).withValues(alpha: 0.1),
          border: Border.all(
            color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance, color: Color(0xFF65c6f4), size: 20),
            SizedBox(width: 8),
            Text(
              'Investor Portal',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
    );
  }

  // Enhanced background decoration
  Widget _buildBackgroundDecoration() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [Color(0xFF1a1a1a), Color(0xFF0f0f0f), Color(0xFF0a0a0a)],
        ),
      ),
      child: CustomPaint(
        painter: InvestorBackgroundPainter(),
        size: Size.infinite,
      ),
    );
  }

  // Centered logo with enhanced design
  Widget _buildCenteredLogo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _colorAnimation,
            builder: (context, child) {
              return ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _colorAnimation.value ?? const Color(0xFF65c6f4),
                        const Color(0xFF4fa8d8),
                        const Color(0xFF3a8bc2),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_colorAnimation.value ??
                                const Color(0xFF65c6f4))
                            .withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                      BoxShadow(
                        color: const Color(0xFF65c6f4).withValues(alpha: 0.2),
                        blurRadius: 60,
                        offset: const Offset(0, 30),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Investor welcome text
  Widget _buildInvestorText() {
    return Column(
      children: [
        const Text(
          'Welcome, Investor',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Discover the next generation of startups',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 18,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Connect with innovative founders and promising ventures',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildElegantButton({
    required String text,
    required Color backgroundColor,
    required Color accentColor,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      height: 64,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [backgroundColor, accentColor],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSignup() {
    final authProvider = context.read<UnifiedAuthProvider>();
    authProvider.setFormType(FormType.signup);
    authProvider.setUserType(UserType.investor); // Pre-select investor type
    authProvider.clearForm();

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const UnifiedSignupPage()));
  }

  void _navigateToLogin() {
    final authProvider = context.read<UnifiedAuthProvider>();
    authProvider.setFormType(FormType.login);
    authProvider.clearForm();

    // Pre-fill email if remembered
    if (authProvider.savedEmail != null) {
      authProvider.emailController.text = authProvider.savedEmail!;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const UnifiedLoginPage()));
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
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Logo section - centered and taking appropriate space
                      Expanded(flex: 4, child: _buildCenteredLogo()),

                      // Investor text - compact spacing
                      _buildInvestorText(),
                      const SizedBox(height: 32),

                      // Buttons section - remaining space
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Sign Up Button
                            _buildElegantButton(
                              text: 'Create Account',
                              backgroundColor: const Color(0xFF65c6f4),
                              accentColor: const Color(0xFF4fa8d8),
                              icon: Icons.person_add,
                              onPressed: _navigateToSignup,
                            ),

                            // Log In Button
                            _buildElegantButton(
                              text: 'Sign In',
                              backgroundColor: const Color(0xFF4fa8d8),
                              accentColor: const Color(0xFF3a8bc2),
                              icon: Icons.login,
                              onPressed: _navigateToLogin,
                            ),

                            const SizedBox(height: 24),

                            // Feature highlights
                            _buildFeatureHighlights(),
                          ],
                        ),
                      ),

                      // Footer section
                      _buildFooter(),
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

  Widget _buildFeatureHighlights() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF65c6f4).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Ready to discover promising startups?',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFeatureItem(Icons.search, 'Discover'),
              _buildFeatureItem(Icons.analytics, 'Analyze'),
              _buildFeatureItem(Icons.handshake, 'Invest'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF65c6f4).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: const Color(0xFF65c6f4), size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Join thousands of investors discovering the next big thing',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, color: Colors.grey[700], size: 12),
            const SizedBox(width: 4),
            Text(
              'Secure & Trusted Platform',
              style: TextStyle(color: Colors.grey[700], fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

// Custom painter for investor-themed background
class InvestorBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF65c6f4).withValues(alpha: 0.03)
          ..strokeWidth = 1;

    // Draw subtle investment-themed pattern
    const spacing = 60.0;

    // Draw grid pattern
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw some investment-themed shapes
    paint.color = const Color(0xFF65c6f4).withValues(alpha: 0.05);
    for (int i = 0; i < 8; i++) {
      final x = (i * spacing * 1.5) % size.width;
      final y = (i * spacing * 0.8) % size.height;
      canvas.drawCircle(Offset(x, y), 20, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

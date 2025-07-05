// lib/Startup/startup_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/unified_signup.dart';
import '../auth/unified_login.dart';
import '../auth/unified_authentication_provider.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage>
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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Orange color animation for startup theme
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

    // Check if user is already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  void _checkLoginStatus() {
    final authProvider = context.read<UnifiedAuthProvider>();
    if (authProvider.isLoggedIn &&
        authProvider.currentUser?.userType == UserType.startup) {
      // Navigate to startup dashboard if already logged in as startup
      Navigator.pushReplacementNamed(context, '/startup_dashboard');
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
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFFffa500),
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
          color: const Color(0xFFffa500).withValues(alpha: 0.1),
          border: Border.all(
            color: const Color(0xFFffa500).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rocket_launch, color: Color(0xFFffa500), size: 20),
            SizedBox(width: 8),
            Text(
              'Startup Portal',
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
        painter: StartupBackgroundPainter(),
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
                    gradient: LinearGradient(
                      colors: [
                        _colorAnimation.value ?? const Color(0xFFffa500),
                        const Color(0xFFff8c00),
                        const Color(0xFFe67e00),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: (_colorAnimation.value ?? const Color(0xFFffa500))
                          .withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_colorAnimation.value ??
                                const Color(0xFFffa500))
                            .withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                      BoxShadow(
                        color: const Color(0xFFffa500).withValues(alpha: 0.2),
                        blurRadius: 60,
                        offset: const Offset(0, 30),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.rocket_launch,
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

  // Startup welcome text
  Widget _buildStartupText() {
    return Column(
      children: [
        const Text(
          'Welcome, Founder',
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
          'Transform your ideas into reality',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 18,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Connect with investors and grow your startup',
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
    authProvider.setUserType(UserType.startup); // Pre-select startup type
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

                      // Startup text - compact spacing
                      _buildStartupText(),
                      const SizedBox(height: 32),

                      // Buttons section - taking remaining space
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Sign Up Button
                            _buildElegantButton(
                              text: 'Create Account',
                              backgroundColor: const Color(0xFFffa500),
                              accentColor: const Color(0xFFff8c00),
                              icon: Icons.person_add,
                              onPressed: _navigateToSignup,
                            ),

                            // Log In Button
                            _buildElegantButton(
                              text: 'Sign In',
                              backgroundColor: const Color(0xFFff8c00),
                              accentColor: const Color(0xFFe67e00),
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
          color: const Color(0xFFffa500).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Ready to transform your ideas into reality?',
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
              _buildFeatureItem(Icons.lightbulb, 'Innovate'),
              _buildFeatureItem(Icons.trending_up, 'Scale'),
              _buildFeatureItem(Icons.attach_money, 'Fund'),
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
            color: const Color(0xFFffa500).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFffa500).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: const Color(0xFFffa500), size: 18),
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
          'Join thousands of entrepreneurs building the future',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, color: Colors.grey[700], size: 12),
            const SizedBox(width: 4),
            Text(
              'Trusted by Founders Worldwide',
              style: TextStyle(color: Colors.grey[700], fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

// Custom painter for startup-themed background
class StartupBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFFffa500).withValues(alpha: 0.03)
          ..strokeWidth = 1;

    // Draw subtle startup-themed pattern
    const spacing = 60.0;

    // Draw grid pattern
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw some startup-themed shapes (rockets, lightbulbs)
    paint.color = const Color(0xFFffa500).withValues(alpha: 0.05);
    for (int i = 0; i < 6; i++) {
      final x = (i * spacing * 1.8) % size.width;
      final y = (i * spacing * 1.2) % size.height;

      // Draw rocket-like triangular shapes
      final path = Path();
      path.moveTo(x, y - 15);
      path.lineTo(x - 10, y + 15);
      path.lineTo(x + 10, y + 15);
      path.close();
      canvas.drawPath(path, paint);
    }

    // Draw some circular innovation bubbles
    paint.color = const Color(0xFFffa500).withValues(alpha: 0.04);
    for (int i = 0; i < 8; i++) {
      final x = (i * spacing * 1.3 + spacing / 2) % size.width;
      final y = (i * spacing * 0.9 + spacing / 2) % size.height;
      canvas.drawCircle(Offset(x, y), 18, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

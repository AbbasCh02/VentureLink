// lib/homepage.dart (Updated WelcomePage)
import 'package:flutter/material.dart';
import 'auth/unified_signup.dart';
import 'auth/unified_login.dart';

/**
 * Implements a comprehensive welcome page for VentureLink application onboarding.
 * Provides an engaging introduction to the platform with advanced animations and professional branding.
 * 
 * Features:
 * - Advanced multi-layered animation system with fade, slide, pulse, and color transitions
 * - Dynamic color-changing logo and branding elements transitioning between orange and blue
 * - Professional gradient backgrounds with custom painted grid patterns
 * - Interactive animated buttons with gradient effects and shadow animations
 * - Responsive brand section with logo, tagline, and feature preview
 * - Navigation integration to unified signup and login pages
 * - Professional onboarding experience with smooth transitions and visual feedback
 * - Fallback error handling for missing logo assets
 * - Custom background pattern painter for subtle visual enhancement
 * - Scalable animation effects with proper controller lifecycle management
 * - Professional button hierarchy with primary and secondary styling
 * - Feature preview section highlighting key platform benefits
 * - Consistent orange-to-blue color scheme with professional styling
 */

/**
 * WelcomePage - Main onboarding widget for VentureLink application introduction.
 * Integrates comprehensive animations, branding, and navigation for user acquisition.
 */
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

/**
 * _WelcomePageState - State management for the comprehensive welcome page interface.
 * Manages multiple animation controllers, color transitions, and navigation operations.
 */
class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  /**
   * Animation controllers for coordinated visual effects and transitions.
   */
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _colorController;

  /**
   * Animation instances for specific visual effects and transitions.
   */
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;

  /**
   * Initializes the welcome page state and sets up animation system.
   * Configures all animation controllers and starts initial animations.
   */
  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  /**
   * Sets up comprehensive animation system with multiple coordinated controllers.
   * Configures fade, slide, pulse, and color transition animations with appropriate curves and durations.
   */
  void _setupAnimations() {
    // Initialize animation controllers with specific durations for different effects
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

    // Configure fade animation from transparent to opaque
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Configure slide animation from bottom to center position
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Configure subtle pulse animation for logo breathing effect
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Configure color animation between orange and blue for dynamic branding
    _colorAnimation = ColorTween(
      begin: const Color(0xFFffa500), // VentureLink Orange
      end: const Color(0xFF65c6f4), // Professional Blue
    ).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
    );

    // Start animations with appropriate repeat patterns
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true); // Continuous breathing effect
    _colorController.repeat(reverse: true); // Continuous color cycling
  }

  /**
   * Disposes all animation controllers to prevent memory leaks.
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
   * Navigates to unified signup page for new user registration.
   * Provides smooth transition to account creation process.
   */
  void _navigateToSignup() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const UnifiedSignupPage()));
  }

  /**
   * Navigates to unified login page for existing user authentication.
   * Provides smooth transition to login process.
   */
  void _navigateToLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const UnifiedLoginPage()));
  }

  /**
   * Builds the main welcome page interface with layered animations and professional styling.
   * Integrates background decoration, brand section, and action section with coordinated animations.
   * 
   * @return Widget containing the complete welcome page interface
   */
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    children: [
                      // Logo, branding, and messaging section
                      Expanded(flex: 5, child: _buildBrandSection()),

                      // Call-to-action buttons and features section
                      Expanded(flex: 3, child: _buildActionSection()),

                      const SizedBox(height: 8), // Bottom spacing for safe area
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
   * Builds the background decoration with radial gradient and custom grid pattern.
   * Creates professional depth and visual interest without distracting from content.
   * 
   * @return Widget containing the layered background decoration
   */
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

  /**
   * Builds the brand section with animated logo, company name, and messaging.
   * Features color-changing elements and pulsing logo for dynamic visual appeal.
   * 
   * @return Widget containing the complete branding and messaging section
   */
  Widget _buildBrandSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated logo with color-changing glow and pulse effect
        AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            final currentColor =
                _colorAnimation.value ?? const Color(0xFFffa500);
            return ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 140,
                height: 140,
                padding: const EdgeInsets.all(12),
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
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: currentColor, // Dynamic border color
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withValues(
                        alpha: 0.5,
                      ), // Animated inner glow
                      blurRadius: 25,
                      offset: const Offset(0, 0),
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: currentColor.withValues(
                        alpha: 0.3,
                      ), // Animated outer glow
                      blurRadius: 40,
                      offset: const Offset(0, 0),
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/VentureLink LogoAlone 2.0.png',
                    width: 116,
                    height: 116,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Professional fallback if logo asset is missing
                      return const Icon(
                        Icons.business_center,
                        size: 60,
                        color: Color(0xFFffa500),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),

        // Company name with dynamic color animation and shadow effects
        AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            final currentColor =
                _colorAnimation.value ?? const Color(0xFFffa500);
            return Text(
              'VentureLink',
              style: TextStyle(
                color: currentColor, // Dynamic text color
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: currentColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Primary tagline with color animation and professional messaging
        AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            final currentColor =
                _colorAnimation.value ?? const Color(0xFFffa500);
            return Text(
              'Connecting Startups with Investors',
              style: TextStyle(
                color: currentColor.withValues(
                  alpha: 0.8,
                ), // Animated subtitle with reduced opacity
                fontSize: 18,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: currentColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
        const SizedBox(height: 8),

        // Secondary tagline with ecosystem messaging
        Text(
          'Join the ecosystem where innovation meets investment',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /**
   * Builds the action section with call-to-action buttons and feature preview.
   * Features animated primary button and secondary login option with feature highlights.
   * 
   * @return Widget containing the action buttons and feature preview section
   */
  Widget _buildActionSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Primary call-to-action button with full color animation
        _buildAnimatedButton(
          text: 'Get Started',
          subtitle: 'Create your account',
          icon: Icons.rocket_launch,
          onPressed: _navigateToSignup,
        ),
        const SizedBox(height: 16),

        // Secondary login button with consistent styling
        _buildSecondaryButton(
          text: 'Sign In',
          subtitle: 'Already have an account?',
          icon: Icons.login,
          onPressed: _navigateToLogin,
        ),
        const SizedBox(height: 24),

        // Platform features preview section
        _buildFeaturePreview(),
      ],
    );
  }

  /**
   * Builds animated primary button with full color transitions and gradient effects.
   * Features dynamic color animation, shadow effects, and professional interaction feedback.
   * 
   * @param text The primary button text
   * @param subtitle The descriptive subtitle text
   * @param icon The leading icon for the button
   * @param onPressed The callback function when button is pressed
   * @return Widget containing the fully animated primary button
   */
  Widget _buildAnimatedButton({
    required String text,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        final currentColor = _colorAnimation.value ?? const Color(0xFFffa500);

        // Create gradient shades from current animated color
        final lightShade =
            Color.lerp(currentColor, Colors.white, 0.1) ?? currentColor;
        final darkShade =
            Color.lerp(currentColor, Colors.black, 0.2) ?? currentColor;

        return Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
            // Full button gradient with animated color transitions
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
                blurRadius: 15,
                offset: const Offset(0, 6),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: currentColor.withValues(alpha: 0.2),
                blurRadius: 25,
                offset: const Offset(0, 10),
                spreadRadius: 3,
              ),
            ],
            border: Border.all(
              color: currentColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.black,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /**
   * Builds secondary button with subtle styling for login functionality.
   * Provides clear hierarchy with primary action button while maintaining professional appearance.
   * 
   * @param text The secondary button text
   * @param subtitle The descriptive subtitle text
   * @param icon The leading icon for the button
   * @param onPressed The callback function when button is pressed
   * @return Widget containing the styled secondary button
   */
  Widget _buildSecondaryButton({
    required String text,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.grey[400], size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 14),
          ],
        ),
      ),
    );
  }

  /**
   * Builds feature preview section highlighting key platform benefits.
   * Displays core value propositions in compact, visually appealing format.
   * 
   * @return Widget containing the feature preview with icons and labels
   */
  Widget _buildFeaturePreview() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFeatureItem(Icons.handshake, 'Connect'),
        _buildFeatureItem(Icons.trending_up, 'Grow'),
      ],
    );
  }

  /**
   * Builds individual feature items with icons and descriptive labels.
   * Creates consistent styling for feature highlights with professional appearance.
   * 
   * @param icon The icon representing the feature
   * @param label The text label describing the feature
   * @return Widget containing the styled feature item
   */
  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a1a),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Icon(icon, color: Colors.grey[400], size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/**
 * Custom painter for background pattern enhancement.
 * Creates subtle grid pattern overlay for visual depth without distraction.
 */
class BackgroundPatternPainter extends CustomPainter {
  /**
   * Paints subtle grid pattern on the background canvas.
   * Creates professional visual texture with minimal opacity for elegance.
   * 
   * @param canvas The canvas to paint on
   * @param size The size of the canvas area
   */
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.02)
          ..strokeWidth = 1;

    // Draw subtle grid pattern with consistent spacing
    const spacing = 50.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  /**
   * Determines whether the painter should repaint.
   * Returns false for static pattern that doesn't require updates.
   * 
   * @param oldDelegate The previous painter instance
   * @return Boolean indicating if repaint is needed
   */
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

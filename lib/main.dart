// lib/main.dart
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "homepage.dart";
import "Startup/Providers/startup_profile_overview_provider.dart";
import "Startup/Providers/startup_profile_provider.dart";
import "Startup/Providers/team_members_provider.dart";
import 'Startup/Providers/business_model_canvas_provider.dart';
import 'auth/unified_authentication_provider.dart'; // NEW: Import unified provider
import 'Startup/Startup_Dashboard/profile_overview.dart';
import 'Startup/Startup_Dashboard/startup_profile_page.dart';
import 'Startup/Startup_Dashboard/team_members_page.dart';
import 'Startup/Startup_Dashboard/Business_Model_Canvas/business_model_canvas.dart';
import 'Startup/Startup_Dashboard/startup_dashboard.dart';
import 'Investor/investor_dashboard.dart'; // Add investor dashboard
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/unified_login.dart';
import 'auth/unified_signup.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables FIRST
  await dotenv.load(fileName: ".env");

  // Verify environment variables are loaded
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception(
      'Missing Supabase environment variables. Please check your .env file.',
    );
  }

  // Initialize Supabase
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  debugPrint('✅ Supabase initialized successfully');
  debugPrint('✅ Environment variables loaded');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // CRITICAL: Unified Authentication Provider MUST be first
        // This replaces both StartupAuthProvider and InvestorAuthProvider
        ChangeNotifierProvider(
          create: (context) => UnifiedAuthProvider(),
          lazy: false, // Initialize immediately
        ),

        // Profile Overview Provider (company details: name, tagline, industry, region)
        ChangeNotifierProvider(
          create: (context) => StartupProfileOverviewProvider(),
          lazy: false,
        ),

        // Startup Profile Provider (funding, idea, pitch deck, profile image)
        ChangeNotifierProvider(
          create: (context) => StartupProfileProvider(),
          lazy: false,
        ),

        // Team Members Provider (team management)
        ChangeNotifierProvider(
          create: (context) => TeamMembersProvider(),
          lazy: false,
        ),

        // Business Model Canvas Provider
        ChangeNotifierProvider(
          create: (context) => BusinessModelCanvasProvider(),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'VentureLink',
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.blueGrey,
          scaffoldBackgroundColor: Colors.black,
        ),
        // Use UnifiedAuthWrapper instead of multiple auth wrappers
        home: const UnifiedAuthWrapper(),
        routes: {
          // Startup Routes
          '/profile-overview': (context) => const ProfileOverview(),
          '/startup-profile': (context) => const StartupProfilePage(),
          '/team-members': (context) => const TeamMembersPage(),
          '/business_model': (context) => const BusinessModelCanvas(),
          '/startup_dashboard': (context) => const StartupDashboard(),

          // Investor Routes
          '/investor_dashboard': (context) => const InvestorDashboard(),

          // Unified Authentication Routes
          '/signup': (context) => const UnifiedSignupPage(),
          '/login': (context) => const UnifiedLoginPage(),

          // General Routes
          '/welcome': (context) => const WelcomePage(),
        },
      ),
    );
  }
}

// Unified Auth Wrapper widget that handles routing based on user type
class UnifiedAuthWrapper extends StatelessWidget {
  const UnifiedAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        debugPrint('🔍 UnifiedAuthWrapper build:');
        debugPrint('   isLoading: ${authProvider.isLoading}');
        debugPrint('   isLoggedIn: ${authProvider.isLoggedIn}');
        debugPrint('   currentUser: ${authProvider.currentUser?.email}');
        debugPrint('   userType: ${authProvider.currentUser?.userType.name}');

        // Show loading screen while checking authentication
        if (authProvider.isLoading) {
          debugPrint('📱 Showing loading screen');
          return const AuthLoadingScreen();
        }

        // If user is logged in, route to appropriate dashboard based on user type
        if (authProvider.isLoggedIn && authProvider.currentUser != null) {
          final user = authProvider.currentUser!;

          debugPrint(
            '✅ User is authenticated: ${user.id} (${user.userType.name})',
          );
          debugPrint('🚀 Routing to ${user.userType.name} dashboard');

          // Route to appropriate dashboard based on user type
          switch (user.userType) {
            case UserType.startup:
              debugPrint('📱 Showing StartupDashboard');
              return const StartupDashboard();
            case UserType.investor:
              debugPrint('📱 Showing InvestorDashboard');
              return const InvestorDashboard();
          }
        }

        // If not logged in, show welcome page
        debugPrint('❌ User is not authenticated - showing welcome page');
        return const WelcomePage();
      },
    );
  }
}

// Enhanced Loading screen with better messaging
class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [Color(0xFF1a1a1a), Color(0xFF0a0a0a)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Enhanced Logo with animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[900]!, Colors.grey[850]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[800]!, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFffa500,
                            ).withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.business_center,
                        size: 64,
                        color: Color(0xFFffa500),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Enhanced loading indicator
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffa500)),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),

              // Loading text with animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, opacity, child) {
                  return Opacity(
                    opacity: opacity,
                    child: Column(
                      children: [
                        const Text(
                          'Welcome to VentureLink',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Setting up your dashboard...',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/main.dart - Replace your main.dart with this updated version:

import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "homepage.dart";
import "Startup/Providers/startup_profile_overview_provider.dart";
import "Startup/Providers/startup_profile_provider.dart";
import "Startup/Providers/team_members_provider.dart";
import 'Startup/Providers/business_model_canvas_provider.dart';
import 'Startup/Providers/startup_authentication_provider.dart';
import 'Startup/Startup_Dashboard/profile_overview.dart';
import 'Startup/Startup_Dashboard/startup_profile_page.dart';
import 'Startup/Startup_Dashboard/team_members_page.dart';
import 'Startup/Startup_Dashboard/Business_Model_Canvas/business_model_canvas.dart';
import 'Startup/Startup_Dashboard/startup_dashboard.dart';
import 'Startup/Providers/user_type_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  debugPrint('✅ Environment variables loaded successfully');
  debugPrint('📍 Supabase URL: ${supabaseUrl.substring(0, 30)}...');

  // Initialize Supabase with loaded environment variables
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: true, // Set to false in production
  );

  debugPrint('✅ Supabase initialized successfully');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Authentication Provider - MUST be first as others depend on it
        ChangeNotifierProvider(
          create: (context) => StartupAuthProvider(),
          lazy: false,
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

        // User Type Provider
        ChangeNotifierProvider(
          create: (context) => UserTypeProvider(),
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
        // Use AuthWrapper to handle authentication state
        home: const AuthWrapper(),
        routes: {
          '/profile-overview': (context) => const ProfileOverview(),
          '/startup-profile': (context) => const StartupProfilePage(),
          '/team-members': (context) => const TeamMembersPage(),
          '/business_model': (context) => const BusinessModelCanvas(),
          '/startup-dashboard': (context) => const StartupDashboard(),
        },
      ),
    );
  }
}

// AuthWrapper to handle authentication state and provider initialization
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasInitializedProviders = false;

  @override
  void initState() {
    super.initState();

    // Listen to auth state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthenticationState();
    });
  }

  void _checkAuthenticationState() {
    final authProvider = context.read<StartupAuthProvider>();

    // If user is logged in but providers haven't been initialized
    if (authProvider.isLoggedIn && !_hasInitializedProviders) {
      _initializeUserProviders();
    }
  }

  Future<void> _initializeUserProviders() async {
    if (_hasInitializedProviders) return;

    setState(() {
      _hasInitializedProviders = true;
    });

    try {
      debugPrint(
        '🔄 AuthWrapper: Initializing providers for logged-in user...',
      );

      // Get all providers
      final profileOverviewProvider =
          context.read<StartupProfileOverviewProvider>();
      final startupProfileProvider = context.read<StartupProfileProvider>();
      final businessModelProvider = context.read<BusinessModelCanvasProvider>();
      final teamMembersProvider = context.read<TeamMembersProvider>();

      // Initialize providers that need manual initialization
      // Note: Some providers auto-initialize, others need explicit initialization
      await Future.wait([
        profileOverviewProvider.initialize(),
        startupProfileProvider.initialize(),
        businessModelProvider.initialize(),
        teamMembersProvider.initialize(),
      ]);

      debugPrint('✅ AuthWrapper: All providers initialized successfully');
    } catch (e) {
      debugPrint('❌ AuthWrapper: Error initializing providers: $e');
      setState(() {
        _hasInitializedProviders = false; // Allow retry
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StartupAuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while checking authentication
        if (authProvider.isLoading) {
          return const AuthLoadingScreen();
        }

        // If user is logged in
        if (authProvider.isLoggedIn && authProvider.currentUser != null) {
          // Initialize providers if not done yet
          if (!_hasInitializedProviders) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeUserProviders();
            });
          }

          return const StartupDashboard();
        }

        // Reset provider initialization flag when user logs out
        if (!authProvider.isLoggedIn && _hasInitializedProviders) {
          setState(() {
            _hasInitializedProviders = false;
          });
        }

        // If not logged in, show welcome page
        return const WelcomePage();
      },
    );
  }
}

// Loading screen while checking authentication
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
              // Animated logo
              Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[900]!, Colors.grey[850]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFffa500).withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFffa500).withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  color: Color(0xFFffa500),
                  size: 60,
                ),
              ),
              const SizedBox(height: 32),

              // Loading indicator
              const CircularProgressIndicator(
                color: Color(0xFFffa500),
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),

              // Loading text
              ShaderMask(
                shaderCallback:
                    (bounds) => const LinearGradient(
                      colors: [Color(0xFFffa500), Color(0xFFff8c00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                child: const Text(
                  'VentureLink',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Loading your startup profile...',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

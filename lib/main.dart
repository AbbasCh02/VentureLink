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
          '/welcome': (context) => const WelcomePage(),
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

// Replace your existing _AuthWrapperState class in main.dart with this:

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasInitializedProviders = false;
  String? _lastUserId; // Add this to track user changes

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
    final currentUserId = authProvider.currentUser?.id;

    // Check if user changed or logged out
    if (_lastUserId != currentUserId) {
      if (currentUserId == null) {
        // User logged out - clear all providers
        debugPrint('🔄 User logged out - clearing all providers');
        _clearAllProviders();
      } else if (_lastUserId != null) {
        // User changed - reset providers for new user
        debugPrint('🔄 User changed - resetting providers for new user');
        _resetProvidersForNewUser();
      }
      _lastUserId = currentUserId;
    }

    // Initialize providers for newly logged in user
    if (authProvider.isLoggedIn && !_hasInitializedProviders) {
      debugPrint('🔄 Initializing providers for logged-in user');
      _initializeProviders();
    }
  }

  void _clearAllProviders() {
    try {
      context.read<StartupProfileOverviewProvider>().clearAllData();
      context.read<StartupProfileProvider>().clearAllData();
      context.read<BusinessModelCanvasProvider>().clearAllData();
      context.read<TeamMembersProvider>().clearAllData();
      _hasInitializedProviders = false;
      debugPrint('✅ All providers cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing providers: $e');
    }
  }

  void _resetProvidersForNewUser() {
    try {
      context.read<StartupProfileOverviewProvider>().resetForNewUser();
      context.read<StartupProfileProvider>().resetForNewUser();
      context.read<BusinessModelCanvasProvider>().resetForNewUser();
      context.read<TeamMembersProvider>().resetForNewUser();
      _hasInitializedProviders = true;
      debugPrint('✅ Providers reset for new user');
    } catch (e) {
      debugPrint('❌ Error resetting providers: $e');
      _hasInitializedProviders = false;
    }
  }

  void _initializeProviders() {
    if (!_hasInitializedProviders) {
      try {
        context.read<StartupProfileOverviewProvider>().initialize();
        context.read<StartupProfileProvider>().initialize();
        context.read<BusinessModelCanvasProvider>().initialize();
        context.read<TeamMembersProvider>().initialize();
        _hasInitializedProviders = true;
        debugPrint('✅ Providers initialized successfully');
      } catch (e) {
        debugPrint('❌ Error initializing providers: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StartupAuthProvider>(
      builder: (context, authProvider, child) {
        // Check for authentication state changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkAuthenticationState();
        });

        // Show loading screen while checking authentication
        if (authProvider.isLoading) {
          return const AuthLoadingScreen();
        }

        // If user is logged in, show dashboard
        if (authProvider.isLoggedIn && authProvider.currentUser != null) {
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

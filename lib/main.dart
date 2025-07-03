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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Startup/startup_page.dart';
import 'Startup/signup_startup.dart';
import 'Startup/login_startup.dart';

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
        // CRITICAL: Authentication Provider MUST be first
        // All other providers depend on user authentication state
        ChangeNotifierProvider(
          create: (context) => StartupAuthProvider(),
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
        // Use AuthWrapper instead of directly going to WelcomePage
        home: const AuthWrapper(),
        routes: {
          '/profile-overview': (context) => const ProfileOverview(),
          '/startup-profile': (context) => const StartupProfilePage(),
          '/team-members': (context) => const TeamMembersPage(),
          '/business_model': (context) => const BusinessModelCanvas(),
          '/choose_profile': (context) => const StartupPage(),
          '/signup_startup': (context) => const StartupSignupPage(),
          '/login_startup': (context) => const StartupLoginPage(),
          '/dashboard': (context) => const StartupDashboard(),
          '/welcome': (context) => const WelcomePage(),
        },
      ),
    );
  }
}

// CRITICAL: AuthWrapper widget to handle user isolation and auto-login logic
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasInitializedProviders = false;
  String? _lastUserId; // CRITICAL: Track user changes for proper isolation

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

    // CRITICAL: Check if user changed or logged out
    if (_lastUserId != currentUserId) {
      if (currentUserId == null) {
        // User logged out - clear all providers
        debugPrint('🔄 User logged out - clearing all providers');
        _clearAllProviders();
      } else if (_lastUserId != null) {
        // User changed - reset providers for new user
        debugPrint(
          '🔄 User changed from $_lastUserId to $currentUserId - resetting providers',
        );
        _resetProvidersForNewUser();
      } else {
        // First time login - initialize providers
        debugPrint(
          '🔄 First time login for user $currentUserId - initializing providers',
        );
        _initializeProviders();
      }
      _lastUserId = currentUserId;
    }

    // Initialize providers for newly logged in user
    if (authProvider.isLoggedIn && !_hasInitializedProviders) {
      debugPrint(
        '🔄 Initializing providers for logged-in user: $currentUserId',
      );
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
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFffa500)),
                  SizedBox(height: 16),
                  Text(
                    'Checking authentication...',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        // If user is logged in, go to dashboard
        if (authProvider.isLoggedIn && authProvider.currentUser != null) {
          debugPrint(
            '✅ User is authenticated: ${authProvider.currentUser!.id}',
          );
          return const StartupDashboard();
        }

        // If not logged in, go to welcome page
        debugPrint('❌ User is not authenticated - showing welcome page');
        return const WelcomePage();
      },
    );
  }
}

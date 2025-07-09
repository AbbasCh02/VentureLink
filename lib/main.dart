// lib/main.dart
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import 'package:venturelink/Investor/Investor_Dashboard/investor_company_page.dart';
import "homepage.dart";
import "Startup/Providers/startup_profile_overview_provider.dart";
import "Startup/Providers/startup_profile_provider.dart";
import "Startup/Providers/team_members_provider.dart";
import 'Startup/Providers/business_model_canvas_provider.dart';
import 'auth/unified_authentication_provider.dart';
import 'Startup/Startup_Dashboard/profile_overview.dart';
import 'Startup/Startup_Dashboard/startup_profile_page.dart';
import 'Startup/Startup_Dashboard/team_members_page.dart';
import 'Startup/Startup_Dashboard/Business_Model_Canvas/business_model_canvas.dart';
import 'Startup/Startup_Dashboard/startup_dashboard.dart';
import 'Investor/Investor_Dashboard/investor_dashboard.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/unified_login.dart';
import 'auth/unified_signup.dart';
import 'Investor/Investor_Dashboard/investor_profile_page.dart';
import 'Investor/Providers/investor_profile_provider.dart';
import 'Investor/Providers/investor_company_provider.dart'; // ADD THIS IMPORT
import 'Investor/Investor_Dashboard/investor_bio.dart';

Future<void> main() async {
  try {
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
  } catch (e) {
    debugPrint('❌ Error during app initialization: $e');
    // Still run the app but with error handling
    runApp(ErrorApp(error: e.toString()));
  }
}

// Error app to show initialization errors
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 20),
                const Text(
                  'Initialization Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  error,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // CRITICAL: Unified Authentication Provider MUST be first
        ChangeNotifierProvider(
          create: (context) => UnifiedAuthProvider(),
          lazy: true, // Initialize immediately
        ),

        // Profile Overview Provider (company details: name, tagline, industry, region)
        ChangeNotifierProvider(
          create: (context) => StartupProfileOverviewProvider(),
          lazy: true,
        ),

        // Startup Profile Provider (funding, idea, pitch deck, profile image)
        ChangeNotifierProvider(
          create: (context) => StartupProfileProvider(),
          lazy: true,
        ),

        // Team Members Provider (team management)
        ChangeNotifierProvider(
          create: (context) => TeamMembersProvider(),
          lazy: true,
        ),

        // Business Model Canvas Provider
        ChangeNotifierProvider(
          create: (context) => BusinessModelCanvasProvider(),
          lazy: true,
        ),

        // Investor Profile Provider
        ChangeNotifierProvider(
          create: (context) => InvestorProfileProvider(),
          lazy: true,
        ),

        // ADD THIS: Investor Companies Provider
        ChangeNotifierProvider(
          create: (context) => InvestorCompaniesProvider(),
          lazy: true,
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
        home: const AuthWrapper(),
        routes: {
          // Startup Routes
          '/profile-overview': (context) => const ProfileOverview(),
          '/startup-profile': (context) => const StartupProfilePage(),
          '/team-members': (context) => const TeamMembersPage(),
          '/business_model': (context) => const BusinessModelCanvas(),
          '/startup-dashboard': (context) => const StartupDashboard(),

          // Investor Routes
          '/investor-dashboard': (context) => const InvestorDashboard(),
          '/investor-profile': (context) => const InvestorProfilePage(),
          '/investor-bio': (context) => const InvestorBio(),
          '/investor-companies':
              (context) =>
                  const InvestorCompanyPage(), // FIX: Use correct class name
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
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF0a0a0a),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF65c6f4)),
              ),
            ),
          );
        }

        // Show error if there's an authentication error
        if (authProvider.error != null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Authentication Error',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      authProvider.error!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        authProvider.clearError();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF65c6f4),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // If user is authenticated, determine their role and navigate accordingly
        if (authProvider.isLoggedIn && authProvider.currentUser != null) {
          final userType = authProvider.currentUser!.userType;

          if (userType == UserType.startup) {
            // Initialize investor providers before showing dashboard
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeStartupProvidersOnLogin(context);
            });
            return const StartupDashboard();
          } else if (userType == UserType.investor) {
            // Initialize investor providers before showing dashboard
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeInvestorProvidersOnLogin(context);
            });
            return const InvestorDashboard();
          }
        }

        // If not authenticated or role is unclear, show welcome page
        return const WelcomePage();
      },
    );
  }

  Future<void> _initializeInvestorProvidersOnLogin(BuildContext context) async {
    try {
      final profileProvider = context.read<InvestorProfileProvider>();
      final companyProvider = context.read<InvestorCompaniesProvider>();

      // Load both providers simultaneously
      Future.wait([profileProvider.initialize(), companyProvider.initialize()]);
    } catch (e) {
      debugPrint('Error initializing investor providers on login: $e');
    }
  }

  void _initializeStartupProvidersOnLogin(BuildContext context) {
    try {
      final profileProvider = context.read<StartupProfileProvider>();
      final profileOverviewProvider =
          context.read<StartupProfileOverviewProvider>();
      final bmcProvider = context.read<BusinessModelCanvasProvider>();
      final teamMembersProvider = context.read<TeamMembersProvider>();

      Future.wait([
        profileProvider.initialize(),
        profileOverviewProvider.initialize(),
        bmcProvider.initialize(),
        teamMembersProvider.initialize(),
      ]);
    } catch (e) {
      debugPrint('Error initializing investor providers on login: $e');
    }
  }
}

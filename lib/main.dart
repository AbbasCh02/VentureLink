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
import 'Investor/Providers/investor_company_provider.dart';
import 'Investor/Investor_Dashboard/investor_bio.dart';

/**
 * VentureLink Application Entry Point
 * 
 * Implements the main application initialization and configuration for the VentureLink platform.
 * Provides comprehensive startup sequence, environment configuration, and error handling.
 * 
 * Core Features:
 * - Complete application initialization with environment variable loading
 * - Supabase backend integration with comprehensive error handling
 * - Multi-provider state management architecture for scalable application state
 * - Unified authentication system with role-based routing and access control
 * - Comprehensive error handling with user-friendly error displays and recovery options
 * - Dark theme configuration with professional color schemes
 * - Route management for both startup and investor user journeys
 * - Provider initialization with lazy loading for optimal performance
 * - Authentication wrapper for seamless user experience and security
 * - Role-based dashboard routing with provider initialization
 * - Graceful degradation with error recovery mechanisms
 * - Debug logging for development and production monitoring
 */

/**
 * Main application entry point with comprehensive initialization sequence.
 * Handles environment setup, Supabase configuration, and error recovery.
 * Provides robust initialization with fallback error handling for production stability.
 */
Future<void> main() async {
  try {
    // Ensure Flutter framework is properly initialized before proceeding
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables from .env file for secure configuration management
    await dotenv.load(fileName: ".env");

    // Validate critical environment variables for backend connectivity
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception(
        'Missing Supabase environment variables. Please check your .env file.',
      );
    }

    // Initialize Supabase backend with validated credentials
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

    debugPrint('✅ Supabase initialized successfully');
    debugPrint('✅ Environment variables loaded');

    // Launch main application with proper initialization
    runApp(const MyApp());
  } catch (e) {
    debugPrint('❌ Error during app initialization: $e');
    // Graceful degradation: run error app with recovery options
    runApp(ErrorApp(error: e.toString()));
  }
}

/**
 * Error application widget for handling initialization failures.
 * Provides user-friendly error display with recovery mechanisms and retry functionality.
 * Ensures application remains functional even when critical initialization fails.
 */
class ErrorApp extends StatelessWidget {
  /**
   * The error message to display to the user with context and guidance.
   */
  final String error;

  const ErrorApp({super.key, required this.error});

  /**
   * Builds the error application interface with recovery options.
   * Provides clear error communication and retry functionality for user recovery.
   * 
   * @return Widget containing the error display with retry mechanism
   */
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
                    // Attempt application restart for error recovery
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

/**
 * Main application widget implementing comprehensive VentureLink platform architecture.
 * Integrates multi-provider state management, routing, theming, and authentication systems.
 * Provides the foundation for both startup and investor user experiences.
 */
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /**
   * Builds the main application with complete provider hierarchy and routing configuration.
   * Implements comprehensive state management architecture with lazy loading optimization.
   * 
   * @return Widget containing the complete VentureLink application structure
   */
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // CRITICAL: Unified Authentication Provider - foundational provider that must be first
        // Manages authentication state, user sessions, and role-based access control
        ChangeNotifierProvider(
          create: (context) => UnifiedAuthProvider(),
          lazy: true, // Immediate initialization for authentication state
        ),

        // Startup Ecosystem Providers - manages complete startup profile and operations

        // Profile Overview Provider - handles company details: name, tagline, industry, region
        ChangeNotifierProvider(
          create: (context) => StartupProfileOverviewProvider(),
          lazy: true,
        ),

        // Startup Profile Provider - manages funding, idea, pitch deck, and profile image
        ChangeNotifierProvider(
          create: (context) => StartupProfileProvider(),
          lazy: true,
        ),

        // Team Members Provider - handles team management and member coordination
        ChangeNotifierProvider(
          create: (context) => TeamMembersProvider(),
          lazy: true,
        ),

        // Business Model Canvas Provider - manages strategic business planning
        ChangeNotifierProvider(
          create: (context) => BusinessModelCanvasProvider(),
          lazy: true,
        ),

        // Investor Ecosystem Providers - manages complete investor profile and operations

        // Investor Profile Provider - handles investor personal and professional information
        ChangeNotifierProvider(
          create: (context) => InvestorProfileProvider(),
          lazy: true,
        ),

        // Investor Companies Provider - manages investment portfolio and company tracking
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
        // Use unified authentication wrapper for seamless user experience
        home: const AuthWrapper(),
        routes: {
          // Startup User Journey Routes - complete startup management ecosystem
          '/profile-overview': (context) => const ProfileOverview(),
          '/startup-profile': (context) => const StartupProfilePage(),
          '/team-members': (context) => const TeamMembersPage(),
          '/business_model': (context) => const BusinessModelCanvas(),
          '/startup-dashboard': (context) => const StartupDashboard(),

          // Investor User Journey Routes - complete investor management ecosystem
          '/investor-dashboard': (context) => const InvestorDashboard(),
          '/investor-profile': (context) => const InvestorProfilePage(),
          '/investor-bio': (context) => const InvestorBio(),
          '/investor-companies': (context) => const InvestorCompanyPage(),

          // Unified Authentication Routes - secure authentication system
          '/signup': (context) => const UnifiedSignupPage(),
          '/login': (context) => const UnifiedLoginPage(),

          // General Application Routes - common navigation destinations
          '/welcome': (context) => const WelcomePage(),
        },
      ),
    );
  }
}

/**
 * Unified authentication wrapper that manages role-based routing and access control.
 * Provides seamless user experience with automatic navigation based on authentication state and user type.
 * Handles loading states, error recovery, and provider initialization for optimal performance.
 */
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  /**
   * Builds the authentication wrapper with comprehensive state management and routing logic.
   * Implements role-based navigation, loading states, error handling, and provider initialization.
   * 
   * @return Widget containing the appropriate interface based on authentication state
   */
  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        // Display loading interface while authentication state is being determined
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

        // Display error interface with recovery options for authentication failures
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

        // Handle authenticated users with role-based routing and provider initialization
        if (authProvider.isLoggedIn && authProvider.currentUser != null) {
          final userType = authProvider.currentUser!.userType;

          if (userType == UserType.startup) {
            // Initialize startup-specific providers and navigate to startup dashboard
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeStartupProvidersOnLogin(context);
            });
            return const StartupDashboard();
          } else if (userType == UserType.investor) {
            // Initialize investor-specific providers and navigate to investor dashboard
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeInvestorProvidersOnLogin(context);
            });
            return const InvestorDashboard();
          }
        }

        // Default navigation for unauthenticated users or unclear authentication state
        return const WelcomePage();
      },
    );
  }

  /**
   * Initializes investor-specific providers after successful authentication.
   * Loads investor profile and company data simultaneously for optimal performance.
   * Provides error handling for provider initialization failures.
   * 
   * @param context The BuildContext for provider access and error handling
   */
  Future<void> _initializeInvestorProvidersOnLogin(BuildContext context) async {
    try {
      final profileProvider = context.read<InvestorProfileProvider>();
      final companyProvider = context.read<InvestorCompaniesProvider>();

      // Load both providers simultaneously for faster initialization
      await Future.wait([
        profileProvider.initialize(),
        companyProvider.initialize(),
      ]);
    } catch (e) {
      debugPrint('Error initializing investor providers on login: $e');
    }
  }

  /**
   * Initializes startup-specific providers after successful authentication.
   * Loads all startup-related data including profile, team, and business model information.
   * Provides comprehensive error handling for provider initialization failures.
   * 
   * @param context The BuildContext for provider access and error handling
   */
  Future<void> _initializeStartupProvidersOnLogin(BuildContext context) async {
    try {
      final profileProvider = context.read<StartupProfileProvider>();
      final profileOverviewProvider =
          context.read<StartupProfileOverviewProvider>();
      final bmcProvider = context.read<BusinessModelCanvasProvider>();
      final teamMembersProvider = context.read<TeamMembersProvider>();

      // Load all startup providers simultaneously for optimal user experience
      await Future.wait([
        profileProvider.initialize(),
        profileOverviewProvider.initialize(),
        bmcProvider.initialize(),
        teamMembersProvider.initialize(),
      ]);
    } catch (e) {
      debugPrint('Error initializing startup providers on login: $e');
    }
  }
}

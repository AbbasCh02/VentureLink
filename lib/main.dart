import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "homepage.dart";
import "Startup/Providers/startup_profile_overview_provider.dart";
import "Startup/Providers/startup_profile_provider.dart";
import "Startup/Providers/team_members_provider.dart";
import 'Startup/Providers/business_model_canvas_provider.dart';
import 'Startup/Providers/startup_authentication_provider.dart';
import 'Investor/Providers/investor_authentication_provider.dart';
import 'Startup/Startup_Dashboard/profile_overview.dart';
import 'Startup/Startup_Dashboard/startup_profile_page.dart';
import 'Startup/Startup_Dashboard/team_members_page.dart';
import 'Startup/Startup_Dashboard/Business_Model_Canvas/business_model_canvas.dart';
import 'Startup/Startup_Dashboard/startup_dashboard.dart';
import 'Investor/investor_dashboard.dart';
import 'Investor/investor_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Startup/startup_page.dart';
import 'Startup/signup_startup.dart';
import 'Startup/login_startup.dart';
import 'Investor/signup_investor.dart';
import 'Investor/login_investor.dart';
import 'services/user_type_service.dart';

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
        // CRITICAL: Authentication Providers MUST be first
        // All other providers depend on user authentication state
        ChangeNotifierProvider(
          create: (context) => StartupAuthProvider(),
          lazy: false, // Initialize immediately
        ),

        // This provider handles investor-specific authentication
        ChangeNotifierProvider(
          create: (context) => InvestorAuthProvider(),
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
        // Use FIXED AuthWrapper that handles both user types
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
          '/investor-page': (context) => const InvestorPage(),
          '/signup_investor': (context) => const InvestorSignupPage(),
          '/login_investor': (context) => const InvestorLoginPage(),
          '/investor-dashboard': (context) => const InvestorDashboard(),
          '/welcome': (context) => const WelcomePage(),
        },
      ),
    );
  }
}

// CRITICAL FIX: AuthWrapper widget to handle user type isolation and auto-login logic
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasInitializedProviders = false;
  String? _detectedUserType;
  bool _isCheckingUserType = false;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    if (_hasInitializedProviders) return;

    try {
      // Initialize both authentication providers
      final startupAuthProvider = context.read<StartupAuthProvider>();
      final investorAuthProvider = context.read<InvestorAuthProvider>();

      // Check if either user is already logged in
      await Future.wait([
        startupAuthProvider.checkAuthState(),
        investorAuthProvider.checkAuthState(),
      ]);

      _hasInitializedProviders = true;

      // Detect user type if someone is logged in
      await _detectAndRouteUser();
    } catch (e) {
      debugPrint('❌ Error initializing providers: $e');
      if (mounted) {
        setState(() {
          _hasInitializedProviders = true;
        });
      }
    }
  }

  Future<void> _detectAndRouteUser() async {
    if (_isCheckingUserType) return;

    setState(() {
      _isCheckingUserType = true;
    });

    try {
      final startupAuthProvider = context.read<StartupAuthProvider>();
      final investorAuthProvider = context.read<InvestorAuthProvider>();

      // Check if startup user is logged in
      if (startupAuthProvider.isLoggedIn &&
          startupAuthProvider.currentUser != null) {
        final userId = startupAuthProvider.currentUser!.id;
        debugPrint('🔍 Checking user type for startup user: $userId');

        final userType = await UserTypeService.detectUserType(userId);

        if (userType == 'startup') {
          debugPrint('✅ Confirmed startup user, staying on startup dashboard');
          setState(() {
            _detectedUserType = 'startup';
            _isCheckingUserType = false;
          });
          return;
        } else {
          debugPrint('❌ Startup auth but not startup user, logging out');
          await startupAuthProvider.logout();
        }
      }

      // Check if investor user is logged in
      if (investorAuthProvider.isLoggedIn &&
          investorAuthProvider.currentUser != null) {
        final userId = investorAuthProvider.currentUser!.id;
        debugPrint('🔍 Checking user type for investor user: $userId');

        final userType = await UserTypeService.detectUserType(userId);

        if (userType == 'investor') {
          debugPrint(
            '✅ Confirmed investor user, routing to investor dashboard',
          );
          setState(() {
            _detectedUserType = 'investor';
            _isCheckingUserType = false;
          });
          return;
        } else {
          debugPrint('❌ Investor auth but not investor user, logging out');
          await investorAuthProvider.logout();
        }
      }

      // No valid user found
      setState(() {
        _detectedUserType = null;
        _isCheckingUserType = false;
      });
    } catch (e) {
      debugPrint('❌ Error detecting user type: $e');
      setState(() {
        _detectedUserType = null;
        _isCheckingUserType = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<StartupAuthProvider, InvestorAuthProvider>(
      builder: (context, startupAuth, investorAuth, child) {
        // Show loading screen while initializing or checking user type
        if (!_hasInitializedProviders ||
            _isCheckingUserType ||
            startupAuth.isLoading ||
            investorAuth.isLoading) {
          return const AuthLoadingScreen();
        }

        // Route based on detected user type and authentication state
        if (_detectedUserType == 'startup' &&
            startupAuth.isLoggedIn &&
            startupAuth.currentUser != null) {
          debugPrint('🏢 Routing to Startup Dashboard');
          return const StartupDashboard();
        }

        if (_detectedUserType == 'investor' &&
            investorAuth.isLoggedIn &&
            investorAuth.currentUser != null) {
          debugPrint('💼 Routing to Investor Dashboard');
          return const InvestorDashboard();
        }

        // No authenticated user or failed authentication - show welcome page
        debugPrint('🏠 Routing to Welcome Page');
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
              // Logo
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
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/VentureLink LogoAlone 2.0.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),

              // Loading indicator
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF65c6f4)),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),

              // Loading text
              Text(
                'Checking authentication...',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

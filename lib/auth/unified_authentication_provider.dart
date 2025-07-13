// lib/auth/unified_authentication_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../services/user_type_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **User Types Enumeration**
/// Defines the two types of users in the VentureLink application
enum UserType { startup, investor }

/// **Generic User Model**
/// Represents both startup and investor users with common properties
/// This unified model allows the app to handle both user types seamlessly
class AppUser {
  final String id; // Unique user identifier from Supabase
  final String fullName; // User's display name
  final String email; // User's email address
  final DateTime createdAt; // Account creation timestamp
  final DateTime lastLoginAt; // Last login timestamp
  final bool isVerified; // Email verification status
  final UserType userType; // Whether user is startup or investor

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.createdAt,
    required this.lastLoginAt,
    required this.isVerified,
    required this.userType,
  });

  /// **Factory Constructor from Supabase User**
  /// Converts Supabase auth user to our AppUser model
  /// Takes UserType parameter to maintain type consistency
  factory AppUser.fromSupabaseUser(User user, UserType userType) {
    return AppUser(
      id: user.id,
      fullName: user.userMetadata?['full_name'] as String? ?? '',
      email: user.email ?? '',
      lastLoginAt: DateTime.now(),
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      isVerified: user.emailConfirmedAt != null,
      userType: userType,
    );
  }

  /// **Copy With Method**
  /// Creates a new AppUser instance with updated properties
  /// Useful for updating user data without mutating existing object
  AppUser copyWith({
    String? id,
    String? fullName,
    String? email,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isVerified,
    UserType? userType,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isVerified: isVerified ?? this.isVerified,
      userType: userType ?? this.userType,
    );
  }
}

/// **Form Type Enumeration**
/// Distinguishes between login and signup forms in the UI
enum FormType { login, signup }

/// **Password Strength Enumeration**
/// Used for real-time password strength validation feedback
enum PasswordStrength { none, weak, medium, strong }

/// **Unified Authentication Provider Class**
/// Main provider that handles both startup and investor authentication
/// Features:
/// - User type selection during signup
/// - Automatic user type detection during login
/// - Form validation and state management
/// - Remember me functionality
/// - Supabase integration for auth and database operations
class UnifiedAuthProvider with ChangeNotifier {
  final Logger _logger = Logger(); // For debugging and error tracking
  final SupabaseClient _supabase =
      Supabase.instance.client; // Supabase client instance

  // ========== FORM MANAGEMENT CONTROLLERS ==========
  // Text controllers for form input fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Form keys for validation
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _signupFormKey = GlobalKey<FormState>();

  // Focus nodes for managing input field focus
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  // ========== UI STATE VARIABLES ==========
  bool _isPasswordVisible = false; // Controls password field visibility toggle
  bool _isConfirmPasswordVisible =
      false; // Controls confirm password field visibility toggle
  bool _isFormValid = false; // Overall form validation state
  FormType _currentFormType =
      FormType.login; // Current form type (login/signup)

  // ========== VALIDATION STATE ==========
  String? _nameError; // Name field validation error message
  String? _emailError; // Email field validation error message
  String? _passwordError; // Password field validation error message
  String?
  _confirmPasswordError; // Confirm password field validation error message
  bool _validateRealTime = false; // Whether to validate fields in real-time
  Timer? _validationTimer; // Timer for debounced validation

  // ========== AUTHENTICATION STATE ==========
  AppUser? _currentUser; // Currently authenticated user
  bool _isLoggedIn = false; // Authentication status
  bool _isLoading = false; // General loading state
  bool _isAuthenticating =
      false; // Specific authentication operation loading state
  String? _error; // Current error message

  // ========== REMEMBER ME FUNCTIONALITY ==========
  bool _rememberMe = false; // Remember me checkbox state
  String? _savedEmail; // Saved email for remember me feature
  SharedPreferences? _prefs; // Local storage for persistent data

  // ========== USER TYPE MANAGEMENT ==========
  UserType? _selectedUserType; // Selected user type during signup

  // ========== CRITICAL FLAGS ==========
  bool _isCreatingUserRecord = false; // Prevents duplicate user record creation

  // ========== SUPABASE INTEGRATION ==========
  StreamSubscription<AuthState>?
  _authSubscription; // Supabase auth state listener

  // ========== SHARED PREFERENCES KEYS ==========
  static const String _keyRememberMe =
      'remember_me'; // Key for remember me preference
  static const String _keySavedEmail = 'saved_email'; // Key for saved email
  static const String _keyAutoLogin =
      'auto_login'; // Key for auto-login preference

  /// **Constructor**
  /// Initializes the provider and sets up necessary listeners and auth state
  UnifiedAuthProvider() {
    _initializeAuth(); // Initialize authentication state
    _initializeListeners(); // Set up Supabase auth listeners
    _setupControllerListeners(); // Set up form field listeners for real-time validation
  }

  // ========== GETTER METHODS ==========
  // **Form Controllers and Keys**
  // These getters expose form controllers to UI widgets for binding input fields
  TextEditingController get nameController => _nameController;
  TextEditingController get emailController => _emailController;
  TextEditingController get passwordController => _passwordController;
  TextEditingController get confirmPasswordController =>
      _confirmPasswordController;

  // Form keys for validation - exposed to UI for form submission handling
  GlobalKey<FormState> get loginFormKey => _loginFormKey;
  GlobalKey<FormState> get signupFormKey => _signupFormKey;

  // **Focus Nodes**
  // Exposed to UI for managing input field focus and keyboard navigation
  FocusNode get nameFocusNode => _nameFocusNode;
  FocusNode get emailFocusNode => _emailFocusNode;
  FocusNode get passwordFocusNode => _passwordFocusNode;
  FocusNode get confirmPasswordFocusNode => _confirmPasswordFocusNode;

  // **UI State Getters**
  // Control password visibility toggles in form fields
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  bool get isFormValid => _isFormValid; // Overall form validation status
  FormType get currentFormType =>
      _currentFormType; // Current form type (login/signup)

  // **Validation Error Getters - ESSENTIAL FOR UI FEEDBACK**
  // These provide real-time validation error messages to display under form fields
  String? get nameError => _nameError;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get confirmPasswordError => _confirmPasswordError;
  bool get validateRealTime =>
      _validateRealTime; // Whether real-time validation is active

  // **Form Value Getters**
  // Processed form field values (trimmed and cleaned)
  String get fullName => _nameController.text.trim();
  String get email => _emailController.text.trim();
  String get password => _passwordController.text;
  String get confirmPassword => _confirmPasswordController.text;

  // **Authentication State Getters**
  // Core authentication status and user information
  AppUser? get currentUser =>
      _currentUser; // Currently authenticated user object
  bool get isLoggedIn => _isLoggedIn; // Authentication status
  bool get isLoading => _isLoading; // General loading state
  bool get isAuthenticating =>
      _isAuthenticating; // Specific auth operation loading
  String? get error => _error; // Current error message
  bool get rememberMe => _rememberMe; // Remember me checkbox state
  String? get savedEmail => _savedEmail; // Saved email from remember me
  UserType? get selectedUserType =>
      _selectedUserType; // Selected user type for signup

  // ========== INITIALIZATION METHODS ==========

  /// **Initialize Authentication State**
  /// Sets up the initial authentication state and checks for existing sessions
  /// Called automatically when provider is created
  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Initialize SharedPreferences for persistent storage
      _prefs = await SharedPreferences.getInstance();

      // Load saved remember me preferences
      _rememberMe = _prefs?.getBool(_keyRememberMe) ?? false;
      _savedEmail = _prefs?.getString(_keySavedEmail);

      // Pre-fill email if remembered
      if (_savedEmail != null && _savedEmail!.isNotEmpty) {
        _emailController.text = _savedEmail!;
      }

      // Check for existing Supabase session
      final session = _supabase.auth.currentSession;
      if (session?.user != null) {
        _logger.i('🔍 Existing session found for: ${session!.user.email}');
        // Note: User type detection and setup will be handled by auth listener
      } else {
        _logger.i('🔍 No existing session found');
      }
    } catch (e) {
      _logger.e('❌ Error initializing auth: $e');
      _error = 'Failed to initialize authentication';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// **Initialize Supabase Authentication Listeners**
  /// Sets up real-time listening for authentication state changes
  /// Handles sign in, sign out, and session recovery automatically
  void _initializeListeners() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final User? user = data.session?.user;

      _logger.i('🔍 Auth state changed: ${event.name}');

      // Handle different authentication events
      switch (event) {
        case AuthChangeEvent.signedIn:
          if (user != null) {
            _logger.i('✅ User signed in: ${user.email}');
            _handleSignedInUser(user); // Process the signed-in user
          }
          break;
        case AuthChangeEvent.signedOut:
          _logger.i('👋 User signed out');
          _handleSignedOutUser(); // Clean up user state
          break;
        case AuthChangeEvent.tokenRefreshed:
          _logger.i('🔄 Token refreshed');
          if (user != null && _currentUser != null) {
            // Update current user with refreshed token data
            _currentUser = _currentUser!.copyWith(lastLoginAt: DateTime.now());
            _logger.i('User updated: ${_currentUser!.email}');
          }
          break;
        case AuthChangeEvent.passwordRecovery:
          _logger.i('Password recovery initiated');
          break;
        default:
          _logger.i('Auth event: ${event.name}');
      }
      notifyListeners(); // CRITICAL: Always notify listeners for route changes
    });
  }

  /// **Handle Signed In User Processing**
  /// Processes user after successful sign in, determines user type, and creates/updates user records
  Future<void> _handleSignedInUser(User user) async {
    try {
      UserType? userType;

      // Determine user type: use selected type (signup) or detect existing type (login)
      if (_selectedUserType != null) {
        userType = _selectedUserType!;
        debugPrint('🔍 Using selected user type: ${userType.name}');
      } else {
        // Detect existing user type for login
        final userTypeString = await UserTypeService.detectUserType(user.id);
        if (userTypeString != null) {
          userType =
              userTypeString == 'startup'
                  ? UserType.startup
                  : UserType.investor;
          debugPrint('🔍 Detected user type: ${userType.name}');
        }
      }

      if (userType != null) {
        _currentUser = AppUser.fromSupabaseUser(user, userType);
        _currentUser = _currentUser!.copyWith(
          isVerified: true,
        ); // Always mark as verified
        _isLoggedIn = true;
        _error = null;

        // CRITICAL: Only create/update user record if not already in progress
        // Prevents duplicate database operations
        if (!_isCreatingUserRecord) {
          debugPrint(
            '🔥 Auth state listener calling _createOrUpdateUserRecord...',
          );
          await _createOrUpdateUserRecord(_currentUser!);
        } else {
          debugPrint('🔍 Skipping user record creation - already in progress');
          // Set a timer to retry if the flag is still set (safety mechanism)
          Timer(const Duration(seconds: 1), () async {
            if (_isCreatingUserRecord) {
              debugPrint('🔄 Retrying user record creation after timeout...');
              _isCreatingUserRecord = false; // Reset flag
              await _createOrUpdateUserRecord(_currentUser!);
            }
          });
        }

        // Handle remember me functionality
        if (_rememberMe && _savedEmail != user.email) {
          await _saveRememberMe(user.email!);
        }

        _logger.i('✅ User authentication completed: ${user.email}');
      } else {
        _logger.e('❌ Could not determine user type for: ${user.email}');
        _error = 'Could not determine account type. Please contact support.';
        await signOut(); // Sign out invalid user
      }
    } catch (e) {
      _logger.e('❌ Error handling signed in user: $e');
      _error = 'Failed to complete sign in process';
    }
  }

  /// **Handle Signed Out User Cleanup**
  /// Cleans up user state and resets authentication variables after sign out
  void _handleSignedOutUser() {
    _currentUser = null;
    _isLoggedIn = false;
    _selectedUserType = null;
    _isCreatingUserRecord = false;
    _error = null;

    // Don't clear form data on logout - allows for quick re-login
    // Only clear sensitive data
    _passwordController.clear();
    _confirmPasswordController.clear();

    _logger.i('✅ User state cleaned up after sign out');
  }

  /// **Auto-Login Management**
  /// Handles automatic login functionality for remember me feature
  Future<void> _saveAutoLogin() async {
    try {
      await _prefs?.setBool(_keyAutoLogin, true);
      _logger.i('✅ Auto-login enabled');
    } catch (e) {
      _logger.e('❌ Error saving auto-login: $e');
    }
  }

  Future<void> _clearAutoLogin() async {
    try {
      await _prefs?.setBool(_keyAutoLogin, false);
      _logger.i('✅ Auto-login disabled');
    } catch (e) {
      _logger.e('❌ Error clearing auto-login: $e');
    }
  }

  /// **Setup Form Field Listeners**
  /// Configures real-time validation listeners for form fields
  /// Enables immediate feedback as user types
  void _setupControllerListeners() {
    _emailController.addListener(() {
      if (_validateRealTime) {
        _emailError = validateEmail(_emailController.text);
        notifyListeners();
      }
    });

    _passwordController.addListener(() {
      if (_validateRealTime) {
        _passwordError = validatePassword(_passwordController.text);
        notifyListeners();
      }
    });

    _nameController.addListener(() {
      if (_validateRealTime) {
        _nameError = validateFullName(_nameController.text);
        notifyListeners();
      }
    });

    _confirmPasswordController.addListener(() {
      if (_validateRealTime) {
        _confirmPasswordError = validateConfirmPassword(
          _passwordController.text,
          _confirmPasswordController.text,
        );
        notifyListeners();
      }
    });
  }

  // ========== CORE AUTHENTICATION METHODS ==========

  /// **Sign Up Method**
  /// Creates a new user account with Supabase and stores user record in appropriate table
  /// Supports both startup and investor account creation
  Future<bool> signUp({
    String? fullName,
    String? email,
    String? password,
    String? confirmPassword,
    UserType? userType,
  }) async {
    // Use provided values or fall back to controller values
    if (fullName != null) _nameController.text = fullName;
    if (email != null) _emailController.text = email;
    if (password != null) _passwordController.text = password;
    if (confirmPassword != null) {
      _confirmPasswordController.text = confirmPassword;
    }
    if (userType != null) _selectedUserType = userType;

    // Validate that user type is selected (required for signup)
    if (_selectedUserType == null) {
      _error = 'Please select whether you are a startup or investor';
      notifyListeners();
      return false;
    }

    // Validate all form fields before proceeding
    if (!_validateSignupForm()) return false;

    _isAuthenticating = true;
    _error = null;
    notifyListeners();

    try {
      _logger.i(
        'Attempting signup for: ${this.email} as ${_selectedUserType!.name}',
      );

      // Create Supabase auth user without email confirmation requirement
      final response = await _supabase.auth.signUp(
        email: this.email,
        password: this.password,
        emailRedirectTo:
            null, // Remove email confirmation redirect for immediate access
        data: {
          'full_name': fullName ?? this.fullName,
          'email': email ?? this.email,
          'user_type': _selectedUserType!.name,
        },
      );

      if (response.user != null) {
        _logger.i('✅ Supabase signup successful for: ${this.email}');
        // User authentication state will be handled by auth listener
        // which will call _handleSignedInUser and create user record
        return true;
      } else {
        _error = 'Failed to create account. Please try again.';
        return false;
      }
    } catch (e) {
      _logger.e('❌ Signup error: $e');
      _error = _getErrorMessage(e);
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// **Sign In Method**
  /// Authenticates existing user with email and password
  /// Automatically detects user type and loads appropriate dashboard
  Future<bool> signIn({
    String? email,
    String? password,
    bool? rememberMe,
  }) async {
    // Use provided values or fall back to controller values
    if (email != null) _emailController.text = email;
    if (password != null) _passwordController.text = password;
    if (rememberMe != null) _rememberMe = rememberMe;

    // Validate login form fields
    if (!_validateLoginForm()) return false;

    _isAuthenticating = true;
    _error = null;
    notifyListeners();

    try {
      _logger.i('Attempting login for: ${this.email}');

      // Authenticate with Supabase
      final response = await _supabase.auth.signInWithPassword(
        email: this.email,
        password: this.password,
      );

      if (response.user != null) {
        _logger.i('✅ Login successful for: ${this.email}');

        // Handle remember me functionality
        if (_rememberMe) {
          await _saveRememberMe(this.email);
          await _saveAutoLogin();
        }

        // User state will be handled by auth listener
        return true;
      } else {
        _error = 'Login failed. Please check your credentials.';
        return false;
      }
    } catch (e) {
      _logger.e('❌ Login error: $e');
      _error = _getErrorMessage(e);
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// **Sign Out Method**
  /// Signs out current user and cleans up authentication state
  Future<bool> signOut() async {
    try {
      await _clearAutoLogin(); // Clear auto-login preference
      await _supabase.auth.signOut(); // Sign out from Supabase
      clearForm(); // Clear form data
      return true;
    } catch (e) {
      _logger.e('❌ Sign out error: $e');
      _error = 'Failed to sign out';
      return false;
    }
  }

  // ========== USER RECORD MANAGEMENT ==========

  /// **Create or Update User Record**
  /// Creates user record in appropriate database table (startups/investors)
  /// Updates existing records if user already exists
  /// CRITICAL: Prevents duplicate user record creation with flag
  Future<void> _createOrUpdateUserRecord(AppUser user) async {
    if (_isCreatingUserRecord) {
      debugPrint('🔍 User record creation already in progress, skipping...');
      return;
    }

    _isCreatingUserRecord = true;

    try {
      // Determine correct table based on user type
      final tableName =
          user.userType == UserType.startup ? 'startups' : 'investors';
      debugPrint(
        '🔍 Managing user record in $tableName table for: ${user.email}',
      );

      // Check if user record already exists
      final existingUser =
          await _supabase
              .from(tableName)
              .select('id, email, username')
              .eq('id', user.id)
              .maybeSingle();

      if (existingUser == null) {
        // Create new user record
        debugPrint('🆕 Creating new user record for: ${user.email}');
        await _supabase.from(tableName).insert({
          'id': user.id,
          'email': user.email,
          'username': user.fullName,
          'created_at': user.createdAt.toIso8601String(),
        });
        debugPrint('✅ Created new user record for ${user.email}');
        _logger.i(
          '✅ Created new ${user.userType.name} record for: ${user.email}',
        );
      } else {
        // Update existing user record if needed
        debugPrint('🔍 User record exists, checking for updates...');
        final Map<String, dynamic> updateData = {};

        // Update email if different
        if (existingUser['email'] != user.email) {
          updateData['email'] = user.email;
          debugPrint(
            '🔄 Updating email from "${existingUser['email']}" to "${user.email}"',
          );
        }

        // Update username if different
        if (existingUser['username'] != user.fullName) {
          final currentUsername = existingUser['username'] ?? '';
          if (currentUsername != user.fullName) {
            updateData['username'] = user.fullName;
            debugPrint(
              '🔄 Updating username from "$currentUsername" to "${user.fullName}"',
            );
          }
        }

        // Apply updates if any changes detected
        if (updateData.isNotEmpty) {
          await _supabase.from(tableName).update(updateData).eq('id', user.id);
          debugPrint('✅ Updated user record for ${user.email}');
          _logger.i(
            '✅ Updated ${user.userType.name} record for: ${user.email}',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error in user record operation: $e');

      // Handle duplicate key error gracefully (user already exists)
      if (e.toString().contains('duplicate key') ||
          e.toString().contains('23505')) {
        debugPrint('🔍 User record already exists (duplicate key)');
        _logger.i('User record already exists for: ${user.email}');
        return;
      }

      throw Exception('Failed to manage ${user.userType.name} user record: $e');
    } finally {
      _isCreatingUserRecord = false; // Always reset flag
    }
  }

  // ========== FORM VALIDATION METHODS ==========

  /// **Login Form Validation**
  /// Validates email and password fields for login
  bool _validateLoginForm() {
    bool isValid = true;
    _emailError = validateEmail(email);
    if (_emailError != null) isValid = false;
    _passwordError = validatePassword(password);
    if (_passwordError != null) isValid = false;
    _isFormValid = isValid;
    notifyListeners();
    return isValid;
  }

  /// **Signup Form Validation**
  /// Validates all required fields for account creation
  bool _validateSignupForm() {
    bool isValid = true;
    _nameError = validateFullName(fullName);
    if (_nameError != null) isValid = false;
    _emailError = validateEmail(email);
    if (_emailError != null) isValid = false;
    _passwordError = validatePassword(password);
    if (_passwordError != null) isValid = false;
    _confirmPasswordError = validateConfirmPassword(password, confirmPassword);
    if (_confirmPasswordError != null) isValid = false;
    _isFormValid = isValid;
    notifyListeners();
    return isValid;
  }

  /// **Individual Field Validation Methods**
  /// Each method returns null if valid, or error message string if invalid

  /// Validates full name field (required, minimum 2 characters)
  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    return null;
  }

  /// Validates email field (required, proper email format)
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    // Comprehensive email validation regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates password field (required, minimum 6 characters)
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates password confirmation (required, must match password)
  String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ========== PASSWORD STRENGTH ANALYSIS ==========

  /// **Calculate Password Strength**
  /// Analyzes password complexity and returns strength level
  PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;

    int score = 0;

    // Length scoring
    if (password.length >= 8) score++; // Basic length
    if (password.length >= 12) score++; // Good length

    // Character type scoring
    if (RegExp(r'[a-z]').hasMatch(password)) score++; // Lowercase letters
    if (RegExp(r'[A-Z]').hasMatch(password)) score++; // Uppercase letters
    if (RegExp(r'[0-9]').hasMatch(password)) score++; // Numbers
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      score++; // Special characters
    }

    // Return strength based on score
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  /// **Get Password Strength Color**
  /// Returns appropriate color for password strength indicator
  Color getPasswordStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// **Get Password Strength Text**
  /// Returns human-readable password strength description
  String getPasswordStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      default:
        return '';
    }
  }

  // ========== FORM MANAGEMENT METHODS ==========

  /// **Set Form Type**
  /// Switches between login and signup forms, clears validation and form data
  void setFormType(FormType formType) {
    debugPrint('🔍 setFormType called: $formType');
    _currentFormType = formType;
    clearValidationErrors();
    clearForm();
    notifyListeners();
  }

  /// **Password Visibility Toggles**
  /// Controls whether password fields show plain text or masked characters
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  /// **Remember Me Management**
  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
    _logger.i('🔥 Remember me set to: $value');
  }

  void toggleRememberMe() {
    setRememberMe(!_rememberMe);
  }

  /// **User Type Selection for Signup**
  void setUserType(UserType userType) {
    _selectedUserType = userType;
    notifyListeners();
  }

  void clearUserTypeSelection() {
    _selectedUserType = null;
    notifyListeners();
  }

  /// **Form Clearing and Reset**
  void clearForm() {
    debugPrint('🔍 clearForm called');
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _nameError = null;
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    _isFormValid = false;
    _validateRealTime = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearValidationErrors() {
    _nameError = null;
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    notifyListeners();
  }

  /// **Validation Control Methods**
  /// Public method to validate entire form (called from UI)
  bool validateForm() {
    return _currentFormType == FormType.login
        ? _validateLoginForm()
        : _validateSignupForm();
  }

  /// Enable real-time validation as user types
  void enableRealTimeValidation() {
    debugPrint('🔍 enableRealTimeValidation called');
    _validateRealTime = true;
    validateForm(); // Validate immediately when enabled
  }

  // ========== REMEMBER ME FUNCTIONALITY ==========

  /// **Save Remember Me Preference**
  /// Stores email in local storage for future auto-fill
  Future<void> _saveRememberMe(String email) async {
    try {
      await _prefs?.setBool(_keyRememberMe, true);
      await _prefs?.setString(_keySavedEmail, email);
      _savedEmail = email;
      _logger.i('✅ Remember me saved for: $email');
    } catch (e) {
      _logger.e('❌ Error saving remember me: $e');
    }
  }

  // ========== UTILITY METHODS ==========

  /// **Error Message Handling**
  /// Converts various error types into user-friendly messages
  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.statusCode) {
        case '400':
          return 'Invalid email or password';
        case '422':
          return 'Email already registered';
        default:
          return error.message;
      }
    }
    return 'An unexpected error occurred';
  }

  /// **Backward Compatibility Aliases**
  /// Alternative method names for external code compatibility
  Future<bool> login({
    String? email,
    String? password,
    bool? rememberMe,
  }) async {
    return await signIn(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );
  }

  Future<bool> signup({
    String? fullName,
    String? email,
    String? password,
    String? confirmPassword,
    UserType? userType,
  }) async {
    return await signUp(
      fullName: fullName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      userType: userType,
    );
  }

  // ========== CLEANUP AND DISPOSAL ==========

  /// **Provider Disposal**
  /// Cleans up resources when provider is destroyed
  /// CRITICAL: Prevents memory leaks by disposing controllers and canceling subscriptions
  @override
  void dispose() {
    // Dispose form controllers
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    // Dispose focus nodes
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    // Cancel timers and subscriptions
    _validationTimer?.cancel();
    _authSubscription?.cancel();

    super.dispose();
  }
}

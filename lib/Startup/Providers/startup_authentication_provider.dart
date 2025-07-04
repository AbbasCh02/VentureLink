// lib/Startup/Providers/startup_authentication_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../../services/user_type_service.dart';

/// Custom user model for better type safety and data handling
class StartupUser {
  final String id;
  final String fullName;
  final String email;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isVerified;

  StartupUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.createdAt,
    required this.lastLoginAt,
    required this.isVerified,
  });

  factory StartupUser.fromSupabaseUser(User user) {
    return StartupUser(
      id: user.id,
      fullName: user.userMetadata?['full_name'] as String? ?? '',
      email: user.email ?? '',
      lastLoginAt: DateTime.now(),
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      isVerified: user.emailConfirmedAt != null,
    );
  }

  StartupUser copyWith({
    String? id,
    String? fullName,
    String? email,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isVerified,
  }) {
    return StartupUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

enum FormType { login, signup }

enum PasswordStrength { none, weak, medium, strong }

/// Unified provider that handles both authentication logic and form management using Supabase
class StartupAuthProvider with ChangeNotifier {
  final Logger _logger = Logger();

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  // ========== FORM MANAGEMENT ==========
  // Form controllers (single source of truth)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Form keys for validation
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _signupFormKey = GlobalKey<FormState>();

  // Focus nodes for better UX
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  // UI state for forms
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isFormValid = false;
  FormType _currentFormType = FormType.login;

  // Validation state
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _validateRealTime = false;
  Timer? _validationTimer;

  // ========== AUTHENTICATION STATE ==========
  StartupUser? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isAuthenticating = false;
  String? _error;

  // Remember me functionality
  bool _rememberMe = false;
  String? _savedEmail;

  // Supabase auth stream subscription
  StreamSubscription<AuthState>? _authSubscription;

  StartupAuthProvider() {
    _initializeAuth();
    _initializeListeners();
  }

  // ========== GETTERS ==========
  // Form getters
  TextEditingController get nameController => _nameController;
  TextEditingController get emailController => _emailController;
  TextEditingController get passwordController => _passwordController;
  TextEditingController get confirmPasswordController =>
      _confirmPasswordController;

  GlobalKey<FormState> get loginFormKey => _loginFormKey;
  GlobalKey<FormState> get signupFormKey => _signupFormKey;

  FocusNode get nameFocusNode => _nameFocusNode;
  FocusNode get emailFocusNode => _emailFocusNode;
  FocusNode get passwordFocusNode => _passwordFocusNode;
  FocusNode get confirmPasswordFocusNode => _confirmPasswordFocusNode;

  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  bool get isFormValid => _isFormValid;
  FormType get currentFormType => _currentFormType;

  String? get nameError => _nameError;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get confirmPasswordError => _confirmPasswordError;
  bool get validateRealTime => _validateRealTime;

  // Form values
  String get fullName => _nameController.text.trim();
  String get email => _emailController.text.trim();
  String get password => _passwordController.text;
  String get confirmPassword => _confirmPasswordController.text;

  // Auth getters
  StartupUser? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isAuthenticating => _isAuthenticating;
  String? get error => _error;
  bool get rememberMe => _rememberMe;
  String? get savedEmail => _savedEmail;

  // ========== INITIALIZATION ==========
  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load saved preferences
      await _loadPreferences();

      // Check current auth state
      await _checkAuthState();

      // Listen to auth changes
      _listenToAuthChanges();
    } catch (e) {
      _logger.e('Error initializing auth: $e');
      _error = 'Failed to initialize authentication';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initializeListeners() {
    // Add text controllers listeners for real-time validation
    _nameController.addListener(_onFormFieldChanged);
    _emailController.addListener(_onFormFieldChanged);
    _passwordController.addListener(_onFormFieldChanged);
    _confirmPasswordController.addListener(_onFormFieldChanged);
  }

  Future<void> _loadPreferences() async {
    try {
      // Load saved email if remember me was checked
      final currentSession = _supabase.auth.currentSession;
      if (currentSession?.user != null) {
        _savedEmail = currentSession!.user.email;
        _rememberMe = true;
      }
    } catch (e) {
      _logger.w('Error loading preferences: $e');
    }
  }

  Future<void> _checkAuthState() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session?.user != null) {
        _currentUser = StartupUser.fromSupabaseUser(session!.user);
        _isLoggedIn = true;

        // Create or update user record in our users table
        await _createOrUpdateUserRecord(_currentUser!);

        _logger.i('✅ User already logged in: ${_currentUser!.email}');
        debugPrint('✅ Current authenticated user: ${_currentUser!.id}');
      } else {
        _currentUser = null;
        _isLoggedIn = false;
        _logger.i('No active session found');
        debugPrint('No authenticated user found');
      }
    } catch (e) {
      _logger.e('Error checking auth state: $e');
      _currentUser = null;
      _isLoggedIn = false;
    }
  }

  void _listenToAuthChanges() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthState state = data;
      _logger.i('🔄 Auth state changed: ${state.event}');

      switch (state.event) {
        case AuthChangeEvent.signedIn:
          if (state.session?.user != null) {
            final previousUserId = _currentUser?.id;
            _currentUser = StartupUser.fromSupabaseUser(state.session!.user);
            _isLoggedIn = true;
            _error = null;

            // Create or update user record
            _createOrUpdateUserRecord(_currentUser!);

            _logger.i('✅ User signed in: ${_currentUser!.email}');
            debugPrint('✅ User signed in with ID: ${_currentUser!.id}');

            // If user changed, notify listeners for data isolation
            if (previousUserId != null && previousUserId != _currentUser!.id) {
              debugPrint(
                '🔄 User changed from $previousUserId to ${_currentUser!.id}',
              );
            }
          }
          break;
        case AuthChangeEvent.signedOut:
          final previousUserId = _currentUser?.id;
          _currentUser = null;
          _isLoggedIn = false;
          _error = null;
          _logger.i('✅ User signed out');
          debugPrint('✅ User signed out (was: $previousUserId)');
          break;
        case AuthChangeEvent.userUpdated:
          if (state.session?.user != null) {
            _currentUser = StartupUser.fromSupabaseUser(state.session!.user);
            // Update user record
            _createOrUpdateUserRecord(_currentUser!);
            _logger.i('User updated: ${_currentUser!.email}');
          }
          break;
        case AuthChangeEvent.passwordRecovery:
          _logger.i('Password recovery initiated');
          break;
        default:
          _logger.i('Auth event: ${state.event}');
      }
      notifyListeners();
    });
  }

  // Create or update user record in our users table - CRITICAL: Proper user isolation
  Future<void> _createOrUpdateUserRecord(StartupUser user) async {
    try {
      debugPrint('🔍 Creating/updating startup user record for: ${user.id}');

      // CRITICAL: Check if user record exists - Filter by specific user ID
      final existingUser =
          await _supabase
              .from('users') // This is the STARTUP table
              .select('id, email, created_at')
              .eq('id', user.id) // THIS IS THE KEY FIX
              .maybeSingle();

      if (existingUser == null) {
        // Create new STARTUP user record
        await _supabase.from('users').insert({
          'id': user.id,
          'email': user.email,
          'username':
              user.fullName.isNotEmpty
                  ? user.fullName
                  : user.email.split(
                    '@',
                  )[0], // Fallback to email prefix if no full name
          'created_at': user.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'last_login_at': user.lastLoginAt.toIso8601String(),
          'is_verified': user.isVerified,
        });

        _logger.i(
          '✅ Created new STARTUP user record for: ${user.email} with ID: ${user.id}',
        );
        debugPrint('✅ Created STARTUP user record for ID: ${user.id}');
      } else {
        // Update existing STARTUP user record
        final updateData = {
          'last_login_at': user.lastLoginAt.toIso8601String(),
          'is_verified': user.isVerified,
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Also update username if it's currently the email prefix and we have a full name
        if (user.fullName.isNotEmpty) {
          updateData['username'] = user.fullName;
        }

        await _supabase
            .from('users') // This is the STARTUP table
            .update(updateData)
            .eq('id', user.id); // THIS IS THE KEY FIX

        _logger.i(
          '✅ Updated STARTUP user record for: ${user.email} with ID: ${user.id}',
        );
        debugPrint('✅ Updated STARTUP user record for ID: ${user.id}');
      }
    } catch (e) {
      _logger.e('❌ Error creating/updating STARTUP user record: $e');
      debugPrint('❌ Error with STARTUP user record for ID: ${user.id}');
      // Don't throw error to not break authentication flow
    }
  }

  // ========== AUTHENTICATION METHODS ==========
  Future<bool> signUp({
    String? fullName,
    String? email,
    String? password,
    String? confirmPassword,
  }) async {
    // Use provided values or controller values
    if (fullName != null) _nameController.text = fullName;
    if (email != null) _emailController.text = email;
    if (password != null) _passwordController.text = password;
    if (confirmPassword != null) {
      _confirmPasswordController.text = confirmPassword;
    }

    if (!_validateSignupForm()) return false;

    _isAuthenticating = true;
    _error = null;
    notifyListeners();

    try {
      _logger.i('Attempting signup for: ${this.email}');

      final response = await _supabase.auth.signUp(
        email: this.email,
        password: this.password,
        data: {
          'full_name': fullName ?? this.fullName,
          'email': email ?? this.email,
        },
      );

      if (response.user != null) {
        _logger.i('✅ Signup successful: ${this.email}');
        debugPrint('✅ New user created with ID: ${response.user!.id}');

        // User will be set via auth state listener
        // Save remember me if checked
        if (_rememberMe) {
          await _saveRememberMe(this.email);
        }

        clearForm();
        return true;
      } else {
        _error = 'Signup failed. Please try again.';
        return false;
      }
    } on AuthException catch (e) {
      _logger.e('❌ Auth exception during signup: ${e.message}');
      _error = e.message;
      return false;
    } catch (e) {
      _logger.e('❌ Unexpected error during signup: $e');
      _error = 'Signup failed. Please try again.';
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    String? email,
    String? password,
    bool? rememberMe,
  }) async {
    // Use provided values or controller values
    if (email != null) _emailController.text = email;
    if (password != null) _passwordController.text = password;
    if (rememberMe != null) _rememberMe = rememberMe;

    if (!_validateLoginForm()) return false;

    _isAuthenticating = true;
    _error = null;
    notifyListeners();

    try {
      _logger.i('Attempting login for: ${this.email}');

      final response = await _supabase.auth.signInWithPassword(
        email: this.email,
        password: this.password,
      );

      if (response.user != null) {
        _logger.i('✅ Login successful: ${this.email}');
        debugPrint('✅ User logged in with ID: ${response.user!.id}');

        // User will be set via auth state listener
        // Save remember me if checked
        if (_rememberMe) {
          await _saveRememberMe(this.email);
        }

        clearForm();
        return true;
      } else {
        _error = 'Login failed. Please check your credentials.';
        return false;
      }
    } on AuthException catch (e) {
      _logger.e('❌ Auth exception during login: ${e.message}');
      _error = e.message;
      return false;
    } catch (e) {
      _logger.e('❌ Unexpected error during login: $e');
      _error = 'Login failed. Please try again.';
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<bool> validateStartupUserAccess() async {
    try {
      if (!_isLoggedIn || _currentUser == null) {
        debugPrint('❌ No startup user logged in');
        return false;
      }

      debugPrint('🔍 Validating startup user access for: ${_currentUser!.id}');

      // Use UserTypeService to validate user type
      final isValidStartup = await UserTypeService.validateUserTypeConsistency(
        _currentUser!.id,
        'startup',
      );

      if (!isValidStartup) {
        debugPrint('❌ User ${_currentUser!.id} is not a valid startup user');
        debugPrint('🔄 Logging out invalid user');

        // Log out the user as they don't belong in startup system
        await logout();
        return false;
      }

      debugPrint('✅ Startup user access validated');
      return true;
    } catch (e) {
      debugPrint('❌ Error validating startup user access: $e');
      await logout();
      return false;
    }
  }

  /// Enhanced checkAuthState method with user type validation
  Future<void> checkAuthState() async {
    try {
      debugPrint('🔍 Checking startup auth state...');

      final session = _supabase.auth.currentSession;
      final user = session?.user;

      if (user != null) {
        debugPrint('👤 Found existing session for: ${user.email}');

        // First verify this user should be in startup system
        final userType = await UserTypeService.detectUserType(user.id);

        if (userType != 'startup') {
          debugPrint(
            '❌ User ${user.id} is not a startup user (type: $userType)',
          );
          debugPrint('🔄 Clearing startup session');

          await _supabase.auth.signOut();
          _currentUser = null;
          _isLoggedIn = false;
          notifyListeners();
          return;
        }

        // User is valid startup user
        _currentUser = StartupUser.fromSupabaseUser(user);
        _isLoggedIn = true;

        debugPrint(
          '✅ Startup auth state validated for: ${_currentUser!.email}',
        );
      } else {
        debugPrint('📝 No existing startup session found');
        _currentUser = null;
        _isLoggedIn = false;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error checking startup auth state: $e');
      _currentUser = null;
      _isLoggedIn = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Enhanced logout method with proper cleanup
  Future<void> logout() async {
    try {
      debugPrint('🔄 Logging out startup user: ${_currentUser?.email}');

      // Clear local state first
      _currentUser = null;
      _isLoggedIn = false;
      _error = null;

      // Clear Supabase session
      await UserTypeService.cleanupUserSessions();

      // Clear form data
      clearForm();

      debugPrint('✅ Startup user logged out successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error during startup logout: $e');
      // Still clear local state even if Supabase logout fails
      _currentUser = null;
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.auth.resetPasswordForEmail(email);
      _logger.i('Password reset email sent to: $email');
      return true;
    } on AuthException catch (e) {
      _logger.e('Auth exception during password reset: ${e.message}');
      _error = e.message;
      return false;
    } catch (e) {
      _logger.e('Unexpected error during password reset: $e');
      _error = 'Failed to send reset email. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Resend email verification
  Future<bool> resendEmailVerification() async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: _currentUser!.email,
      );
      _logger.i('Verification email resent to: ${_currentUser!.email}');
      return true;
    } on AuthException catch (e) {
      _logger.e('Error resending verification: ${e.message}');
      _error = e.message;
      return false;
    } catch (e) {
      _logger.e('Unexpected error resending verification: $e');
      _error = 'Failed to resend verification email.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile({String? fullName, String? email}) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Map<String, dynamic> updates = {};

      if (fullName != null && fullName != _currentUser!.fullName) {
        updates['full_name'] = fullName;
      }

      if (email != null && email != _currentUser!.email) {
        updates['email'] = email;
      }

      if (updates.isNotEmpty) {
        await _supabase.auth.updateUser(
          UserAttributes(email: email, data: updates),
        );

        _logger.i('Profile updated successfully');
        return true;
      }

      return true; // No changes needed
    } on AuthException catch (e) {
      _logger.e('Error updating profile: ${e.message}');
      _error = e.message;
      return false;
    } catch (e) {
      _logger.e('Unexpected error updating profile: $e');
      _error = 'Failed to update profile.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== HELPER METHODS ==========
  Future<void> _saveRememberMe(String email) async {
    try {
      _rememberMe = true;
      _savedEmail = email;
      _logger.i('Remember me saved for: $email');
    } catch (e) {
      _logger.w('Error saving remember me: $e');
    }
  }

  // ========== FORM MANAGEMENT METHODS ==========
  void setFormType(FormType type) {
    _currentFormType = type;
    clearForm();
    clearError();
    notifyListeners();
  }

  void enableRealTimeValidation() {
    _validateRealTime = true;
    notifyListeners();
  }

  bool validateForm() {
    switch (_currentFormType) {
      case FormType.signup:
        return _validateSignupForm();
      case FormType.login:
        return _validateLoginForm();
    }
  }

  // Login method (alias for signIn for backward compatibility)
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

  // Signup method (alias for signUp for backward compatibility)
  Future<bool> signup({
    String? fullName,
    String? email,
    String? password,
    String? confirmPassword,
  }) async {
    return await signUp(
      fullName: fullName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  // ========== VALIDATION METHODS ==========
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

  void _onFormFieldChanged() {
    if (_validateRealTime) {
      _validationTimer?.cancel();
      _validationTimer = Timer(const Duration(milliseconds: 300), () {
        validateForm();
      });
    }
  }

  // ========== FIELD VALIDATION ==========
  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ========== PASSWORD STRENGTH ==========
  PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;

    int score = 0;

    // Length
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character types
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  Color getPasswordStrengthColor(dynamic input) {
    PasswordStrength strength;
    if (input is String) {
      strength = getPasswordStrength(input);
    } else if (input is PasswordStrength) {
      strength = input;
    } else {
      strength = PasswordStrength.none;
    }

    switch (strength) {
      case PasswordStrength.none:
        return Colors.grey;
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  String getPasswordStrengthText(dynamic input) {
    PasswordStrength strength;
    if (input is String) {
      strength = getPasswordStrength(input);
    } else if (input is PasswordStrength) {
      strength = input;
    } else {
      strength = PasswordStrength.none;
    }

    switch (strength) {
      case PasswordStrength.none:
        return '';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  // ========== UI CONTROL METHODS ==========
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();

    _nameError = null;
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    _isFormValid = false;

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get user status for dashboard routing
  String getUserStatus() {
    return 'startup'; // Default for now, can be enhanced to read from database
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _validationTimer?.cancel();

    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    super.dispose();
  }
}

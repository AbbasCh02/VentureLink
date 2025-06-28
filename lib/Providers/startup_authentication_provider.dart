// lib/Providers/startup_authentication_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'dart:async';

// User model for startup authentication
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
    this.isVerified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'isVerified': isVerified,
    };
  }

  factory StartupUser.fromSupabaseUser(User user) {
    return StartupUser(
      id: user.id,
      fullName: user.userMetadata?['full_name'] ?? '',
      email: user.email ?? '',
      createdAt: DateTime.parse(user.createdAt),
      lastLoginAt: DateTime.parse(user.lastSignInAt ?? user.createdAt),
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

        _logger.i('User already logged in: ${_currentUser!.email}');
      } else {
        _currentUser = null;
        _isLoggedIn = false;
        _logger.i('No active session found');
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
      _logger.i('Auth state changed: ${state.event}');

      switch (state.event) {
        case AuthChangeEvent.signedIn:
          if (state.session?.user != null) {
            _currentUser = StartupUser.fromSupabaseUser(state.session!.user);
            _isLoggedIn = true;
            _error = null;

            // Create or update user record
            _createOrUpdateUserRecord(_currentUser!);

            _logger.i('User signed in: ${_currentUser!.email}');
          }
          break;
        case AuthChangeEvent.signedOut:
          _currentUser = null;
          _isLoggedIn = false;
          _logger.i('User signed out');
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

  // Create or update user record in our users table
  Future<void> _createOrUpdateUserRecord(StartupUser user) async {
    try {
      // Check if user record exists
      final existingUser =
          await _supabase
              .from('users')
              .select('id, email, created_at')
              .eq('id', user.id)
              .maybeSingle();

      if (existingUser == null) {
        // Create new user record
        await _supabase.from('users').insert({
          'id': user.id,
          'email': user.email,
          'username': user.email.split('@')[0], // Default username from email
          'user_status': 'startup', // Default to startup
          'created_at': user.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'last_login_at': user.lastLoginAt.toIso8601String(),
          'is_verified': user.isVerified,
        });

        _logger.i('Created new user record for: ${user.email}');
      } else {
        // Update existing user record
        await _supabase
            .from('users')
            .update({
              'last_login_at': user.lastLoginAt.toIso8601String(),
              'is_verified': user.isVerified,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);

        _logger.i('Updated user record for: ${user.email}');
      }
    } catch (e) {
      _logger.e('Error creating/updating user record: $e');
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
    if (confirmPassword != null)
      _confirmPasswordController.text = confirmPassword;

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
        _logger.i('Signup successful: ${this.email}');

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
      _logger.e('Auth exception during signup: ${e.message}');
      _error = e.message;
      return false;
    } catch (e) {
      _logger.e('Unexpected error during signup: $e');
      _error = 'Signup failed. Please try again.';
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<bool> signIn() async {
    if (!_validateLoginForm()) return false;

    _isAuthenticating = true;
    _error = null;
    notifyListeners();

    try {
      _logger.i('Attempting login for: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _logger.i('Login successful: $email');

        // User will be set via auth state listener
        // Save remember me if checked
        if (_rememberMe) {
          await _saveRememberMe(email);
        }

        clearForm();
        return true;
      } else {
        _error = 'Login failed. Please check your credentials.';
        return false;
      }
    } on AuthException catch (e) {
      _logger.e('Auth exception during login: ${e.message}');
      _error = e.message;
      return false;
    } catch (e) {
      _logger.e('Unexpected error during login: $e');
      _error = 'Login failed. Please try again.';
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isAuthenticating = true;
    notifyListeners();

    try {
      _logger.i('Signing out user');
      await _supabase.auth.signOut();

      // Clear remember me if not set
      if (!_rememberMe) {
        await _clearRememberMe();
      }

      // Clear form
      clearForm();

      // Note: User will be automatically cleared via auth state listener
    } catch (e) {
      _logger.e('Error during signout: $e');
      _error = 'Failed to sign out. Please try again.';
    } finally {
      _isAuthenticating = false;
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

  Future<void> _clearRememberMe() async {
    try {
      _savedEmail = null;
      _rememberMe = false;
      _logger.i('Remember me cleared');
    } catch (e) {
      _logger.w('Error clearing remember me: $e');
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
    // Use provided values or controller values
    if (email != null) _emailController.text = email;
    if (password != null) _passwordController.text = password;
    if (rememberMe != null) _rememberMe = rememberMe;

    return await signIn();
  }

  void clearPasswords() {
    _passwordController.clear();
    _confirmPasswordController.clear();
    _passwordError = null;
    _confirmPasswordError = null;
    notifyListeners();
  }

  void _onFormFieldChanged() {
    if (_validateRealTime) {
      _validateCurrentForm();
    }

    // Debounce validation
    _validationTimer?.cancel();
    _validationTimer = Timer(const Duration(milliseconds: 300), () {
      _updateFormValidity();
    });
  }

  void _validateCurrentForm() {
    switch (_currentFormType) {
      case FormType.signup:
        _nameError = validateName(_nameController.text);
        _emailError = validateEmail(_emailController.text);
        _passwordError = validatePassword(_passwordController.text);
        _confirmPasswordError = validateConfirmPassword(
          _passwordController.text,
          _confirmPasswordController.text,
        );
        break;
      case FormType.login:
        _emailError = validateEmail(_emailController.text);
        _passwordError =
            _passwordController.text.isEmpty
                ? 'Please enter your password'
                : null;
        break;
    }
    notifyListeners();
  }

  void _updateFormValidity() {
    bool wasValid = _isFormValid;

    switch (_currentFormType) {
      case FormType.signup:
        _isFormValid =
            validateName(_nameController.text) == null &&
            validateEmail(_emailController.text) == null &&
            validatePassword(_passwordController.text) == null &&
            validateConfirmPassword(
                  _passwordController.text,
                  _confirmPasswordController.text,
                ) ==
                null;
        break;
      case FormType.login:
        _isFormValid =
            validateEmail(_emailController.text) == null &&
            _passwordController.text.isNotEmpty;
        break;
    }

    if (wasValid != _isFormValid) {
      notifyListeners();
    }
  }

  bool _validateSignupForm() {
    _validateRealTime = true;
    _validateCurrentForm();
    return _isFormValid;
  }

  bool _validateLoginForm() {
    _validateRealTime = true;
    _validateCurrentForm();
    return _isFormValid;
  }

  // ========== FORM UI METHODS ==========
  void switchToLogin() {
    _currentFormType = FormType.login;
    clearForm();
    clearError();
    notifyListeners();
  }

  void switchToSignup() {
    _currentFormType = FormType.signup;
    clearForm();
    clearError();
    notifyListeners();
  }

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

  void clearError() {
    _error = null;
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
    _validateRealTime = false;
    _isFormValid = false;

    notifyListeners();
  }

  // ========== VALIDATION METHODS ==========
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
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

  // Password strength checker
  PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    if (password.length < 6) return PasswordStrength.weak;

    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  // Get password strength color for UI - accepts both String and PasswordStrength
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

  // Get password strength text for UI - accepts both String and PasswordStrength
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

  // Alternative methods that return string directly (for UI compatibility)
  String getPasswordStrengthString(String password) {
    return getPasswordStrength(password).name;
  }

  // Signup method with named parameters (for backward compatibility)
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

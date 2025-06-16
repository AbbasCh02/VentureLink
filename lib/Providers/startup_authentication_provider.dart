// lib/Providers/startup_authentication_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../config/supabase_config.dart';
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

  // Remember me functionality (kept but without persistence)
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

  Future<void> _checkAuthState() async {
    try {
      final session = supabase.auth.currentSession;
      if (session?.user != null) {
        _currentUser = StartupUser.fromSupabaseUser(session!.user);
        _isLoggedIn = true;
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
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final AuthState state = data;
      _logger.i('Auth state changed: ${state.event}');

      switch (state.event) {
        case AuthChangeEvent.signedIn:
          if (state.session?.user != null) {
            _currentUser = StartupUser.fromSupabaseUser(state.session!.user);
            _isLoggedIn = true;
            _error = null;
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
            _logger.i('User updated: ${_currentUser!.email}');
          }
          break;
        default:
          break;
      }
      notifyListeners();
    });
  }

  // ========== AUTHENTICATION METHODS ==========

  // Login method (alias for signIn to maintain compatibility)
  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _rememberMe = rememberMe;
    return await signIn(email: email, password: password);
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (password != confirmPassword) {
      _error = 'Passwords do not match';
      notifyListeners();
      return false;
    }

    _isAuthenticating = true;
    _error = null;
    notifyListeners();

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user != null) {
        // Store email for session (not persistent)
        if (_rememberMe) {
          _savedEmail = email;
        }

        return true;
      } else {
        _error = 'Signup failed. Please try again.';
        return false;
      }
    } catch (e) {
      _logger.e('Error during signup: $e');
      _error = 'Signup failed: ${e.toString()}';
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isAuthenticating = true;
    _error = null;
    notifyListeners();

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Store email for session (not persistent)
        if (_rememberMe) {
          _savedEmail = email;
        }

        return true;
      } else {
        _error = 'Login failed. Please check your credentials.';
        return false;
      }
    } catch (e) {
      _logger.e('Error during login: $e');
      _error = 'Login failed: ${e.toString()}';
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
      // Clear remember me data on sign out
      _savedEmail = null;
      _rememberMe = false;
      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Error during sign out: $e');
      _error = 'Sign out failed: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isAuthenticating = true;
    _error = null;
    notifyListeners();

    try {
      await supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      _logger.e('Error during password reset: $e');
      _error = 'Password reset failed: ${e.toString()}';
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  // ========== FORM MANAGEMENT METHODS ==========
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
            _passwordController.text.isEmpty ? 'Password is required' : null;
        break;
    }
    _updateFormValidity();
    notifyListeners();
  }

  void _updateFormValidity() {
    switch (_currentFormType) {
      case FormType.signup:
        _isFormValid =
            _nameController.text.trim().isNotEmpty &&
            _emailController.text.trim().isNotEmpty &&
            _passwordController.text.isNotEmpty &&
            _confirmPasswordController.text.isNotEmpty &&
            _nameError == null &&
            _emailError == null &&
            _passwordError == null &&
            _confirmPasswordError == null;
        break;
      case FormType.login:
        _isFormValid =
            _emailController.text.trim().isNotEmpty &&
            _passwordController.text.isNotEmpty &&
            _emailError == null &&
            _passwordError == null;
        break;
    }
  }

  // ========== VALIDATION METHODS ==========
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
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

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  String? validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  // ========== FORM UI METHODS ==========
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  void setFormType(FormType formType) {
    _currentFormType = formType;
    _clearValidationErrors();
    _updateFormValidity();
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void enableRealTimeValidation() {
    _validateRealTime = true;
    _validateCurrentForm();
  }

  void disableRealTimeValidation() {
    _validateRealTime = false;
    _clearValidationErrors();
    notifyListeners();
  }

  void clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _clearValidationErrors();
    _updateFormValidity();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _clearValidationErrors() {
    _nameError = null;
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
  }

  // ========== PASSWORD STRENGTH ==========
  PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;

    int score = 0;

    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character variety checks
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  Color getPasswordStrengthColor(PasswordStrength strength) {
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

  String getPasswordStrengthText(PasswordStrength strength) {
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

  // ========== FORM SUBMISSION ==========
  Future<bool> submitForm() async {
    if (!_isFormValid) return false;

    switch (_currentFormType) {
      case FormType.signup:
        return await signUp(
          fullName: fullName,
          email: email,
          password: password,
          confirmPassword: confirmPassword,
        );
      case FormType.login:
        return await login(
          email: email,
          password: password,
          rememberMe: _rememberMe,
        );
    }
  }

  @override
  void dispose() {
    _validationTimer?.cancel();
    _authSubscription?.cancel();

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

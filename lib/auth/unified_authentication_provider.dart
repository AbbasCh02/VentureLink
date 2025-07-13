// lib/auth/unified_authentication_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../services/user_type_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User types enumeration
enum UserType { startup, investor }

/// Generic user model that can represent both startup and investor users
class AppUser {
  final String id;
  final String fullName;
  final String email;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isVerified;
  final UserType userType;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.createdAt,
    required this.lastLoginAt,
    required this.isVerified,
    required this.userType,
  });

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

enum FormType { login, signup }

enum PasswordStrength { none, weak, medium, strong }

/// Unified Authentication Provider that handles both startup and investor authentication
/// based on user type selection during signup and automatic detection during login
class UnifiedAuthProvider with ChangeNotifier {
  final Logger _logger = Logger();
  final SupabaseClient _supabase = Supabase.instance.client;

  // ========== FORM MANAGEMENT ==========
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _signupFormKey = GlobalKey<FormState>();

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
  AppUser? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isAuthenticating = false;
  String? _error;

  // Remember me functionality
  bool _rememberMe = false;
  String? _savedEmail;
  SharedPreferences? _prefs;

  // User type selection for signup
  UserType? _selectedUserType;

  // CRITICAL: Flag to prevent duplicate user record creation
  bool _isCreatingUserRecord = false;

  // Supabase auth stream subscription
  StreamSubscription<AuthState>? _authSubscription;

  static const String _keyRememberMe = 'remember_me';
  static const String _keySavedEmail = 'saved_email';
  static const String _keyAutoLogin = 'auto_login';

  UnifiedAuthProvider() {
    _initializeAuth();
    _initializeListeners();
    _setupControllerListeners();
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

  // Validation error getters - ESSENTIAL FOR THE UI
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
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isAuthenticating => _isAuthenticating;
  String? get error => _error;
  bool get rememberMe => _rememberMe;
  String? get savedEmail => _savedEmail;
  UserType? get selectedUserType => _selectedUserType;

  // ========== INITIALIZATION ==========
  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 🔥 Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // 🔥 Load saved remember me preferences
      await _loadRememberMePreferences();

      // 🔥 Check if user should auto-login based on remember me setting
      final shouldAutoLogin = _prefs?.getBool(_keyAutoLogin) ?? false;

      if (shouldAutoLogin) {
        // Check if user is already logged in with valid session
        final session = _supabase.auth.currentSession;
        if (session?.user != null) {
          _logger.i('🔥 Auto-login: Valid session found, logging in user');
          await _handleExistingUser(session!.user);
        } else {
          _logger.i('🔥 Auto-login disabled: No valid session found');
          await _clearAutoLogin();
        }
      } else {
        _logger.i('🔥 Auto-login disabled: Remember me not enabled');
        // 🔥 CRITICAL: Sign out any existing session if remember me is not enabled
        final session = _supabase.auth.currentSession;
        if (session?.user != null) {
          _logger.i('🔥 Signing out existing session (remember me disabled)');
          await _supabase.auth.signOut();
        }
      }
    } catch (e) {
      _logger.e('Error initializing auth: $e');
      _error = 'Failed to initialize authentication';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRememberMePreferences() async {
    try {
      _rememberMe = _prefs?.getBool(_keyRememberMe) ?? false;
      _savedEmail = _prefs?.getString(_keySavedEmail);

      if (_rememberMe && _savedEmail != null) {
        _emailController.text = _savedEmail!;
        _logger.i('✅ Remember me loaded for: $_savedEmail');
      }
    } catch (e) {
      _logger.e('❌ Error loading remember me preferences: $e');
    }
  }

  Future<void> _saveRememberMePreferences(
    String email,
    bool enableAutoLogin,
  ) async {
    try {
      await _prefs?.setBool(_keyRememberMe, _rememberMe);
      await _prefs?.setBool(_keyAutoLogin, enableAutoLogin);

      if (_rememberMe) {
        await _prefs?.setString(_keySavedEmail, email);
        _savedEmail = email;
        _logger.i(
          '✅ Remember me saved for: $email (auto-login: $enableAutoLogin)',
        );
      } else {
        await _prefs?.remove(_keySavedEmail);
        await _prefs?.remove(_keyAutoLogin);
        _savedEmail = null;
        _logger.i('✅ Remember me cleared');
      }
    } catch (e) {
      _logger.e('❌ Error saving remember me preferences: $e');
    }
  }

  Future<void> _clearAutoLogin() async {
    try {
      await _prefs?.remove(_keyAutoLogin);
      _logger.i('✅ Auto-login disabled');
    } catch (e) {
      _logger.e('❌ Error clearing auto-login: $e');
    }
  }

  /// Handle existing user by detecting their type and setting up the session
  /// OPTIMIZED: Only update user record if actually needed
  Future<void> _handleExistingUser(User user) async {
    try {
      final userTypeString = await UserTypeService.detectUserType(user.id);

      if (userTypeString != null) {
        final userType =
            userTypeString == 'startup' ? UserType.startup : UserType.investor;
        _currentUser = AppUser.fromSupabaseUser(user, userType);
        _isLoggedIn = true;
        _selectedUserType = userType;

        // Update user record if needed
        final shouldUpdateRecord = await _shouldUpdateUserRecord(
          user.id,
          userType,
        );
        if (shouldUpdateRecord) {
          await _createOrUpdateUserRecord(_currentUser!);
        }

        _logger.i(
          '✅ Existing user loaded: ${_currentUser!.email} (${userType.name})',
        );
      } else {
        // User not found in either table
        await _supabase.auth.signOut();
        await _clearAutoLogin();
        _error = 'User account not found. Please contact support.';
      }
    } catch (e) {
      _logger.e('Error handling signed in user: $e');
      _error = 'Failed to load user data';
    }
  }

  /// Check if we should update the user record
  /// OPTIMIZATION: Only update if last_login_at is older than 1 hour
  Future<bool> _shouldUpdateUserRecord(String userId, UserType userType) async {
    try {
      final tableName = userType == UserType.startup ? 'startups' : 'investors';

      final result =
          await _supabase
              .from(tableName)
              .select('last_login_at')
              .eq('id', userId)
              .maybeSingle();

      if (result != null && result['last_login_at'] != null) {
        final lastLogin = DateTime.parse(result['last_login_at']);
        final now = DateTime.now();
        final difference = now.difference(lastLogin);

        // Only update if last login was more than 1 hour ago
        return difference.inHours >= 1;
      }

      // If no last_login_at found, we should update
      return true;
    } catch (e) {
      debugPrint('❌ Error checking last login time: $e');
      // If there's an error, err on the side of not updating
      return false;
    }
  }

  void _initializeListeners() {
    // Set up form field listeners for real-time validation
    _nameController.addListener(_onFormFieldChanged);
    _emailController.addListener(_onFormFieldChanged);
    _passwordController.addListener(_onFormFieldChanged);
    _confirmPasswordController.addListener(_onFormFieldChanged);

    // Listen to auth state changes
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      _logger.i('Auth state changed: ${event.name}');

      switch (event) {
        case AuthChangeEvent.signedIn:
          if (session?.user != null) {
            debugPrint('🔄 Handling signed in user...');
            await _handleSignedInUser(session!.user);
          }
          break;
        case AuthChangeEvent.signedOut:
          debugPrint('🔄 Handling signed out user...');
          _handleSignedOut();
          break;
        case AuthChangeEvent.userUpdated:
          if (session?.user != null && _currentUser != null) {
            _currentUser = AppUser.fromSupabaseUser(
              session!.user,
              _currentUser!.userType,
            );
            _currentUser = _currentUser!.copyWith(
              isVerified: true,
            ); // Always verified
            await _createOrUpdateUserRecord(_currentUser!);
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

  /// Handle user sign in - detect type or use selected type
  Future<void> _handleSignedInUser(User user) async {
    try {
      UserType? userType;

      // If we have a selected type (from signup), use it
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
        final previousUserId = _currentUser?.id;
        _currentUser = AppUser.fromSupabaseUser(user, userType);
        _currentUser = _currentUser!.copyWith(
          isVerified: true,
        ); // Always mark as verified
        _isLoggedIn = true;
        _error = null;

        // CRITICAL FIX: Only create/update user record if not already in progress
        // But allow retry if previous attempt may have failed
        if (!_isCreatingUserRecord) {
          debugPrint(
            '🔥 Auth state listener calling _createOrUpdateUserRecord...',
          );
          await _createOrUpdateUserRecord(_currentUser!);
        } else {
          debugPrint(
            '🔍 Skipping user record creation from auth listener - already in progress',
          );
          debugPrint('   Will retry in 1 second if still needed...');
          // Set a timer to retry if the flag is still set (means something went wrong)
          Timer(const Duration(seconds: 1), () async {
            if (_isCreatingUserRecord) {
              debugPrint('🔄 Retrying user record creation after timeout...');
              _isCreatingUserRecord = false; // Reset flag
              await _createOrUpdateUserRecord(_currentUser!);
            }
          });
        }

        _logger.i(
          '✅ User signed in: ${_currentUser!.email} (${userType.name})',
        );
        debugPrint('✅ User signed in with ID: ${_currentUser!.id}');
        debugPrint('✅ Routing to ${userType.name} dashboard');

        // If user changed, notify listeners for data isolation
        if (previousUserId != null && previousUserId != _currentUser!.id) {
          debugPrint(
            '🔄 User changed from $previousUserId to ${_currentUser!.id}',
          );
        }
      } else {
        // User not found in either table - this shouldn't happen
        await _supabase.auth.signOut();
        _error = 'User account not found. Please contact support.';
      }
    } catch (e) {
      _logger.e('Error handling signed in user: $e');
      _error = 'Failed to load user data';
    }
  }

  void _handleSignedOut() {
    final previousUserId = _currentUser?.id;
    _currentUser = null;
    _isLoggedIn = false;
    _error = null;
    _selectedUserType = null;
    _isCreatingUserRecord = false; // Reset the flag
    _logger.i('✅ User signed out');
    debugPrint('✅ User signed out (was: $previousUserId)');
  }

  /// Create or update user record in the appropriate table based on user type
  /// Replace your existing _createOrUpdateUserRecord method with this fixed version
  /// Alternative version without storing results (simpler)
  /// OPTIMIZED: Create or update user record only when necessary
  Future<void> _createOrUpdateUserRecord(AppUser user) async {
    if (_isCreatingUserRecord) {
      debugPrint('🔍 User record creation already in progress, skipping...');
      return;
    }

    _isCreatingUserRecord = true;
    final tableName =
        user.userType == UserType.startup ? 'startups' : 'investors';

    debugPrint(
      '🔄 Starting user record update for ${user.id} (${user.userType.name})',
    );

    try {
      // Check if user record exists
      final existingUser =
          await _supabase
              .from(tableName)
              .select('id, email, created_at, last_login_at')
              .eq('id', user.id)
              .maybeSingle();

      if (existingUser == null) {
        // Create new user record (this should be rare for existing users)
        final insertData = <String, dynamic>{
          'id': user.id,
          'email': user.email,
          'username':
              user.fullName.isNotEmpty
                  ? user.fullName
                  : user.email.split('@')[0],
          'is_verified': user.isVerified,
          'last_login_at': user.lastLoginAt.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (user.userType == UserType.startup) {
          insertData['user_type'] = 'startup';
        } else if (user.userType == UserType.investor) {
          insertData['user_type'] = 'investor';
        }

        await _supabase.from(tableName).insert(insertData);
        debugPrint('✅ Created new user record for ${user.email}');
        _logger.i(
          '✅ Created new ${user.userType.name} record for: ${user.email}',
        );
      } else {
        // Update existing user record with minimal data
        final updateData = <String, dynamic>{
          'last_login_at': user.lastLoginAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Only update username if we have a full name and it's different
        if (user.fullName.isNotEmpty) {
          final currentUsername = existingUser['username'] ?? '';
          if (currentUsername != user.fullName) {
            updateData['username'] = user.fullName;
            debugPrint(
              '🔄 Updating username from "$currentUsername" to "${user.fullName}"',
            );
          }
        }

        await _supabase.from(tableName).update(updateData).eq('id', user.id);
        debugPrint('✅ Updated user record for ${user.email}');
        _logger.i('✅ Updated ${user.userType.name} record for: ${user.email}');
      }
    } catch (e) {
      debugPrint('❌ Error in user record operation: $e');

      // Handle duplicate key gracefully
      if (e.toString().contains('duplicate key') ||
          e.toString().contains('23505')) {
        debugPrint('🔍 User record already exists (duplicate key)');
        _logger.i('User record already exists for: ${user.email}');
        return;
      }

      throw Exception('Failed to manage ${user.userType.name} user record: $e');
    } finally {
      _isCreatingUserRecord = false;
    }
  }

  // ========== USER TYPE SELECTION ==========
  void setUserType(UserType userType) {
    _selectedUserType = userType;
    notifyListeners();
  }

  void clearUserTypeSelection() {
    _selectedUserType = null;
    notifyListeners();
  }

  // ========== FORM MANAGEMENT ==========
  void setFormType(FormType formType) {
    debugPrint('🔍 setFormType called: $formType');
    _currentFormType = formType;
    clearValidationErrors();
    clearForm();
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
    _logger.i('🔥 Remember me set to: $value');
  }

  void toggleRememberMe() {
    setRememberMe(!_rememberMe);
  }

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

  // Public method to validate form (called from UI)
  bool validateForm() {
    return _currentFormType == FormType.login
        ? _validateLoginForm()
        : _validateSignupForm();
  }

  // Public method to enable real-time validation (called from UI)
  void enableRealTimeValidation() {
    debugPrint('🔍 enableRealTimeValidation called');
    _validateRealTime = true;
    validateForm(); // Validate immediately when enabled
  }

  // Method to clear validation errors
  void clearValidationErrors() {
    _nameError = null;
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    notifyListeners();
  }

  // Add listener setup for real-time validation
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
  }

  // ========== AUTHENTICATION METHODS ==========
  Future<bool> signUp({
    String? fullName,
    String? email,
    String? password,
    String? confirmPassword,
    UserType? userType,
  }) async {
    // Use provided values or controller values
    if (fullName != null) _nameController.text = fullName;
    if (email != null) _emailController.text = email;
    if (password != null) _passwordController.text = password;
    if (confirmPassword != null) {
      _confirmPasswordController.text = confirmPassword;
    }
    if (userType != null) _selectedUserType = userType;

    // Validate that user type is selected
    if (_selectedUserType == null) {
      _error = 'Please select whether you are a startup or investor';
      notifyListeners();
      return false;
    }

    if (!_validateSignupForm()) return false;

    _isAuthenticating = true;
    _error = null;
    notifyListeners();

    try {
      _logger.i(
        'Attempting signup for: ${this.email} as ${_selectedUserType!.name}',
      );

      // CRITICAL: Sign up WITHOUT email confirmation required
      final response = await _supabase.auth.signUp(
        email: this.email,
        password: this.password,
        emailRedirectTo: null, // Remove email confirmation redirect
        data: {
          'full_name': fullName ?? this.fullName,
          'email': email ?? this.email,
          'user_type': _selectedUserType!.name,
          'email_confirmed': true, // Force email as confirmed
        },
      );

      if (response.user != null) {
        _logger.i(
          '✅ Signup successful: ${this.email} as ${_selectedUserType!.name}',
        );
        debugPrint(
          '✅ New ${_selectedUserType!.name} user created with ID: ${response.user!.id}',
        );

        // CRITICAL: Set the user data but let the auth state listener handle user record creation
        _currentUser = AppUser.fromSupabaseUser(
          response.user!,
          _selectedUserType!,
        );
        _currentUser = _currentUser!.copyWith(
          isVerified: true,
        ); // Force verified status
        _isLoggedIn = true;

        // CRITICAL FIX: Create user record here since auth listener might race
        debugPrint('🔥 SignUp method calling _createOrUpdateUserRecord...');
        await _createOrUpdateUserRecord(_currentUser!);

        await _saveRememberMePreferences(this.email, _rememberMe);

        // Save remember me if checked
        if (_rememberMe) {
          await _saveRememberMe(this.email);
        }

        _logger.i(
          '✅ User immediately logged in after signup: ${_currentUser!.email}',
        );
        debugPrint(
          '✅ User logged in with ID: ${_currentUser!.id} (${_currentUser!.userType.name})',
        );

        clearForm();
        notifyListeners(); // CRITICAL: Notify listeners to trigger navigation
        return true;
      } else {
        _error = 'Signup failed. Please try again.';
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
        // User type will be detected in _handleSignedInUser
        _logger.i('✅ Login successful: ${this.email}');

        await _saveRememberMePreferences(this.email, _rememberMe);

        clearForm();
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

  Future<bool> signOut() async {
    try {
      await _clearAutoLogin();
      await _supabase.auth.signOut();
      clearForm();
      return true;
    } catch (e) {
      _logger.e('❌ Sign out error: $e');
      _error = 'Failed to sign out';
      return false;
    }
  }

  // ========== REMEMBER ME FUNCTIONALITY ==========
  Future<void> _saveRememberMe(String email) async {
    try {
      // In a real app, you might want to use secure storage
      // For now, this is a placeholder
      _savedEmail = email;
      _logger.i('✅ Remember me saved for: $email');
    } catch (e) {
      _logger.e('❌ Error saving remember me: $e');
    }
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
    debugPrint('🔍 Form field changed - validateRealTime: $_validateRealTime');
    if (_validateRealTime) {
      // Immediate validation for instant feedback
      debugPrint('🔍 Running validation immediately...');
      validateForm();
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
    // Fixed complete email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
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

  // ========== UTILITY METHODS ==========
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

  // Alias methods for backward compatibility
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _validationTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}

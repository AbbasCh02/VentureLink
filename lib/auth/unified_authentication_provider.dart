// lib/auth/unified_authentication_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../services/user_type_service.dart';

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

  // User type selection for signup
  UserType? _selectedUserType;

  // CRITICAL: Flag to prevent duplicate user record creation
  bool _isCreatingUserRecord = false;

  // Supabase auth stream subscription
  StreamSubscription<AuthState>? _authSubscription;

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
      // Check if user is already logged in
      final session = _supabase.auth.currentSession;
      if (session?.user != null) {
        await _handleExistingUser(session!.user);
      }

      // Load saved credentials
      await _loadRememberMe();
    } catch (e) {
      _logger.e('Error initializing auth: $e');
      _error = 'Failed to initialize authentication';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle existing user by detecting their type and setting up the session
  Future<void> _handleExistingUser(User user) async {
    try {
      final userTypeString = await UserTypeService.detectUserType(user.id);

      if (userTypeString != null) {
        final userType =
            userTypeString == 'startup' ? UserType.startup : UserType.investor;
        _currentUser = AppUser.fromSupabaseUser(user, userType);
        _isLoggedIn = true;
        _selectedUserType = userType;

        // Update user record in appropriate table
        await _createOrUpdateUserRecord(_currentUser!);

        _logger.i(
          '✅ Existing user loaded: ${_currentUser!.email} (${userType.name})',
        );
      } else {
        // User exists in auth but not in our tables - sign them out
        await _supabase.auth.signOut();
        _logger.w('User found in auth but not in database tables - signed out');
      }
    } catch (e) {
      _logger.e('Error handling existing user: $e');
      await _supabase.auth.signOut();
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
  Future<void> _createOrUpdateUserRecord(AppUser user) async {
    // CRITICAL FIX: Check if already creating, but allow retry if previous attempt failed
    if (_isCreatingUserRecord) {
      debugPrint('🔍 User record creation already in progress, skipping...');
      return;
    }

    _isCreatingUserRecord = true;
    debugPrint(
      '🔥 Starting user record creation for ${user.id} (${user.userType.name})',
    );

    try {
      final tableName =
          user.userType == UserType.startup ? 'users' : 'investors';

      debugPrint('🔍 Attempting to create/update record in table: $tableName');
      debugPrint('   User ID: ${user.id}');
      debugPrint('   User Type: ${user.userType.name}');
      debugPrint('   Email: ${user.email}');

      // Check if user record exists
      final existingUser =
          await _supabase
              .from(tableName)
              .select('id, email, created_at')
              .eq('id', user.id)
              .maybeSingle();

      debugPrint(
        '🔍 Existing user check result: ${existingUser != null ? "Found" : "Not found"}',
      );

      if (existingUser == null) {
        // Create new user record - using correct field names from your database schema
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

        // Add fields specific to each table type
        if (user.userType == UserType.startup) {
          // For users table - CRITICAL: Include all required fields from DB schema
          insertData.addAll({
            'user_type': 'startup', // Required field from schema
          });
          debugPrint('📝 Preparing startup user insert with data: $insertData');
        } else {
          // For investors table - based on DB investor.txt
          insertData.addAll({
            'portfolio_size': 0, // Default value for investors
          });
          debugPrint(
            '📝 Preparing investor user insert with data: $insertData',
          );
        }

        debugPrint('🔥 Attempting INSERT into $tableName table...');

        // CRITICAL FIX: Add error handling and debugging for the insert operation
        try {
          debugPrint('🔥 Executing INSERT query...');
          final insertResult =
              await _supabase.from(tableName).insert(insertData).select();
          debugPrint('✅ INSERT successful! Result: $insertResult');

          if (insertResult.isNotEmpty) {
            debugPrint(
              '✅ Database record created successfully for ${user.email}',
            );
            debugPrint('   Record ID: ${insertResult[0]['id']}');
            debugPrint('   Email: ${insertResult[0]['email']}');
            debugPrint('   User Type: ${user.userType.name}');
          }
        } catch (insertError) {
          debugPrint('❌ INSERT failed with error: $insertError');
          debugPrint('❌ Insert data was: $insertData');
          debugPrint('❌ Table name: $tableName');

          // CRITICAL FIX: Handle duplicate key error gracefully
          if (insertError.toString().contains('duplicate key') ||
              insertError.toString().contains('23505')) {
            debugPrint(
              '🔍 User record already exists, this is expected in some cases',
            );
            // Don't throw error for duplicate key, just log it
            _logger.i('User record already exists for: ${user.email}');
            return;
          }

          // Check if it's a policy issue
          if (insertError.toString().contains('policy')) {
            debugPrint(
              '🔒 This appears to be a Row Level Security (RLS) policy issue',
            );
            debugPrint(
              '🔒 Ensure the INSERT policy exists for table: $tableName',
            );
          }

          // Re-throw the error with more context for non-duplicate errors
          throw Exception(
            'Failed to insert ${user.userType.name} user: $insertError',
          );
        }

        _logger.i(
          '✅ Created new ${user.userType.name} record for: ${user.email}',
        );
        debugPrint(
          '✅ Created ${user.userType.name} user record for ID: ${user.id}',
        );
      } else {
        // Update existing user record - using only fields that exist
        final updateData = <String, dynamic>{
          'last_login_at': user.lastLoginAt.toIso8601String(),
          'is_verified': user.isVerified,
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Update username if we have a full name
        if (user.fullName.isNotEmpty) {
          updateData['username'] = user.fullName;
        }

        debugPrint('🔄 Updating existing user with data: $updateData');

        try {
          final updateResult =
              await _supabase
                  .from(tableName)
                  .update(updateData)
                  .eq('id', user.id)
                  .select();

          debugPrint('✅ UPDATE successful! Result: $updateResult');
          _logger.i(
            '✅ Updated ${user.userType.name} record for: ${user.email}',
          );
          debugPrint(
            '✅ Updated ${user.userType.name} user record for ID: ${user.id}',
          );
        } catch (updateError) {
          debugPrint('❌ UPDATE failed with error: $updateError');
          throw Exception(
            'Failed to update ${user.userType.name} user: $updateError',
          );
        }
      }
    } catch (e) {
      _logger.e('❌ Error creating/updating user record: $e');
      debugPrint('❌ Database error for user ${user.id}: $e');
      debugPrint(
        '❌ Table: ${user.userType == UserType.startup ? 'users' : 'investors'}',
      );

      // Enhanced error reporting
      debugPrint('❌ Full error details:');
      debugPrint('   User Type: ${user.userType.name}');
      debugPrint(
        '   Table Name: ${user.userType == UserType.startup ? 'users' : 'investors'}',
      );
      debugPrint('   User ID: ${user.id}');
      debugPrint('   Email: ${user.email}');

      // Don't throw error to not break authentication flow, but log extensively
      _error = 'Failed to create user record: ${e.toString()}';
      notifyListeners();
    } finally {
      _isCreatingUserRecord = false; // Always reset the flag
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
    debugPrint('🔍 validateForm called - currentFormType: $_currentFormType');
    if (_currentFormType == FormType.login) {
      return _validateLoginForm();
    } else {
      return _validateSignupForm();
    }
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

        // Save remember me if checked
        if (_rememberMe) {
          await _saveRememberMe(this.email);
        } else {
          await _clearRememberMe();
        }

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

  Future<void> _loadRememberMe() async {
    try {
      // In a real app, you might want to use secure storage
      // For now, this is a placeholder
      if (_savedEmail != null) {
        _emailController.text = _savedEmail!;
        _rememberMe = true;
        _logger.i('✅ Remember me loaded for: $_savedEmail');
      }
    } catch (e) {
      _logger.e('❌ Error loading remember me: $e');
    }
  }

  Future<void> _clearRememberMe() async {
    try {
      _savedEmail = null;
      _logger.i('✅ Remember me cleared');
    } catch (e) {
      _logger.e('❌ Error clearing remember me: $e');
    }
  }

  // ========== VALIDATION METHODS ==========
  bool _validateLoginForm() {
    debugPrint('🔍 _validateLoginForm called');
    bool isValid = true;

    final emailValue = email;
    final passwordValue = password;
    debugPrint(
      '🔍 Validating email: "$emailValue", password: "${passwordValue.length} chars"',
    );

    _emailError = validateEmail(emailValue);
    if (_emailError != null) {
      debugPrint('🔍 Email error: $_emailError');
      isValid = false;
    }

    _passwordError = validatePassword(passwordValue);
    if (_passwordError != null) {
      debugPrint('🔍 Password error: $_passwordError');
      isValid = false;
    }

    _isFormValid = isValid;
    debugPrint('🔍 Form valid: $isValid, notifying listeners...');
    notifyListeners(); // CRITICAL: Notify UI of validation changes
    return isValid;
  }

  bool _validateSignupForm() {
    debugPrint('🔍 _validateSignupForm called');
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
    debugPrint('🔍 Signup form valid: $isValid, notifying listeners...');
    notifyListeners(); // CRITICAL: Notify UI of validation changes
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

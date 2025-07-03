// lib/Investor/Providers/investor_authentication_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

/// Custom investor user model for the split table structure
class InvestorUser {
  // Basic info from investors table
  final String id;
  final String email;
  final String? username;
  final String? avatarUrl;
  final int portfolioSize;
  final bool isVerified;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  // Professional info from investor_profiles table
  final String? companyName;
  final String? title;
  final String? bio;
  final String? linkedinUrl;
  final String? websiteUrl;
  final List<String> industries;
  final List<String> geographicFocus;

  // Additional computed fields
  final String displayName;
  final bool hasProfile;

  InvestorUser({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
    this.portfolioSize = 0,
    this.isVerified = false,
    this.lastLoginAt,
    required this.createdAt,
    this.companyName,
    this.title,
    this.bio,
    this.linkedinUrl,
    this.websiteUrl,
    this.industries = const [],
    this.geographicFocus = const [],
  }) : displayName = username ?? email.split('@')[0],
       hasProfile = companyName != null || title != null || bio != null;

  factory InvestorUser.fromSupabaseUser(User user) {
    return InvestorUser(
      id: user.id,
      email: user.email ?? '',
      username: user.userMetadata?['full_name'] as String?,
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }

  factory InvestorUser.fromDatabase(
    Map<String, dynamic> basicData, [
    Map<String, dynamic>? profileData,
  ]) {
    return InvestorUser(
      // Basic investor data
      id: basicData['id'] as String,
      email: basicData['email'] as String,
      username: basicData['username'] as String?,
      avatarUrl: basicData['avatar_url'] as String?,
      portfolioSize: basicData['portfolio_size'] as int? ?? 0,
      isVerified: basicData['is_verified'] as bool? ?? false,
      lastLoginAt:
          basicData['last_login_at'] != null
              ? DateTime.tryParse(basicData['last_login_at'] as String)
              : null,
      createdAt:
          DateTime.tryParse(basicData['created_at'] as String? ?? '') ??
          DateTime.now(),

      // Professional profile data (may be null)
      companyName: profileData?['company_name'] as String?,
      title: profileData?['title'] as String?,
      bio: profileData?['bio'] as String?,
      linkedinUrl: profileData?['linkedin_url'] as String?,
      websiteUrl: profileData?['website_url'] as String?,
      industries:
          profileData?['industries'] != null
              ? List<String>.from(profileData!['industries'] as List)
              : [],
      geographicFocus:
          profileData?['geographic_focus'] != null
              ? List<String>.from(profileData!['geographic_focus'] as List)
              : [],
    );
  }

  factory InvestorUser.fromJoinedData(Map<String, dynamic> data) {
    return InvestorUser(
      // Basic investor data
      id: data['id'] as String,
      email: data['email'] as String,
      username: data['username'] as String?,
      avatarUrl: data['avatar_url'] as String?,
      portfolioSize: data['portfolio_size'] as int? ?? 0,
      isVerified: data['is_verified'] as bool? ?? false,
      lastLoginAt:
          data['last_login_at'] != null
              ? DateTime.tryParse(data['last_login_at'] as String)
              : null,
      createdAt:
          DateTime.tryParse(data['created_at'] as String? ?? '') ??
          DateTime.now(),

      // Professional profile data (from join)
      companyName: data['company_name'] as String?,
      title: data['title'] as String?,
      bio: data['bio'] as String?,
      linkedinUrl: data['linkedin_url'] as String?,
      websiteUrl: data['website_url'] as String?,
      industries:
          data['industries'] != null
              ? List<String>.from(data['industries'] as List)
              : [],
      geographicFocus:
          data['geographic_focus'] != null
              ? List<String>.from(data['geographic_focus'] as List)
              : [],
    );
  }

  InvestorUser copyWith({
    String? id,
    String? email,
    String? username,
    String? avatarUrl,
    int? portfolioSize,
    bool? isVerified,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    String? companyName,
    String? title,
    String? bio,
    String? linkedinUrl,
    String? websiteUrl,
    List<String>? industries,
    List<String>? geographicFocus,
  }) {
    return InvestorUser(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      portfolioSize: portfolioSize ?? this.portfolioSize,
      isVerified: isVerified ?? this.isVerified,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      companyName: companyName ?? this.companyName,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      industries: industries ?? this.industries,
      geographicFocus: geographicFocus ?? this.geographicFocus,
    );
  }

  Map<String, dynamic> toBasicDatabase() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatar_url': avatarUrl,
      'portfolio_size': portfolioSize,
      'is_verified': isVerified,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> toProfileDatabase() {
    return {
      'investor_id': id,
      'company_name': companyName,
      'title': title,
      'bio': bio,
      'linkedin_url': linkedinUrl,
      'website_url': websiteUrl,
      'industries': industries,
      'geographic_focus': geographicFocus,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

enum FormType { login, signup }

enum PasswordStrength { none, weak, medium, strong }

/// Unified provider that handles authentication with split table structure
class InvestorAuthProvider with ChangeNotifier {
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
  InvestorUser? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isAuthenticating = false;
  String? _error;

  // Remember me functionality
  bool _rememberMe = false;
  String? _savedEmail;

  // Supabase auth stream subscription
  StreamSubscription<AuthState>? _authSubscription;

  InvestorAuthProvider() {
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
  InvestorUser? get currentUser => _currentUser;
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
      await _loadPreferences();
      await _checkAuthState();
      _listenToAuthChanges();
    } catch (e) {
      _logger.e('Error initializing investor auth: $e');
      _error = 'Failed to initialize authentication';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initializeListeners() {
    _nameController.addListener(_onFormFieldChanged);
    _emailController.addListener(_onFormFieldChanged);
    _passwordController.addListener(_onFormFieldChanged);
    _confirmPasswordController.addListener(_onFormFieldChanged);
  }

  Future<void> _loadPreferences() async {
    try {
      final currentSession = _supabase.auth.currentSession;
      if (currentSession?.user != null) {
        _savedEmail = currentSession!.user.email;
        _rememberMe = true;
      }
    } catch (e) {
      _logger.w('Error loading investor preferences: $e');
    }
  }

  Future<void> _checkAuthState() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session?.user != null) {
        await _loadCompleteInvestorProfile(session!.user.id);
        _isLoggedIn = true;
        _logger.i('✅ Investor already logged in: ${_currentUser!.email}');
        debugPrint('✅ Current authenticated investor: ${_currentUser!.id}');
      } else {
        _currentUser = null;
        _isLoggedIn = false;
        _logger.i('No active investor session found');
      }
    } catch (e) {
      _logger.e('Error checking investor auth state: $e');
      _currentUser = null;
      _isLoggedIn = false;
    }
  }

  void _listenToAuthChanges() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthState state = data;
      _logger.i('🔄 Investor auth state changed: ${state.event}');

      switch (state.event) {
        case AuthChangeEvent.signedIn:
          if (state.session?.user != null) {
            _handleSignIn(state.session!.user);
            _isLoggedIn = true;
            _error = null;
            _logger.i('✅ Investor signed in: ${state.session!.user.email}');
          }
          break;
        case AuthChangeEvent.signedOut:
          final previousUserId = _currentUser?.id;
          _currentUser = null;
          _isLoggedIn = false;
          _error = null;
          _logger.i('✅ Investor signed out (was: $previousUserId)');
          break;
        case AuthChangeEvent.userUpdated:
          if (state.session?.user != null) {
            _handleUserUpdate(state.session!.user);
          }
          break;
        default:
          _logger.i('Investor auth event: ${state.event}');
      }
      notifyListeners();
    });
  }

  // ========== DATABASE OPERATIONS ==========

  // Load complete investor profile using helper function
  Future<void> _loadCompleteInvestorProfile(String userId) async {
    try {
      final response = await _supabase.rpc(
        'get_complete_investor_profile',
        params: {'investor_user_id': userId},
      );

      if (response != null && response.isNotEmpty) {
        _currentUser = InvestorUser.fromJoinedData(response[0]);
        debugPrint(
          '✅ Loaded complete investor profile for: ${_currentUser!.email}',
        );
      } else {
        // Fallback: load basic investor data only
        await _loadBasicInvestorProfile(userId);
      }
    } catch (e) {
      _logger.e('Error loading complete investor profile: $e');
      // Fallback to basic profile
      await _loadBasicInvestorProfile(userId);
    }
  }

  // Load basic investor profile from investors table only
  Future<void> _loadBasicInvestorProfile(String userId) async {
    try {
      final response =
          await _supabase
              .from('investors')
              .select('*')
              .eq('id', userId)
              .maybeSingle();

      if (response != null) {
        _currentUser = InvestorUser.fromDatabase(response);
        debugPrint(
          '✅ Loaded basic investor profile for: ${_currentUser!.email}',
        );
      } else {
        // Create basic investor record if doesn't exist
        final authUser = _supabase.auth.currentUser;
        if (authUser != null) {
          _currentUser = InvestorUser.fromSupabaseUser(authUser);
          await _createBasicInvestorRecord(_currentUser!);
        }
      }
    } catch (e) {
      _logger.e('Error loading basic investor profile: $e');
      // Final fallback
      final authUser = _supabase.auth.currentUser;
      if (authUser != null) {
        _currentUser = InvestorUser.fromSupabaseUser(authUser);
      }
    }
  }

  // Handle sign in event
  Future<void> _handleSignIn(User authUser) async {
    try {
      await _loadCompleteInvestorProfile(authUser.id);
      if (_currentUser == null) {
        _currentUser = InvestorUser.fromSupabaseUser(authUser);
        await _createBasicInvestorRecord(_currentUser!);
      } else {
        await _updateLastLogin(_currentUser!.id);
      }
    } catch (e) {
      _logger.e('Error handling investor sign in: $e');
      _currentUser = InvestorUser.fromSupabaseUser(authUser);
    }
  }

  // Handle user update event
  Future<void> _handleUserUpdate(User authUser) async {
    try {
      if (_currentUser != null) {
        final updatedUser = _currentUser!.copyWith(
          email: authUser.email ?? _currentUser!.email,
          username:
              authUser.userMetadata?['full_name'] as String? ??
              _currentUser!.username,
        );

        await _updateBasicInvestorRecord(updatedUser);
        _currentUser = updatedUser;
      }
    } catch (e) {
      _logger.e('Error handling investor user update: $e');
    }
  }

  // Create basic investor record in investors table
  Future<void> _createBasicInvestorRecord(InvestorUser user) async {
    try {
      final existingInvestor =
          await _supabase
              .from('investors')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();

      if (existingInvestor == null) {
        final insertData = {
          'id': user.id,
          'email': user.email,
          'username': user.username ?? user.email.split('@')[0],
          'portfolio_size': 0,
          'is_verified': false,
          'last_login_at': DateTime.now().toIso8601String(),
          'created_at': user.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _supabase.from('investors').insert(insertData);

        _logger.i(
          '✅ Created basic investor record for: ${user.email} with ID: ${user.id}',
        );
        debugPrint('✅ Created investor record for ID: ${user.id}');
      } else {
        _logger.i('✅ Investor record already exists for: ${user.email}');
      }
    } catch (e) {
      _logger.e('❌ Error creating investor record: $e');
      throw Exception('Failed to create investor record: $e');
    }
  }

  // Update basic investor record in investors table
  Future<void> _updateBasicInvestorRecord(InvestorUser user) async {
    try {
      final updateData = user.toBasicDatabase();

      await _supabase.from('investors').update(updateData).eq('id', user.id);

      _logger.i('✅ Updated basic investor record for: ${user.email}');
      debugPrint('✅ Updated investor record for ID: ${user.id}');
    } catch (e) {
      _logger.e('❌ Error updating investor record: $e');
      throw Exception('Failed to update investor record: $e');
    }
  }

  // Create or update investor profile in investor_profiles table
  Future<void> _createOrUpdateInvestorProfile(InvestorUser user) async {
    try {
      final existingProfile =
          await _supabase
              .from('investor_profiles')
              .select('id')
              .eq('investor_id', user.id)
              .maybeSingle();

      final profileData = user.toProfileDatabase();

      if (existingProfile == null) {
        // Create new profile
        await _supabase.from('investor_profiles').insert(profileData);
        _logger.i('✅ Created investor profile for: ${user.email}');
      } else {
        // Update existing profile
        await _supabase
            .from('investor_profiles')
            .update(profileData)
            .eq('investor_id', user.id);
        _logger.i('✅ Updated investor profile for: ${user.email}');
      }
    } catch (e) {
      _logger.e('❌ Error creating/updating investor profile: $e');
      throw Exception('Failed to create/update investor profile: $e');
    }
  }

  // Update last login timestamp
  Future<void> _updateLastLogin(String userId) async {
    try {
      await _supabase
          .from('investors')
          .update({
            'last_login_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      debugPrint('✅ Updated last login for investor: $userId');
    } catch (e) {
      _logger.w('Error updating last login: $e');
    }
  }

  // ========== AUTHENTICATION METHODS ==========
  Future<bool> signUp({
    String? fullName,
    String? email,
    String? password,
    String? confirmPassword,
  }) async {
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
      _logger.i('Attempting investor signup for: ${this.email}');

      final response = await _supabase.auth.signUp(
        email: this.email,
        password: this.password,
        data: {
          'full_name': fullName ?? this.fullName,
          'email': email ?? this.email,
          'user_type': 'investor',
        },
      );

      if (response.user != null) {
        _logger.i('✅ Investor signup successful: ${this.email}');
        debugPrint('✅ New investor created with ID: ${response.user!.id}');

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
      _logger.e('❌ Auth exception during investor signup: ${e.message}');
      _error = e.message;
      return false;
    } catch (e) {
      _logger.e('❌ Unexpected error during investor signup: $e');
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
    if (email != null) _emailController.text = email;
    if (password != null) _passwordController.text = password;
    if (rememberMe != null) _rememberMe = rememberMe;

    if (!_validateLoginForm()) return false;

    _isAuthenticating = true;
    _error = null;
    notifyListeners();

    try {
      _logger.i('Attempting investor login for: ${this.email}');

      final response = await _supabase.auth.signInWithPassword(
        email: this.email,
        password: this.password,
      );

      if (response.user != null) {
        _logger.i('✅ Investor login successful: ${this.email}');
        debugPrint('✅ Investor logged in with ID: ${response.user!.id}');

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
      _logger.e('❌ Auth exception during investor login: ${e.message}');
      _error = e.message;
      return false;
    } catch (e) {
      _logger.e('❌ Unexpected error during investor login: $e');
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
      await _supabase.auth.signOut();
      _logger.i('✅ Investor signed out successfully');
    } catch (e) {
      _logger.e('❌ Error signing out investor: $e');
      _error = 'Failed to sign out. Please try again.';
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  // ========== PROFILE MANAGEMENT METHODS ==========

  // Update basic investor information
  Future<bool> updateBasicProfile({
    String? username,
    String? avatarUrl,
    int? portfolioSize,
  }) async {
    if (_currentUser == null) {
      _error = 'No user logged in';
      return false;
    }

    try {
      final updatedUser = _currentUser!.copyWith(
        username: username,
        avatarUrl: avatarUrl,
        portfolioSize: portfolioSize,
      );

      await _updateBasicInvestorRecord(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Failed to update basic profile: $e';
      return false;
    }
  }

  // Update professional profile information
  Future<bool> updateProfessionalProfile({
    String? companyName,
    String? title,
    String? bio,
    String? linkedinUrl,
    String? websiteUrl,
    List<String>? industries,
    List<String>? geographicFocus,
  }) async {
    if (_currentUser == null) {
      _error = 'No user logged in';
      return false;
    }

    try {
      final updatedUser = _currentUser!.copyWith(
        companyName: companyName,
        title: title,
        bio: bio,
        linkedinUrl: linkedinUrl,
        websiteUrl: websiteUrl,
        industries: industries,
        geographicFocus: geographicFocus,
      );

      await _createOrUpdateInvestorProfile(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Failed to update professional profile: $e';
      return false;
    }
  }

  // Get all verified investors for discovery
  Future<List<InvestorUser>> getAllInvestors({
    String? searchTerm,
    List<String>? industries,
    List<String>? geographicFocus,
    String? companyFilter,
  }) async {
    try {
      final response = await _supabase.rpc(
        'search_investors_with_profiles',
        params: {
          'search_term': searchTerm,
          'industry_filter': industries,
          'geographic_filter': geographicFocus,
          'company_filter': companyFilter,
        },
      );

      return (response as List)
          .map((data) => InvestorUser.fromJoinedData(data))
          .toList();
    } catch (e) {
      _logger.e('Error fetching investors: $e');
      throw Exception('Failed to fetch investors: $e');
    }
  }

  // Get investor by ID
  Future<InvestorUser?> getInvestorById(String investorId) async {
    try {
      final response = await _supabase.rpc(
        'get_complete_investor_profile',
        params: {'investor_user_id': investorId},
      );

      if (response != null && response.isNotEmpty) {
        return InvestorUser.fromJoinedData(response[0]);
      }
      return null;
    } catch (e) {
      _logger.e('Error fetching investor: $e');
      return null;
    }
  }

  // Check if investor has a professional profile
  bool get hasCompleteProfessionalProfile {
    if (_currentUser == null) return false;
    return _currentUser!.hasProfile;
  }

  // Get profile completion percentage
  double get profileCompletionPercentage {
    if (_currentUser == null) return 0.0;

    int completed = 0;
    int total = 8; // Total number of profile fields

    // Basic fields (4)
    if (_currentUser!.username != null && _currentUser!.username!.isNotEmpty) {
      completed++;
    }
    if (_currentUser!.avatarUrl != null &&
        _currentUser!.avatarUrl!.isNotEmpty) {
      completed++;
    }

    // Professional fields (6)
    if (_currentUser!.companyName != null &&
        _currentUser!.companyName!.isNotEmpty) {
      completed++;
    }
    if (_currentUser!.title != null && _currentUser!.title!.isNotEmpty) {
      completed++;
    }
    if (_currentUser!.bio != null && _currentUser!.bio!.isNotEmpty) completed++;
    if (_currentUser!.linkedinUrl != null &&
        _currentUser!.linkedinUrl!.isNotEmpty) {
      completed++;
    }
    if (_currentUser!.industries.isNotEmpty) completed++;
    if (_currentUser!.geographicFocus.isNotEmpty) completed++;

    return (completed / total) * 100;
  }

  // ========== FORM MANAGEMENT METHODS ==========
  void setFormType(FormType type) {
    _currentFormType = type;
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

  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  void clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _clearValidationErrors();
    _isFormValid = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void enableRealTimeValidation() {
    _validateRealTime = true;
    _validateForm();
  }

  void disableRealTimeValidation() {
    _validateRealTime = false;
    _clearValidationErrors();
  }

  // ========== VALIDATION METHODS ==========
  void _onFormFieldChanged() {
    if (_validateRealTime) {
      _validationTimer?.cancel();
      _validationTimer = Timer(const Duration(milliseconds: 300), () {
        _validateForm();
      });
    }
  }

  void _validateForm() {
    if (_currentFormType == FormType.signup) {
      _validateSignupForm();
    } else {
      _validateLoginForm();
    }
  }

  bool _validateSignupForm() {
    _clearValidationErrors();
    bool isValid = true;

    if (fullName.isEmpty) {
      _nameError = 'Full name is required';
      isValid = false;
    } else if (fullName.length < 2) {
      _nameError = 'Name must be at least 2 characters';
      isValid = false;
    }

    if (email.isEmpty) {
      _emailError = 'Email is required';
      isValid = false;
    } else if (!_isValidEmail(email)) {
      _emailError = 'Please enter a valid email address';
      isValid = false;
    }

    if (password.isEmpty) {
      _passwordError = 'Password is required';
      isValid = false;
    } else if (password.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
      isValid = false;
    }

    if (confirmPassword.isEmpty) {
      _confirmPasswordError = 'Please confirm your password';
      isValid = false;
    } else if (password != confirmPassword) {
      _confirmPasswordError = 'Passwords do not match';
      isValid = false;
    }

    _isFormValid = isValid;
    notifyListeners();
    return isValid;
  }

  bool _validateLoginForm() {
    _clearValidationErrors();
    bool isValid = true;

    if (email.isEmpty) {
      _emailError = 'Email is required';
      isValid = false;
    } else if (!_isValidEmail(email)) {
      _emailError = 'Please enter a valid email address';
      isValid = false;
    }

    if (password.isEmpty) {
      _passwordError = 'Password is required';
      isValid = false;
    }

    _isFormValid = isValid;
    notifyListeners();
    return isValid;
  }

  void _clearValidationErrors() {
    _nameError = null;
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Individual field validation methods for UI
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!_isValidEmail(value.trim())) {
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

  // ========== UTILITY METHODS ==========
  PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    if (password.length < 6) return PasswordStrength.weak;
    if (password.length < 10) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  Future<void> _saveRememberMe(String email) async {
    try {
      _savedEmail = email;
      _logger.i('Remember me saved for investor: $email');
    } catch (e) {
      _logger.w('Error saving remember me for investor: $e');
    }
  }

  // ========== CLEANUP ==========
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

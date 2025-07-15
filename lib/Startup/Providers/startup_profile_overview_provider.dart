// lib/Startup/Providers/startup_profile_overview_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

/**
 * startup_profile_overview_provider.dart
 * 
 * Implements a state management provider for startup profile overview information,
 * handling basic company details like name, tagline, industry and region.
 * 
 * Features:
 * - Core startup profile data management
 * - Auto-saving with debouncing
 * - Form validation
 * - Profile completion tracking
 * - Dirty field tracking for UI updates
 * - Authentication state integration
 * - User-specific data isolation
 * - Database persistence with Supabase
 */

/**
 * StartupProfileOverviewProvider - Change notifier provider for managing
 * startup profile overview data with Supabase integration.
 */
class StartupProfileOverviewProvider with ChangeNotifier {
  // Controllers for profile data
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _taglineController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();

  // Loading and error states
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  Timer? _saveTimer;
  String? _currentUserId;
  StreamSubscription<AuthState>? _authSubscription;

  // Dirty tracking for unsaved changes
  final Set<String> _dirtyFields = <String>{};

  // Flag to prevent infinite loops during initialization
  bool _isInitializing = false;
  bool _isInitialized = false;

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  /**
   * Constructor that sets up authentication listener and
   * initializes data when authenticated.
   */
  StartupProfileOverviewProvider() {
    // Initialize automatically when provider is created and user is authenticated
    _setupAuthListener();
    _addListeners();
    _initializeWhenReady();
  }

  /**
   * Sets up an authentication state listener to handle user changes.
   * Ensures data is isolated between different users.
   */
  void _setupAuthListener() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final User? user = data.session?.user;

      if (event == AuthChangeEvent.signedIn && user != null) {
        // User signed in - check if it's a different user
        if (_currentUserId != null && _currentUserId != user.id) {
          debugPrint(
            '🔄 Different startup user detected, resetting provider state',
          );
          _resetProviderState();
        }
        _currentUserId = user.id;

        // Initialize for new user if not already initialized
        if (!_isInitialized) {
          initialize();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('🔄 Startup user signed out, resetting provider state');
        _resetProviderState();
      }
    });
  }

  /**
   * Checks for authenticated user and initializes data if found.
   * Otherwise sets up listeners for future authentication events.
   */
  void _initializeWhenReady() {
    // Check if there's an authenticated user
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null && !_isInitialized) {
      // User is already authenticated, initialize immediately
      initialize();
    } else {
      // Listen for auth state changes
      _supabase.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        if (event == AuthChangeEvent.signedIn && !_isInitialized) {
          // User just signed in, initialize
          initialize();
        } else if (event == AuthChangeEvent.signedOut) {
          // User signed out, reset state
          _resetProviderState();
        }
      });
    }

    _addListeners();
  }

  /**
   * Resets the provider state when user signs out or changes.
   * Clears all data and cancels pending operations.
   */
  void _resetProviderState() {
    _isInitialized = false;
    _currentUserId = null;
    _removeListeners();
    _companyNameController.clear();
    _taglineController.clear();
    _industryController.clear();
    _regionController.clear();
    _dirtyFields.clear();
    _error = null;
    _saveTimer?.cancel();
    notifyListeners();
    _addListeners();
  }

  /**
   * Sets up listeners for text field changes.
   */
  void _addListeners() {
    _companyNameController.addListener(() => _onFieldChanged('companyName'));
    _taglineController.addListener(() => _onFieldChanged('tagline'));
    _industryController.addListener(() => _onFieldChanged('industry'));
    _regionController.addListener(() => _onFieldChanged('region'));
  }

  /**
   * Removes listeners for text field changes.
   */
  void _removeListeners() {
    _companyNameController.removeListener(() => _onFieldChanged('companyName'));
    _taglineController.removeListener(() => _onFieldChanged('tagline'));
    _industryController.removeListener(() => _onFieldChanged('industry'));
    _regionController.removeListener(() => _onFieldChanged('region'));
  }

  /**
   * Clears all profile data and resets the provider state.
   */
  Future<void> clearAllData() async {
    _removeListeners();

    _companyNameController.clear();
    _taglineController.clear();
    _industryController.clear();
    _regionController.clear();

    _dirtyFields.clear();
    _error = null;
    _isInitialized = false;

    notifyListeners();
    _addListeners();
  }

  /**
   * Resets the provider for a new user.
   * Clears state and reinitializes.
   */
  Future<void> resetForNewUser() async {
    clearAllData();
    await initialize();
  }

  /**
   * Handles field changes by marking fields as dirty and scheduling auto-save.
   * 
   * @param fieldName The field that changed
   */
  void _onFieldChanged(String fieldName) {
    // Don't mark as dirty during initialization
    if (_isInitializing) return;

    _dirtyFields.add(fieldName);
    notifyListeners();

    // Auto-save with debouncing (2 seconds after user stops typing)
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      if (_dirtyFields.contains(fieldName)) {
        saveField(fieldName);
      }
    });
  }

  /**
   * Indicates whether data is currently loading.
   * 
   * @return Loading state
   */
  bool get isLoading => _isLoading;

  /**
   * Indicates whether a save operation is in progress.
   * 
   * @return Saving state
   */
  bool get isSaving => _isSaving;

  /**
   * Provides the latest error message if any.
   * 
   * @return Error message or null
   */
  String? get error => _error;

  /**
   * Checks if a specific field has unsaved changes.
   * 
   * @param field The field name to check
   * @return True if the field has unsaved changes
   */
  bool hasUnsavedChanges(String field) => _dirtyFields.contains(field);

  /**
   * Indicates whether any fields have unsaved changes.
   * 
   * @return True if there are any unsaved changes
   */
  bool get hasAnyUnsavedChanges => _dirtyFields.isNotEmpty;

  /**
   * Clears the current error state.
   */
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /**
   * Initializes the provider with user data.
   * Loads profile data from database if exists.
   */
  Future<void> initialize() async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      _resetProviderState();
      return;
    }

    // Check if we need to reset for different user
    if (_currentUserId != null && _currentUserId != currentUser.id) {
      debugPrint('🔄 User changed during initialization, resetting state');
      _resetProviderState();
    }

    _currentUserId = currentUser.id;

    if (_isInitialized) {
      debugPrint('✅ Provider already initialized for user: ${currentUser.id}');
      await _loadProfileData();
      return;
    }

    _isLoading = true;
    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      await _loadProfileData();
      _isInitialized = true;
      debugPrint('✅ Profile overview initialized for user: ${currentUser.id}');
    } catch (e) {
      _error = 'Failed to initialize profile: $e';
      debugPrint('❌ Error initializing profile: $e');
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /**
   * Loads startup profile data from the database.
   * Temporarily removes listeners to prevent auto-save during loading.
   */
  Future<void> _loadProfileData() async {
    try {
      _removeListeners();

      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      // Verify user consistency
      if (_currentUserId != null && _currentUserId != currentUser.id) {
        debugPrint('⚠️ User mismatch detected in _loadProfileData, resetting');
        _resetProviderState();
        _currentUserId = currentUser.id;
      }

      final userResponse =
          await _supabase
              .from('startup_profiles')
              .select('*')
              .eq('startup_id', currentUser.id)
              .maybeSingle();

      if (userResponse != null) {
        _companyNameController.text = userResponse['company_name'] ?? '';
        _taglineController.text = userResponse['tagline'] ?? '';
        _industryController.text = userResponse['industry'] ?? '';
        _regionController.text = userResponse['region'] ?? '';

        debugPrint('✅ Profile data loaded for user: ${currentUser.id}');
      } else {
        debugPrint('No profile data found for user: ${currentUser.id}');
      }

      _addListeners();
      _dirtyFields.clear();
    } catch (e) {
      _error = 'Failed to load profile data: $e';
      debugPrint('❌ Error loading profile data: $e');
      _addListeners();
      rethrow;
    }
  }

  /**
   * Provides access to the company name text controller.
   * 
   * @return Text controller for company name
   */
  TextEditingController get companyNameController => _companyNameController;

  /**
   * Provides access to the tagline text controller.
   * 
   * @return Text controller for tagline
   */
  TextEditingController get taglineController => _taglineController;

  /**
   * Provides access to the industry text controller.
   * 
   * @return Text controller for industry
   */
  TextEditingController get industryController => _industryController;

  /**
   * Provides access to the region text controller.
   * 
   * @return Text controller for region
   */
  TextEditingController get regionController => _regionController;

  /**
   * Returns the company name text.
   * 
   * @return Company name or null if empty
   */
  String? get companyName =>
      _companyNameController.text.isEmpty ? null : _companyNameController.text;

  /**
   * Returns the tagline text.
   * 
   * @return Tagline or null if empty
   */
  String? get tagline =>
      _taglineController.text.isEmpty ? null : _taglineController.text;

  /**
   * Returns the industry text.
   * 
   * @return Industry or null if empty
   */
  String? get industry =>
      _industryController.text.isEmpty ? null : _industryController.text;

  /**
   * Returns the region text.
   * 
   * @return Region or null if empty
   */
  String? get region =>
      _regionController.text.isEmpty ? null : _regionController.text;

  /**
   * Determines if the profile is complete.
   * All required fields must have content.
   * 
   * @return True if profile is complete
   */
  bool get isProfileComplete {
    return companyName != null &&
        tagline != null &&
        industry != null &&
        region != null;
  }

  /**
   * Calculates the profile completion percentage.
   * 
   * @return Percentage (0-100) of completion
   */
  double get completionPercentage {
    int completedFields = 0;
    if (companyName != null) completedFields++;
    if (tagline != null) completedFields++;
    if (industry != null) completedFields++;
    if (region != null) completedFields++;
    return (completedFields / 4) * 100;
  }

  /**
   * Saves a specific field to the database.
   * Only saves if the field has been marked as dirty.
   * 
   * @param fieldName The field to save
   * @return True if save was successful, false otherwise
   */
  Future<bool> saveField(String fieldName) async {
    if (!_dirtyFields.contains(fieldName)) return true;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Prepare update data based on field name
      Map<String, dynamic> updateData = {};

      switch (fieldName) {
        case 'companyName':
          updateData['company_name'] = _companyNameController.text.trim();
          break;
        case 'tagline':
          updateData['tagline'] = _taglineController.text.trim();
          break;
        case 'industry':
          updateData['industry'] = _industryController.text.trim();
          break;
        case 'region':
          updateData['region'] = _regionController.text.trim();
          break;
        default:
          debugPrint('Unknown field: $fieldName');
          return false;
      }

      updateData['updated_at'] = DateTime.now().toIso8601String();

      // Check if record exists first
      final existingRecord =
          await _supabase
              .from('startup_profiles')
              .select('id')
              .eq('startup_id', currentUser.id)
              .maybeSingle();

      if (existingRecord != null) {
        // Record exists - UPDATE it
        await _supabase
            .from('startup_profiles')
            .update(updateData)
            .eq('startup_id', currentUser.id);
      } else {
        // Record doesn't exist - INSERT it
        updateData['startup_id'] = currentUser.id;
        await _supabase.from('startup_profiles').insert(updateData);
      }

      _dirtyFields.remove(fieldName);
      debugPrint(
        '✅ Successfully saved $fieldName to Supabase for user: ${currentUser.id}',
      );
      return true;
    } catch (e) {
      _error = 'Failed to save $fieldName: $e';
      debugPrint('❌ Error saving $fieldName: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /**
   * Saves all dirty fields to the database in a single operation.
   * 
   * @return True if save was successful, false otherwise
   */
  Future<bool> saveAllFields() async {
    if (_dirtyFields.isEmpty) return true;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Prepare update data for all dirty fields
      Map<String, dynamic> updateData = {};

      if (_dirtyFields.contains('companyName')) {
        updateData['company_name'] = _companyNameController.text.trim();
      }
      if (_dirtyFields.contains('tagline')) {
        updateData['tagline'] = _taglineController.text.trim();
      }
      if (_dirtyFields.contains('industry')) {
        updateData['industry'] = _industryController.text.trim();
      }
      if (_dirtyFields.contains('region')) {
        updateData['region'] = _regionController.text.trim();
      }

      updateData['updated_at'] = DateTime.now().toIso8601String();

      // Check if record exists first
      final existingRecord =
          await _supabase
              .from('startup_profiles')
              .select('id')
              .eq('startup_id', currentUser.id)
              .maybeSingle();

      if (existingRecord != null) {
        // Record exists - UPDATE it
        await _supabase
            .from('startup_profiles')
            .update(updateData)
            .eq('startup_id', currentUser.id);
      } else {
        // Record doesn't exist - INSERT it
        updateData['startup_id'] = currentUser.id;
        await _supabase.from('startup_profiles').insert(updateData);
      }

      _dirtyFields.clear();
      debugPrint(
        '✅ Successfully saved all profile changes to Supabase for user: ${currentUser.id}',
      );
      return true;
    } catch (e) {
      _error = 'Failed to save profile changes: $e';
      debugPrint('❌ Error saving profile changes: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /**
   * Validates the company name field.
   * 
   * @param value The company name to validate
   * @return Error message or null if valid
   */
  String? validateCompanyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Company name is required';
    }
    if (value.trim().length < 2) {
      return 'Company name must be at least 2 characters';
    }
    return null;
  }

  /**
   * Validates the tagline field.
   * 
   * @param value The tagline to validate
   * @return Error message or null if valid
   */
  String? validateTagline(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tagline is required';
    }
    if (value.trim().length < 10) {
      return 'Tagline must be at least 10 characters';
    }
    return null;
  }

  /**
   * Validates the industry field.
   * 
   * @param value The industry to validate
   * @return Error message or null if valid
   */
  String? validateIndustry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Industry is required';
    }
    return null;
  }

  /**
   * Validates the region field.
   * 
   * @param value The region to validate
   * @return Error message or null if valid
   */
  String? validateRegion(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Region is required';
    }
    return null;
  }

  /**
   * Returns the profile data as a map for export or display.
   * 
   * @return Map containing all profile fields
   */
  Map<String, String> getProfileData() {
    return {
      'companyName': _companyNameController.text.trim(),
      'tagline': _taglineController.text.trim(),
      'industry': _industryController.text.trim(),
      'region': _regionController.text.trim(),
    };
  }

  /**
   * Updates profile data programmatically with new values.
   * 
   * @param companyName Optional new company name
   * @param tagline Optional new tagline
   * @param industry Optional new industry
   * @param region Optional new region
   */
  void updateProfileData({
    String? companyName,
    String? tagline,
    String? industry,
    String? region,
  }) {
    _removeListeners();

    if (companyName != null) _companyNameController.text = companyName;
    if (tagline != null) _taglineController.text = tagline;
    if (industry != null) _industryController.text = industry;
    if (region != null) _regionController.text = region;

    _addListeners();
    notifyListeners();
  }

  /**
   * Returns a summary of the profile status.
   * 
   * @return Map with completion status and data
   */
  Map<String, dynamic> getProfileStatus() {
    return {
      'completionPercentage': completionPercentage,
      'isComplete': isProfileComplete,
      'hasUnsavedChanges': hasAnyUnsavedChanges,
      'profileData': getProfileData(),
    };
  }

  /**
   * Clears all profile data.
   * Shorthand for clearAllData().
   */
  Future<void> clearProfileData() async {
    await clearAllData();
  }

  /**
   * Refreshes profile data from the database.
   * Useful for manual refresh operations.
   */
  Future<void> refreshFromDatabase() async {
    _isInitialized = false;
    await initialize();
  }

  /**
   * Cleans up resources when the provider is disposed.
   */
  @override
  void dispose() {
    _authSubscription?.cancel(); // Cancel auth listener
    _saveTimer?.cancel();
    _removeListeners();
    _companyNameController.dispose();
    _taglineController.dispose();
    _industryController.dispose();
    _regionController.dispose();
    super.dispose();
  }
}

// lib/Startup/Providers/startup_profile_overview_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

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

  // Dirty tracking for unsaved changes
  final Set<String> _dirtyFields = <String>{};

  // Flag to prevent infinite loops during initialization
  bool _isInitializing = false;
  bool _isInitialized = false;

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  StartupProfileOverviewProvider() {
    // Initialize automatically when provider is created and user is authenticated
    _initializeWhenReady();
  }

  // Check if user is authenticated and initialize
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

  // Reset provider state on logout
  void _resetProviderState() {
    _isInitialized = false;
    _removeListeners();
    _companyNameController.clear();
    _taglineController.clear();
    _industryController.clear();
    _regionController.clear();
    _dirtyFields.clear();
    _error = null;
    notifyListeners();
    _addListeners();
  }

  void _addListeners() {
    _companyNameController.addListener(() => _onFieldChanged('companyName'));
    _taglineController.addListener(() => _onFieldChanged('tagline'));
    _industryController.addListener(() => _onFieldChanged('industry'));
    _regionController.addListener(() => _onFieldChanged('region'));
  }

  void _removeListeners() {
    _companyNameController.removeListener(() => _onFieldChanged('companyName'));
    _taglineController.removeListener(() => _onFieldChanged('tagline'));
    _industryController.removeListener(() => _onFieldChanged('industry'));
    _regionController.removeListener(() => _onFieldChanged('region'));
  }

  // Add this method to clear all data
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

  // Add method to reset for new user
  Future<void> resetForNewUser() async {
    clearAllData();
    await initialize();
  }

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

  // Getters for states
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  // Check if specific field has unsaved changes
  bool hasUnsavedChanges(String field) => _dirtyFields.contains(field);
  bool get hasAnyUnsavedChanges => _dirtyFields.isNotEmpty;

  // Clear error method
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Initialize and load data from Supabase
  Future<void> initialize() async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      clearAllData();
      return;
    }

    if (_isInitialized) {
      // If already initialized, just refresh data
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
      debugPrint('✅ Profile overview initialized successfully');
    } catch (e) {
      _error = 'Failed to initialize profile: $e';
      debugPrint('❌ Error initializing profile: $e');
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfileData() async {
    try {
      // Remove listeners temporarily to prevent triggering dirty state
      _removeListeners();

      // Get current user
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      // Load from startup_profiles table
      final userResponse =
          await _supabase
              .from('startup_profiles')
              .select('*')
              .eq('startup_id', currentUser.id)
              .maybeSingle();

      if (userResponse != null) {
        // Populate controllers with loaded data
        _companyNameController.text = userResponse['company_name'] ?? '';
        _taglineController.text = userResponse['tagline'] ?? '';
        _industryController.text = userResponse['industry'] ?? '';
        _regionController.text = userResponse['region'] ?? '';

        debugPrint(
          '✅ Profile data loaded successfully for user: ${currentUser.id}',
        );
        debugPrint(
          '   - Company: ${userResponse['company_name'] ?? "Not Set"}',
        );
        debugPrint('   - Tagline: ${userResponse['tagline'] ?? "Not Set"}');
        debugPrint('   - Industry: ${userResponse['industry'] ?? "Not Set"}');
        debugPrint('   - Region: ${userResponse['region'] ?? "Not Set"}');
      } else {
        debugPrint('No profile data found for user: ${currentUser.id}');
      }

      // Re-add listeners
      _addListeners();
      _dirtyFields.clear(); // Clear dirty state after loading
    } catch (e) {
      _error = 'Failed to load profile data: $e';
      debugPrint('❌ Error loading profile data: $e');

      // Re-add listeners even on error
      _addListeners();
      rethrow;
    }
  }

  // Getters for controllers
  TextEditingController get companyNameController => _companyNameController;
  TextEditingController get taglineController => _taglineController;
  TextEditingController get industryController => _industryController;
  TextEditingController get regionController => _regionController;

  // Getters for values
  String? get companyName =>
      _companyNameController.text.isEmpty ? null : _companyNameController.text;
  String? get tagline =>
      _taglineController.text.isEmpty ? null : _taglineController.text;
  String? get industry =>
      _industryController.text.isEmpty ? null : _industryController.text;
  String? get region =>
      _regionController.text.isEmpty ? null : _regionController.text;

  // Check if profile is complete
  bool get isProfileComplete {
    return companyName != null &&
        tagline != null &&
        industry != null &&
        region != null;
  }

  // Get completion percentage
  double get completionPercentage {
    int completedFields = 0;
    if (companyName != null) completedFields++;
    if (tagline != null) completedFields++;
    if (industry != null) completedFields++;
    if (region != null) completedFields++;
    return (completedFields / 4) * 100;
  }

  // Save specific field to Supabase
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

      // FIXED: Check if record exists first
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

      // FIXED: Check if record exists first
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

  // Validation methods
  String? validateCompanyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Company name is required';
    }
    if (value.trim().length < 2) {
      return 'Company name must be at least 2 characters';
    }
    return null;
  }

  String? validateTagline(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tagline is required';
    }
    if (value.trim().length < 10) {
      return 'Tagline must be at least 10 characters';
    }
    return null;
  }

  String? validateIndustry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Industry is required';
    }
    return null;
  }

  String? validateRegion(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Region is required';
    }
    return null;
  }

  // Get profile data as map
  Map<String, String> getProfileData() {
    return {
      'companyName': _companyNameController.text.trim(),
      'tagline': _taglineController.text.trim(),
      'industry': _industryController.text.trim(),
      'region': _regionController.text.trim(),
    };
  }

  // Method to update profile data programmatically
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

  // Get profile status summary
  Map<String, dynamic> getProfileStatus() {
    return {
      'completionPercentage': completionPercentage,
      'isComplete': isProfileComplete,
      'hasUnsavedChanges': hasAnyUnsavedChanges,
      'profileData': getProfileData(),
    };
  }

  Future<void> clearProfileData() async {
    await clearAllData();
  }

  Future<void> refreshFromDatabase() async {
    _isInitialized = false;
    await initialize();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _removeListeners();
    _companyNameController.dispose();
    _taglineController.dispose();
    _industryController.dispose();
    _regionController.dispose();
    super.dispose();
  }
}

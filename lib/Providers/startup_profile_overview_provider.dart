// lib/Providers/startup_profile_overview_provider.dart
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

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  StartupProfileOverviewProvider() {
    // Initialize automatically when provider is created
    initialize();
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

  void _onFieldChanged(String fieldName) {
    // Don't mark as dirty during initialization
    if (_isInitializing) return;

    _dirtyFields.add(fieldName);
    notifyListeners();

    // Cancel previous timer
    _saveTimer?.cancel();

    // Set new timer - saves 1 second after user stops typing
    _saveTimer = Timer(Duration(seconds: 1), () {
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
    _isLoading = true;
    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      // Remove listeners temporarily to prevent triggering dirty state
      _removeListeners();

      // Get current user
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Load user data from Supabase
      final response =
          await _supabase
              .from('users')
              .select('company_name, tagline, industry, region')
              .eq('id', currentUser.id)
              .maybeSingle();

      if (response != null) {
        // Populate controllers with loaded data
        _companyNameController.text = response['company_name'] ?? '';
        _taglineController.text = response['tagline'] ?? '';
        _industryController.text = response['industry'] ?? '';
        _regionController.text = response['region'] ?? '';
      }

      // Re-add listeners
      _addListeners();

      _dirtyFields.clear(); // Clear dirty state after loading
      debugPrint('Profile overview data loaded successfully');
    } catch (e) {
      _error = 'Failed to load profile data: $e';
      debugPrint('Error loading startup profile data: $e');
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save specific field to Supabase
  Future<bool> saveField(String fieldName) async {
    if (!_dirtyFields.contains(fieldName)) return true;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Get current user
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Prepare update data based on field name
      Map<String, dynamic> updateData = {};

      switch (fieldName) {
        case 'companyName':
          updateData['company_name'] = _companyNameController.text;
          break;
        case 'tagline':
          updateData['tagline'] = _taglineController.text;
          break;
        case 'industry':
          updateData['industry'] = _industryController.text;
          break;
        case 'region':
          updateData['region'] = _regionController.text;
          break;
        default:
          debugPrint('Unknown field: $fieldName');
          return false;
      }

      // Add updated_at timestamp
      updateData['updated_at'] = DateTime.now().toIso8601String();

      // Update in Supabase
      await _supabase.from('users').update(updateData).eq('id', currentUser.id);

      _dirtyFields.remove(fieldName);
      debugPrint('Successfully saved $fieldName to Supabase');
      return true;
    } catch (e) {
      _error = 'Failed to save $fieldName: $e';
      debugPrint('Error saving $fieldName: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Save all dirty fields to Supabase
  Future<bool> saveAllChanges() async {
    if (_dirtyFields.isEmpty) return true;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Get current user
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Prepare update data for all dirty fields
      Map<String, dynamic> updateData = {};

      if (_dirtyFields.contains('companyName')) {
        updateData['company_name'] = _companyNameController.text;
      }
      if (_dirtyFields.contains('tagline')) {
        updateData['tagline'] = _taglineController.text;
      }
      if (_dirtyFields.contains('industry')) {
        updateData['industry'] = _industryController.text;
      }
      if (_dirtyFields.contains('region')) {
        updateData['region'] = _regionController.text;
      }

      // Add updated_at timestamp
      updateData['updated_at'] = DateTime.now().toIso8601String();

      // Update in Supabase
      await _supabase.from('users').update(updateData).eq('id', currentUser.id);

      _dirtyFields.clear();
      debugPrint('Successfully saved all changes to Supabase');
      return true;
    } catch (e) {
      _error = 'Failed to save changes: $e';
      debugPrint('Error saving all changes: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Create user record if it doesn't exist
  Future<bool> createUserRecord() async {
    try {
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if user record already exists
      final existingUser =
          await _supabase
              .from('users')
              .select('id')
              .eq('id', currentUser.id)
              .maybeSingle();

      if (existingUser == null) {
        // Create new user record
        await _supabase.from('users').insert({
          'id': currentUser.id,
          'email': currentUser.email,
          'username': currentUser.userMetadata?['username'],
          'user_status': 'startup', // Default to startup
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'is_verified': currentUser.emailConfirmedAt != null,
        });

        debugPrint('Created new user record in Supabase');
      }

      return true;
    } catch (e) {
      _error = 'Failed to create user record: $e';
      debugPrint('Error creating user record: $e');
      return false;
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

  // Get profile data as map
  Map<String, String> getProfileData() {
    return {
      'companyName': _companyNameController.text,
      'tagline': _taglineController.text,
      'industry': _industryController.text,
      'region': _regionController.text,
    };
  }

  // Clear all profile data
  Future<void> clearProfileData() async {
    _removeListeners();

    _companyNameController.clear();
    _taglineController.clear();
    _industryController.clear();
    _regionController.clear();
    _dirtyFields.clear();

    _addListeners();
    notifyListeners();

    try {
      // Clear data from Supabase
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        await _supabase
            .from('users')
            .update({
              'company_name': null,
              'tagline': null,
              'industry': null,
              'region': null,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', currentUser.id);
      }
    } catch (e) {
      _error = 'Failed to clear profile data: $e';
      debugPrint('Error clearing profile data: $e');
    }
  }

  // Method to update profile data programmatically
  void updateProfileData({
    String? companyName,
    String? tagline,
    String? industry,
    String? region,
  }) {
    _removeListeners();

    if (companyName != null) {
      _companyNameController.text = companyName;
      _dirtyFields.add('companyName');
    }
    if (tagline != null) {
      _taglineController.text = tagline;
      _dirtyFields.add('tagline');
    }
    if (industry != null) {
      _industryController.text = industry;
      _dirtyFields.add('industry');
    }
    if (region != null) {
      _regionController.text = region;
      _dirtyFields.add('region');
    }

    _addListeners();
    notifyListeners();
  }

  // Method to force notification (can be called externally)
  void forceUpdate() {
    notifyListeners();
  }

  // Force refresh from database
  Future<void> refreshFromDatabase() async {
    await initialize();
  }

  // Validation methods
  String? validateCompanyName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your company name';
    }
    return null;
  }

  String? validateTagline(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your tagline';
    }
    return null;
  }

  String? validateIndustry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your industry';
    }
    return null;
  }

  String? validateRegion(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your region';
    }
    return null;
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

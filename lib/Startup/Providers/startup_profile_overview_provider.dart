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
    // Initialize automatically when provider is created
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
      debugPrint('Profile overview initialized successfully');
    } catch (e) {
      _error = 'Failed to initialize profile: $e';
      debugPrint('Error initializing profile: $e');
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
      if (currentUser == null) {
        debugPrint('No authenticated user found');
        return;
      }

      // Load user profile data
      final userResponse =
          await _supabase
              .from('users')
              .select('company_name, tagline, industry, region')
              .eq('id', currentUser.id)
              .maybeSingle();

      if (userResponse != null) {
        // Populate controllers with loaded data
        _companyNameController.text = userResponse['company_name'] ?? '';
        _taglineController.text = userResponse['tagline'] ?? '';
        _industryController.text = userResponse['industry'] ?? '';
        _regionController.text = userResponse['region'] ?? '';

        debugPrint('Profile data loaded successfully');
      } else {
        debugPrint('No profile data found for user');
      }

      // Re-add listeners
      _addListeners();
      _dirtyFields.clear(); // Clear dirty state after loading
    } catch (e) {
      _error = 'Failed to load profile data: $e';
      debugPrint('Error loading profile data: $e');

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
  Future<bool> saveAllFields() async {
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

      // Always update timestamp
      updateData['updated_at'] = DateTime.now().toIso8601String();

      // Update in Supabase
      await _supabase.from('users').update(updateData).eq('id', currentUser.id);

      _dirtyFields.clear();
      debugPrint('Successfully saved all profile changes to Supabase');
      return true;
    } catch (e) {
      _error = 'Failed to save profile changes: $e';
      debugPrint('Error saving profile changes: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
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

  // Clear all profile data
  Future<void> clearProfileData() async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Remove listeners temporarily
      _removeListeners();

      // Clear controllers
      _companyNameController.clear();
      _taglineController.clear();
      _industryController.clear();
      _regionController.clear();
      _dirtyFields.clear();

      // Re-add listeners
      _addListeners();

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

      debugPrint('Profile data cleared successfully');
    } catch (e) {
      _error = 'Failed to clear profile data: $e';
      debugPrint('Error clearing profile data: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
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
    _isInitialized = false;
    await initialize();
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
    if (value.trim().length > 100) {
      return 'Tagline must be less than 100 characters';
    }
    return null;
  }

  String? validateIndustry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Industry is required';
    }
    if (value.trim().length < 2) {
      return 'Industry must be at least 2 characters';
    }
    return null;
  }

  String? validateRegion(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Region is required';
    }
    if (value.trim().length < 2) {
      return 'Region must be at least 2 characters';
    }
    return null;
  }

  // Get profile completion percentage
  double get completionPercentage {
    int completedFields = 0;
    const int totalFields = 4;

    if (companyName != null) completedFields++;
    if (tagline != null) completedFields++;
    if (industry != null) completedFields++;
    if (region != null) completedFields++;

    return completedFields / totalFields;
  }

  // Get completed fields count
  int get completedFieldsCount {
    int count = 0;
    if (companyName != null) count++;
    if (tagline != null) count++;
    if (industry != null) count++;
    if (region != null) count++;
    return count;
  }

  // Get profile summary
  Map<String, dynamic> getProfileSummary() {
    return {
      'completionPercentage': completionPercentage,
      'completedFields': completedFieldsCount,
      'totalFields': 4,
      'isComplete': isProfileComplete,
      'hasUnsavedChanges': hasAnyUnsavedChanges,
      'profileData': getProfileData(),
    };
  }

  // Export profile data for backup/sharing
  Map<String, dynamic> exportProfileData() {
    return {
      'companyName': companyName,
      'tagline': tagline,
      'industry': industry,
      'region': region,
      'completionPercentage': completionPercentage,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  // Import profile data
  Future<bool> importProfileData(Map<String, String> data) async {
    try {
      updateProfileData(
        companyName: data['companyName'],
        tagline: data['tagline'],
        industry: data['industry'],
        region: data['region'],
      );

      // Save all changes to Supabase
      await saveAllFields();

      debugPrint('Profile data imported successfully');
      return true;
    } catch (e) {
      _error = 'Failed to import profile data: $e';
      debugPrint('Error importing profile data: $e');
      return false;
    }
  }

  // Get profile validation errors
  List<String> getValidationErrors() {
    List<String> errors = [];

    final companyNameError = validateCompanyName(_companyNameController.text);
    if (companyNameError != null) errors.add('Company Name: $companyNameError');

    final taglineError = validateTagline(_taglineController.text);
    if (taglineError != null) errors.add('Tagline: $taglineError');

    final industryError = validateIndustry(_industryController.text);
    if (industryError != null) errors.add('Industry: $industryError');

    final regionError = validateRegion(_regionController.text);
    if (regionError != null) errors.add('Region: $regionError');

    return errors;
  }

  // Check if form is valid
  bool get isFormValid => getValidationErrors().isEmpty;

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

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class StartupProfileOverviewProvider with ChangeNotifier {
  // Keys for SharedPreferences
  static const String _companyNameKey = 'startup_company_name';
  static const String _taglineKey = 'startup_tagline';
  static const String _industryKey = 'startup_industry';
  static const String _regionKey = 'startup_region';

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

  // Initialize and load data from SharedPreferences
  Future<void> initialize() async {
    _isLoading = true;
    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove listeners temporarily to prevent triggering dirty state
      _removeListeners();

      // Load data and sync with controllers
      final companyName = prefs.getString(_companyNameKey) ?? '';
      final tagline = prefs.getString(_taglineKey) ?? '';
      final industry = prefs.getString(_industryKey) ?? '';
      final region = prefs.getString(_regionKey) ?? '';

      // Sync controllers with loaded data
      if (_companyNameController.text != companyName) {
        _companyNameController.text = companyName;
      }
      if (_taglineController.text != tagline) {
        _taglineController.text = tagline;
      }
      if (_industryController.text != industry) {
        _industryController.text = industry;
      }
      if (_regionController.text != region) {
        _regionController.text = region;
      }

      // Re-add listeners
      _addListeners();

      _dirtyFields.clear(); // Clear dirty state after loading
    } catch (e) {
      _error = 'Failed to load profile data: $e';
      debugPrint('Error loading startup profile data: $e');
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save specific field to preferences
  Future<bool> saveField(String fieldName) async {
    if (!_dirtyFields.contains(fieldName)) return true;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      String prefKey = _getPrefKeyForField(fieldName);
      String value = _getValueForField(fieldName);

      await prefs.setString(prefKey, value);
      _dirtyFields.remove(fieldName);

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

  // Save all dirty fields
  Future<bool> saveAllChanges() async {
    if (_dirtyFields.isEmpty) return true;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      for (String fieldName in _dirtyFields.toList()) {
        String prefKey = _getPrefKeyForField(fieldName);
        String value = _getValueForField(fieldName);
        await prefs.setString(prefKey, value);
      }

      _dirtyFields.clear();
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

  // Helper methods
  String _getPrefKeyForField(String fieldName) {
    switch (fieldName) {
      case 'companyName':
        return _companyNameKey;
      case 'tagline':
        return _taglineKey;
      case 'industry':
        return _industryKey;
      case 'region':
        return _regionKey;
      default:
        throw ArgumentError('Unknown field: $fieldName');
    }
  }

  String _getValueForField(String fieldName) {
    switch (fieldName) {
      case 'companyName':
        return _companyNameController.text;
      case 'tagline':
        return _taglineController.text;
      case 'industry':
        return _industryController.text;
      case 'region':
        return _regionController.text;
      default:
        throw ArgumentError('Unknown field: $fieldName');
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_companyNameKey);
      await prefs.remove(_taglineKey);
      await prefs.remove(_industryKey);
      await prefs.remove(_regionKey);
    } catch (e) {
      _error = 'Failed to clear profile data: $e';
      debugPrint('Error clearing profile preferences: $e');
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
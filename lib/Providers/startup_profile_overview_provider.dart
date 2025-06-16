// lib/Providers/startup_profile_overview_provider.dart
import 'package:flutter/material.dart';

class StartupProfileOverviewProvider with ChangeNotifier {
  // Controllers for profile data
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _taglineController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();

  // Loading and error states
  bool _isLoading = false;
  String? _error;

  // Dirty tracking for unsaved changes
  final Set<String> _dirtyFields = <String>{};

  // Initialization flag
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
  }

  // Getters for states
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check if specific field has unsaved changes
  bool hasUnsavedChanges(String field) => _dirtyFields.contains(field);
  bool get hasAnyUnsavedChanges => _dirtyFields.isNotEmpty;

  // Clear error method
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Initialize and setup listeners
  Future<void> initialize() async {
    _isLoading = true;
    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      // Remove listeners temporarily to prevent triggering dirty state
      _removeListeners();

      // Add listeners after initialization
      _addListeners();

      _dirtyFields.clear(); // Clear dirty state after loading
    } catch (e) {
      _error = 'Failed to initialize profile data: $e';
      debugPrint('Error initializing startup profile data: $e');
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mock save methods (kept for API compatibility)
  Future<bool> saveField(String fieldName) async {
    _dirtyFields.remove(fieldName);
    notifyListeners();
    return true;
  }

  // Save all changes (now just clears dirty fields)
  Future<bool> saveAllChanges() async {
    _dirtyFields.clear();
    notifyListeners();
    return true;
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
    _removeListeners();
    _companyNameController.dispose();
    _taglineController.dispose();
    _industryController.dispose();
    _regionController.dispose();
    super.dispose();
  }
}

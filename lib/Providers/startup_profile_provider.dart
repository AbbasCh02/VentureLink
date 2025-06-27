import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

class StartupProfileProvider with ChangeNotifier {
  // Text controllers
  final TextEditingController _ideaDescriptionController =
      TextEditingController();
  final TextEditingController _fundingGoalController = TextEditingController();

  // Profile image
  File? _profileImage;

  // Pitch deck files
  List<File> _pitchDeckFiles = [];
  List<Widget> _pitchDeckThumbnails = [];
  bool _isPitchDeckSubmitted = false;
  DateTime? _pitchDeckSubmissionDate;

  // Auto-save timer
  Timer? _saveTimer;

  // Funding information
  int? _fundingGoalAmount;
  String? _selectedFundingPhase;

  // Loading and error states
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // Dirty tracking for unsaved changes
  final Set<String> _dirtyFields = <String>{};

  // Flag to prevent infinite loops during initialization
  bool _isInitializing = false;
  bool _isInitialized = false;

  StartupProfileProvider() {
    // Initialize automatically when provider is created
    initialize();
  }

  void _addListeners() {
    _ideaDescriptionController.addListener(
      () => _onFieldChanged('ideaDescription'),
    );
    _fundingGoalController.addListener(() => _onFieldChanged('fundingGoal'));
  }

  void _removeListeners() {
    _ideaDescriptionController.removeListener(
      () => _onFieldChanged('ideaDescription'),
    );
    _fundingGoalController.removeListener(() => _onFieldChanged('fundingGoal'));
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
  bool get isInitialized => _isInitialized;

  // Check if specific field has unsaved changes
  bool hasUnsavedChanges(String field) => _dirtyFields.contains(field);
  bool get hasAnyUnsavedChanges => _dirtyFields.isNotEmpty;

  // Clear error method
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Initialize and load data from SharedPreferences
  // Replace the entire initialize() method with:
  // Replace the entire initialize() method with:
  Future<void> initialize() async {
    if (_isInitialized) return; // Prevent multiple initializations

    _isLoading = true;
    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      // Remove listeners temporarily
      _removeListeners();

      // TODO: Load data from Supabase here
      // For now, just initialize with empty values

      // Re-add listeners
      _addListeners();

      _dirtyFields.clear(); // Clear dirty state after loading
      _isInitialized = true;
    } catch (e) {
      _error = 'Failed to load startup profile data: $e';
      debugPrint('Error loading startup profile data: $e');
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Force re-sync data (useful for debugging or manual refresh)
  Future<void> refreshData() async {
    _isInitialized = false;
    await initialize();
  }

  // Save specific field to preferences
  Future<bool> saveField(String fieldName) async {
    if (!_dirtyFields.contains(fieldName)) return true;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Save to Supabase here based on fieldName
      // For now, just clear the dirty state
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
  // Replace the entire saveAllChanges() method with:
  Future<bool> saveAllChanges() async {
    if (_dirtyFields.isEmpty) return true;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Save all fields to Supabase here
      // For now, just clear all dirty states
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

  // Getters for controllers
  TextEditingController get ideaDescriptionController =>
      _ideaDescriptionController;
  TextEditingController get fundingGoalController => _fundingGoalController;

  // Getters for data
  File? get profileImage => _profileImage;
  List<File> get pitchDeckFiles => _pitchDeckFiles;
  List<Widget> get pitchDeckThumbnails => _pitchDeckThumbnails;
  bool get isPitchDeckSubmitted => _isPitchDeckSubmitted;
  DateTime? get pitchDeckSubmissionDate => _pitchDeckSubmissionDate;
  int? get fundingGoalAmount => _fundingGoalAmount;
  String? get selectedFundingPhase => _selectedFundingPhase;

  // Getters for text values
  String? get ideaDescription =>
      _ideaDescriptionController.text.isEmpty
          ? null
          : _ideaDescriptionController.text;

  // Setters with auto-save for immediate actions
  void setProfileImage(File? image) {
    _profileImage = image;
    _dirtyFields.add('profileImage');
    notifyListeners();
    // Save immediately for file operations
    saveField('profileImage');
  }

  void setFundingGoalAmount(int? amount) {
    _fundingGoalAmount = amount;
    _dirtyFields.add('fundingGoalAmount');

    // Keep controller in sync but avoid infinite loops
    final currentText = _fundingGoalController.text;
    final newText = amount?.toString() ?? '';
    if (currentText != newText) {
      _removeListeners();
      _fundingGoalController.text = newText;
      _addListeners();
    }
    notifyListeners();
    // Save immediately for dropdowns/selectors
    saveField('fundingGoalAmount');
  }

  void setSelectedFundingPhase(String? phase) {
    _selectedFundingPhase = phase;
    _dirtyFields.add('selectedFundingPhase');
    notifyListeners();
    // Save immediately for dropdowns/selectors
    saveField('selectedFundingPhase');
  }

  // Pitch deck methods with auto-save
  void setPitchDeckFiles(List<File> files, List<Widget> thumbnails) {
    _pitchDeckFiles = List.from(files);
    _pitchDeckThumbnails = List.from(thumbnails);
    _dirtyFields.add('pitchDeckFiles');

    // Reset submission status when files change
    if (_isPitchDeckSubmitted) {
      _isPitchDeckSubmitted = false;
      _pitchDeckSubmissionDate = null;
      _dirtyFields.add('pitchDeckSubmission');
    }
    notifyListeners();

    // Save immediately for file operations
    saveField('pitchDeckFiles');
    if (_dirtyFields.contains('pitchDeckSubmission')) {
      saveField('pitchDeckSubmission');
    }
  }

  void addPitchDeckFiles(List<File> files, List<Widget> thumbnails) {
    _pitchDeckFiles.addAll(files);
    _pitchDeckThumbnails.addAll(thumbnails);
    _dirtyFields.add('pitchDeckFiles');

    // Reset submission status when files change
    if (_isPitchDeckSubmitted) {
      _isPitchDeckSubmitted = false;
      _pitchDeckSubmissionDate = null;
      _dirtyFields.add('pitchDeckSubmission');
    }
    notifyListeners();

    // Save immediately for file operations
    saveField('pitchDeckFiles');
    if (_dirtyFields.contains('pitchDeckSubmission')) {
      saveField('pitchDeckSubmission');
    }
  }

  void removePitchDeckFile(int index) {
    if (index >= 0 && index < _pitchDeckFiles.length) {
      _pitchDeckFiles.removeAt(index);
      _pitchDeckThumbnails.removeAt(index);
      _dirtyFields.add('pitchDeckFiles');

      // Reset submission status when files change
      if (_isPitchDeckSubmitted) {
        _isPitchDeckSubmitted = false;
        _pitchDeckSubmissionDate = null;
        _dirtyFields.add('pitchDeckSubmission');
      }
      notifyListeners();

      // Save immediately for file operations
      saveField('pitchDeckFiles');
      if (_dirtyFields.contains('pitchDeckSubmission')) {
        saveField('pitchDeckSubmission');
      }
    }
  }

  void clearPitchDeckFiles() {
    _pitchDeckFiles.clear();
    _pitchDeckThumbnails.clear();
    _isPitchDeckSubmitted = false;
    _pitchDeckSubmissionDate = null;
    _dirtyFields.add('pitchDeckFiles');
    _dirtyFields.add('pitchDeckSubmission');
    notifyListeners();

    // Save immediately for clear operations
    saveField('pitchDeckFiles');
    saveField('pitchDeckSubmission');
  }

  // Submit pitch deck files
  Future<void> submitPitchDeckFiles() async {
    if (_pitchDeckFiles.isEmpty) {
      throw Exception('No files to submit');
    }

    try {
      // Set submission status
      _isPitchDeckSubmitted = true;
      _pitchDeckSubmissionDate = DateTime.now();
      _dirtyFields.add('pitchDeckSubmission');

      // TODO: Upload files to Supabase storage and save metadata
      // For now, just update state

      notifyListeners();
    } catch (e) {
      // Reset on error
      _isPitchDeckSubmitted = false;
      _pitchDeckSubmissionDate = null;
      rethrow; // Changed from 'throw e' to 'rethrow'
    }
  }

  // Get submission status info
  Map<String, dynamic> getPitchDeckSubmissionInfo() {
    return {
      'isSubmitted': _isPitchDeckSubmitted,
      'submissionDate': _pitchDeckSubmissionDate?.toIso8601String(),
      'fileCount': _pitchDeckFiles.length,
      'files':
          _pitchDeckFiles
              .map(
                (file) => {
                  'name': file.path.split('/').last,
                  'path': file.path,
                  'size': file.lengthSync(),
                },
              )
              .toList(),
    };
  }

  // Validation methods
  String? validateIdeaDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please describe your idea';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    return null;
  }

  String? validateFundingGoal(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your funding goal';
    }

    final amount = int.tryParse(value.replaceAll(',', ''));
    if (amount == null) {
      return 'Please enter a valid number';
    }

    if (amount < 1000) {
      return 'Funding goal must be at least \$1,000';
    }

    if (amount > 100000000) {
      return 'Funding goal cannot exceed \$100,000,000';
    }

    return null;
  }

  String? validateFundingPhase(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a funding phase';
    }

    const validPhases = [
      'Pre-Seed',
      'Seed',
      'Series A',
      'Series B',
      'Series C',
    ];
    if (!validPhases.contains(value)) {
      return 'Please select a valid funding phase';
    }

    return null;
  }

  String? validatePitchDeck() {
    if (_pitchDeckFiles.isEmpty) {
      return 'Please upload at least one pitch deck file';
    }
    return null;
  }

  bool isProfileValid() {
    return validateIdeaDescription(_ideaDescriptionController.text) == null &&
        validateFundingGoal(_fundingGoalController.text) == null &&
        validateFundingPhase(_selectedFundingPhase) == null &&
        validatePitchDeck() == null;
  }

  Map<String, String> getValidationErrors() {
    Map<String, String> errors = {};

    final ideaError = validateIdeaDescription(_ideaDescriptionController.text);
    if (ideaError != null) errors['ideaDescription'] = ideaError;

    final fundingGoalError = validateFundingGoal(_fundingGoalController.text);
    if (fundingGoalError != null) errors['fundingGoal'] = fundingGoalError;

    final fundingPhaseError = validateFundingPhase(_selectedFundingPhase);
    if (fundingPhaseError != null) errors['fundingPhase'] = fundingPhaseError;

    final pitchDeckError = validatePitchDeck();
    if (pitchDeckError != null) errors['pitchDeck'] = pitchDeckError;

    return errors;
  }

  Map<String, dynamic> getProfileData() {
    return {
      'ideaDescription': ideaDescription,
      'profileImage': _profileImage?.path,
      'pitchDeck': getPitchDeckSubmissionInfo(),
      'fundingGoalAmount': _fundingGoalAmount,
      'selectedFundingPhase': _selectedFundingPhase,
      'isValid': isProfileValid(),
      'validationErrors': getValidationErrors(),
    };
  }

  // Clear all data
  // Replace clearAllData() method with:
  Future<void> clearAllData() async {
    _removeListeners();

    _ideaDescriptionController.clear();
    _fundingGoalController.clear();
    _profileImage = null;
    _pitchDeckFiles.clear();
    _pitchDeckThumbnails.clear();
    _isPitchDeckSubmitted = false;
    _pitchDeckSubmissionDate = null;
    _fundingGoalAmount = null;
    _selectedFundingPhase = null;
    _dirtyFields.clear();

    _addListeners();
    notifyListeners();

    try {
      // TODO: Clear data from Supabase if needed
    } catch (e) {
      _error = 'Failed to clear startup profile data: $e';
      debugPrint('Error clearing startup profile data: $e');
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel(); // Clean up auto-save timer
    _removeListeners();
    _ideaDescriptionController.dispose();
    _fundingGoalController.dispose();
    super.dispose();
  }
}

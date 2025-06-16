import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';

class StartupProfileProvider with ChangeNotifier {
  // Keys for SharedPreferences
  static const String _ideaDescriptionKey = 'startup_idea_description';
  static const String _fundingGoalKey = 'startup_funding_goal';
  static const String _profileImageKey = 'startup_profile_image';
  static const String _pitchDeckFilesKey = 'startup_pitch_deck_files';
  static const String _fundingGoalAmountKey = 'startup_funding_goal_amount';
  static const String _selectedFundingPhaseKey = 'startup_funding_phase';
  static const String _isPitchDeckSubmittedKey = 'startup_pitch_deck_submitted';
  static const String _pitchDeckSubmissionDateKey =
      'startup_pitch_deck_submission_date';

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
  Future<void> initialize() async {
    if (_isInitialized) return; // Prevent multiple initializations

    _isLoading = true;
    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove listeners temporarily
      _removeListeners();

      // Load text data and sync with controllers
      final ideaDescription = prefs.getString(_ideaDescriptionKey) ?? '';
      final fundingGoal = prefs.getString(_fundingGoalKey) ?? '';

      // Sync controllers with loaded data
      _ideaDescriptionController.text = ideaDescription;
      _fundingGoalController.text = fundingGoal;

      // Load other data
      final profileImagePath = prefs.getString(_profileImageKey);
      if (profileImagePath != null && File(profileImagePath).existsSync()) {
        _profileImage = File(profileImagePath);
      }

      // Load pitch deck files (paths only - files might not exist after app restart)
      final pitchDeckData = prefs.getString(_pitchDeckFilesKey);
      if (pitchDeckData != null) {
        try {
          final List<dynamic> filePathsList = json.decode(pitchDeckData);
          _pitchDeckFiles =
              filePathsList
                  .map((path) => File(path as String))
                  .where((file) => file.existsSync())
                  .toList();
          // Note: thumbnails will need to be regenerated
          _pitchDeckThumbnails = [];
        } catch (e) {
          debugPrint('Error loading pitch deck files: $e');
          _pitchDeckFiles = [];
          _pitchDeckThumbnails = [];
        }
      }

      // Load funding information
      _fundingGoalAmount = prefs.getInt(_fundingGoalAmountKey);
      _selectedFundingPhase = prefs.getString(_selectedFundingPhaseKey);

      // Update funding goal controller with the amount if it exists
      if (_fundingGoalAmount != null && _fundingGoalController.text.isEmpty) {
        _fundingGoalController.text = _fundingGoalAmount.toString();
      }

      _isPitchDeckSubmitted = prefs.getBool(_isPitchDeckSubmittedKey) ?? false;

      final submissionDateString = prefs.getString(_pitchDeckSubmissionDateKey);
      if (submissionDateString != null) {
        _pitchDeckSubmissionDate = DateTime.tryParse(submissionDateString);
      }

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
      final prefs = await SharedPreferences.getInstance();

      switch (fieldName) {
        case 'ideaDescription':
          await prefs.setString(
            _ideaDescriptionKey,
            _ideaDescriptionController.text,
          );
          break;
        case 'fundingGoal':
          await prefs.setString(_fundingGoalKey, _fundingGoalController.text);
          // Also try to parse and save as amount
          final amount = int.tryParse(
            _fundingGoalController.text.replaceAll(',', ''),
          );
          if (amount != null) {
            _fundingGoalAmount = amount;
            await prefs.setInt(_fundingGoalAmountKey, amount);
          }
          break;
        case 'profileImage':
          if (_profileImage != null) {
            await prefs.setString(_profileImageKey, _profileImage!.path);
          } else {
            await prefs.remove(_profileImageKey);
          }
          break;
        case 'pitchDeckFiles':
          final filePaths = _pitchDeckFiles.map((file) => file.path).toList();
          await prefs.setString(_pitchDeckFilesKey, json.encode(filePaths));
          break;
        case 'fundingGoalAmount':
          if (_fundingGoalAmount != null) {
            await prefs.setInt(_fundingGoalAmountKey, _fundingGoalAmount!);
          } else {
            await prefs.remove(_fundingGoalAmountKey);
          }
          break;
        case 'selectedFundingPhase':
          if (_selectedFundingPhase != null) {
            await prefs.setString(
              _selectedFundingPhaseKey,
              _selectedFundingPhase!,
            );
          } else {
            await prefs.remove(_selectedFundingPhaseKey);
          }
          break;
        case 'pitchDeckSubmission':
          await prefs.setBool(_isPitchDeckSubmittedKey, _isPitchDeckSubmitted);
          if (_pitchDeckSubmissionDate != null) {
            await prefs.setString(
              _pitchDeckSubmissionDateKey,
              _pitchDeckSubmissionDate!.toIso8601String(),
            );
          } else {
            await prefs.remove(_pitchDeckSubmissionDateKey);
          }
          break;
      }

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
        switch (fieldName) {
          case 'ideaDescription':
            await prefs.setString(
              _ideaDescriptionKey,
              _ideaDescriptionController.text,
            );
            break;
          case 'fundingGoal':
            await prefs.setString(_fundingGoalKey, _fundingGoalController.text);
            // Also try to parse and save as amount
            final amount = int.tryParse(
              _fundingGoalController.text.replaceAll(',', ''),
            );
            if (amount != null) {
              _fundingGoalAmount = amount;
              await prefs.setInt(_fundingGoalAmountKey, amount);
            }
            break;
          case 'profileImage':
            if (_profileImage != null) {
              await prefs.setString(_profileImageKey, _profileImage!.path);
            } else {
              await prefs.remove(_profileImageKey);
            }
            break;
          case 'pitchDeckFiles':
            final filePaths = _pitchDeckFiles.map((file) => file.path).toList();
            await prefs.setString(_pitchDeckFilesKey, json.encode(filePaths));
            break;
          case 'fundingGoalAmount':
            if (_fundingGoalAmount != null) {
              await prefs.setInt(_fundingGoalAmountKey, _fundingGoalAmount!);
            } else {
              await prefs.remove(_fundingGoalAmountKey);
            }
            break;
          case 'selectedFundingPhase':
            if (_selectedFundingPhase != null) {
              await prefs.setString(
                _selectedFundingPhaseKey,
                _selectedFundingPhase!,
              );
            } else {
              await prefs.remove(_selectedFundingPhaseKey);
            }
            break;
          case 'pitchDeckSubmission':
            await prefs.setBool(
              _isPitchDeckSubmittedKey,
              _isPitchDeckSubmitted,
            );
            if (_pitchDeckSubmissionDate != null) {
              await prefs.setString(
                _pitchDeckSubmissionDateKey,
                _pitchDeckSubmissionDate!.toIso8601String(),
              );
            } else {
              await prefs.remove(_pitchDeckSubmissionDateKey);
            }
            break;
        }
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
      // Simulate file upload/submission process
      await Future.delayed(const Duration(seconds: 2));

      // Mark as submitted
      _isPitchDeckSubmitted = true;
      _pitchDeckSubmissionDate = DateTime.now();
      _dirtyFields.add('pitchDeckSubmission');
      notifyListeners();

      // Auto-save submission status
      await saveField('pitchDeckSubmission');
    } catch (e) {
      throw Exception('Failed to submit pitch deck files: $e');
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ideaDescriptionKey);
      await prefs.remove(_fundingGoalKey);
      await prefs.remove(_profileImageKey);
      await prefs.remove(_pitchDeckFilesKey);
      await prefs.remove(_fundingGoalAmountKey);
      await prefs.remove(_selectedFundingPhaseKey);
      await prefs.remove(_isPitchDeckSubmittedKey);
      await prefs.remove(_pitchDeckSubmissionDateKey);
    } catch (e) {
      _error = 'Failed to clear startup profile data: $e';
      debugPrint('Error clearing startup profile preferences: $e');
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

// lib/Providers/startup_profile_provider.dart
import 'package:flutter/material.dart';
import 'dart:io';

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

  // Funding information
  int? _fundingGoalAmount;
  String? _selectedFundingPhase;

  // Loading and error states
  bool _isLoading = false;
  String? _error;

  // Dirty tracking for unsaved changes (kept for UI state)
  final Set<String> _dirtyFields = <String>{};

  // Initialization flag
  bool _isInitialized = false;

  StartupProfileProvider() {
    // Initialize listeners
    _addListeners();
    _isInitialized = true;
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
    _dirtyFields.add(fieldName);
    notifyListeners();
  }

  // Getters for states
  bool get isLoading => _isLoading;
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

  // Initialize method (now just sets flag since no persistence)
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Simulate loading delay for UI consistency
    await Future.delayed(const Duration(milliseconds: 100));

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  // Force re-sync data (no-op now but kept for API compatibility)
  Future<void> refreshData() async {
    await initialize();
  }

  // Mock save methods (kept for API compatibility)
  Future<bool> saveField(String fieldName) async {
    _dirtyFields.remove(fieldName);
    notifyListeners();
    return true;
  }

  Future<bool> saveAllChanges() async {
    _dirtyFields.clear();
    notifyListeners();
    return true;
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

  // Setters with immediate state update
  void setProfileImage(File? image) {
    _profileImage = image;
    _dirtyFields.add('profileImage');
    notifyListeners();
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
  }

  void setSelectedFundingPhase(String? phase) {
    _selectedFundingPhase = phase;
    _dirtyFields.add('selectedFundingPhase');
    notifyListeners();
  }

  // Pitch deck methods
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
  }

  void removePitchDeckFile(int index) {
    if (index >= 0 && index < _pitchDeckFiles.length) {
      _pitchDeckFiles.removeAt(index);
      if (index < _pitchDeckThumbnails.length) {
        _pitchDeckThumbnails.removeAt(index);
      }
      _dirtyFields.add('pitchDeckFiles');

      // Reset submission status when files change
      if (_isPitchDeckSubmitted) {
        _isPitchDeckSubmitted = false;
        _pitchDeckSubmissionDate = null;
        _dirtyFields.add('pitchDeckSubmission');
      }
      notifyListeners();
    }
  }

  void submitPitchDeck() {
    _isPitchDeckSubmitted = true;
    _pitchDeckSubmissionDate = DateTime.now();
    _dirtyFields.add('pitchDeckSubmission');
    notifyListeners();
  }

  void unsubmitPitchDeck() {
    _isPitchDeckSubmitted = false;
    _pitchDeckSubmissionDate = null;
    _dirtyFields.add('pitchDeckSubmission');
    notifyListeners();
  }

  // Validation methods
  bool isProfileValid() {
    return _ideaDescriptionController.text.isNotEmpty &&
        _fundingGoalController.text.isNotEmpty;
  }

  // Profile completion percentage
  double getProfileCompletionPercentage() {
    int completedFields = 0;
    int totalFields = 5; // idea, funding, image, pitch deck, funding phase

    if (_ideaDescriptionController.text.isNotEmpty) completedFields++;
    if (_fundingGoalController.text.isNotEmpty) completedFields++;
    if (_profileImage != null) completedFields++;
    if (_pitchDeckFiles.isNotEmpty) completedFields++;
    if (_selectedFundingPhase != null) completedFields++;

    return completedFields / totalFields;
  }

  // Get profile data as map
  Map<String, dynamic> getProfileData() {
    return {
      'ideaDescription': _ideaDescriptionController.text,
      'fundingGoal': _fundingGoalController.text,
      'fundingGoalAmount': _fundingGoalAmount,
      'selectedFundingPhase': _selectedFundingPhase,
      'hasProfileImage': _profileImage != null,
      'pitchDeckFileCount': _pitchDeckFiles.length,
      'isPitchDeckSubmitted': _isPitchDeckSubmitted,
      'pitchDeckSubmissionDate': _pitchDeckSubmissionDate?.toIso8601String(),
    };
  }

  // Clear all profile data
  Future<void> clearProfileData() async {
    _removeListeners();

    _ideaDescriptionController.clear();
    _fundingGoalController.clear();
    _profileImage = null;
    _pitchDeckFiles.clear();
    _pitchDeckThumbnails.clear();
    _fundingGoalAmount = null;
    _selectedFundingPhase = null;
    _isPitchDeckSubmitted = false;
    _pitchDeckSubmissionDate = null;
    _dirtyFields.clear();

    _addListeners();
    notifyListeners();
  }

  // Validation methods
  String? validateIdeaDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please describe your business idea';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    return null;
  }

  String? validateFundingGoal(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your funding goal';
    }

    // Remove commas and try to parse
    final cleanValue = value.replaceAll(',', '');
    final amount = int.tryParse(cleanValue);

    if (amount == null) {
      return 'Please enter a valid number';
    }

    if (amount < 1000) {
      return 'Funding goal must be at least \$1,000';
    }

    if (amount > 1000000000) {
      return 'Funding goal cannot exceed \$1 billion';
    }

    return null;
  }

  String? validateFundingPhase(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a funding phase';
    }

    final validPhases = [
      'Pre-Seed',
      'Seed',
      'Series A',
      'Series B',
      'Series C',
      'Series D+',
      'Growth/Late Stage',
      'IPO Ready',
    ];

    if (!validPhases.contains(value)) {
      return 'Please select a valid funding phase';
    }

    return null;
  }

  @override
  void dispose() {
    _removeListeners();
    _ideaDescriptionController.dispose();
    _fundingGoalController.dispose();
    super.dispose();
  }
}

// lib/Providers/startup_profile_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';

class StartupProfileProvider with ChangeNotifier {
  // Text controllers
  final TextEditingController _ideaDescriptionController =
      TextEditingController();
  final TextEditingController _fundingGoalController = TextEditingController();

  // Profile image
  File? _profileImage;
  String? _profileImageUrl; // URL from Supabase storage

  // Pitch deck files
  List<File> _pitchDeckFiles = [];
  List<Widget> _pitchDeckThumbnails = [];
  bool _isPitchDeckSubmitted = false;
  DateTime? _pitchDeckSubmissionDate;
  String? _pitchDeckId; // Reference to pitch_deck record

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

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

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

  // Initialize and load data from Supabase
  Future<void> initialize() async {
    if (_isInitialized) return; // Prevent multiple initializations

    _isLoading = true;
    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      // Remove listeners temporarily
      _removeListeners();

      // Get current user
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Load user data from Supabase
      final userResponse =
          await _supabase
              .from('users')
              .select(
                'funding_goal, funding_stage, avatar_url, idea_description, pitch_deck_id',
              )
              .eq('id', currentUser.id)
              .maybeSingle();

      if (userResponse != null) {
        // Populate controllers and variables with loaded data
        _ideaDescriptionController.text =
            userResponse['idea_description'] ?? '';
        _fundingGoalAmount = userResponse['funding_goal'];
        _selectedFundingPhase = userResponse['funding_stage'];
        _profileImageUrl = userResponse['avatar_url'];
        _pitchDeckId = userResponse['pitch_deck_id'];

        // Update funding goal controller
        _fundingGoalController.text = _fundingGoalAmount?.toString() ?? '';

        // Load pitch deck data if exists
        if (_pitchDeckId != null) {
          await _loadPitchDeckData(_pitchDeckId!);
        }
      }

      // Re-add listeners
      _addListeners();

      _dirtyFields.clear(); // Clear dirty state after loading
      _isInitialized = true;
      debugPrint('Startup profile data loaded successfully');
    } catch (e) {
      _error = 'Failed to load startup profile data: $e';
      debugPrint('Error loading startup profile data: $e');
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load pitch deck data from database
  Future<void> _loadPitchDeckData(String pitchDeckId) async {
    try {
      final pitchDeckResponse =
          await _supabase
              .from('pitch_decks')
              .select('*')
              .eq('id', pitchDeckId)
              .maybeSingle();

      if (pitchDeckResponse != null) {
        _isPitchDeckSubmitted = pitchDeckResponse['is_submitted'] ?? false;
        _pitchDeckSubmissionDate =
            pitchDeckResponse['submission_date'] != null
                ? DateTime.parse(pitchDeckResponse['submission_date'])
                : null;

        // Note: File objects can't be reconstructed from URLs,
        // so we'll only track the metadata for now
        debugPrint('Pitch deck metadata loaded');
      }
    } catch (e) {
      debugPrint('Error loading pitch deck data: $e');
    }
  }

  // Force re-sync data (useful for debugging or manual refresh)
  Future<void> refreshData() async {
    _isInitialized = false;
    await initialize();
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

      // Handle different field types
      switch (fieldName) {
        case 'ideaDescription':
          await _saveIdeaDescription(currentUser.id);
          break;
        case 'fundingGoal':
          await _saveFundingGoal(currentUser.id);
          break;
        case 'fundingGoalAmount':
          await _saveFundingGoalAmount(currentUser.id);
          break;
        case 'selectedFundingPhase':
          await _saveFundingPhase(currentUser.id);
          break;
        case 'profileImage':
          await _saveProfileImage(currentUser.id);
          break;
        case 'pitchDeckFiles':
          await _savePitchDeckFiles(currentUser.id);
          break;
        case 'pitchDeckSubmission':
          await _savePitchDeckSubmission(currentUser.id);
          break;
        default:
          debugPrint('Unknown field: $fieldName');
          return false;
      }

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

  // Save idea description
  Future<void> _saveIdeaDescription(String userId) async {
    await _supabase
        .from('users')
        .update({
          'idea_description': _ideaDescriptionController.text,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  // Save funding goal (from text controller)
  Future<void> _saveFundingGoal(String userId) async {
    final amount = int.tryParse(
      _fundingGoalController.text.replaceAll(',', ''),
    );
    _fundingGoalAmount = amount;

    await _supabase
        .from('users')
        .update({
          'funding_goal': amount,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  // Save funding goal amount (from direct setter)
  Future<void> _saveFundingGoalAmount(String userId) async {
    await _supabase
        .from('users')
        .update({
          'funding_goal': _fundingGoalAmount,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  // Save funding phase
  Future<void> _saveFundingPhase(String userId) async {
    await _supabase
        .from('users')
        .update({
          'funding_stage': _selectedFundingPhase,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  // Save profile image
  Future<void> _saveProfileImage(String userId) async {
    String? imageUrl;

    if (_profileImage != null) {
      // Upload image to Supabase storage
      final fileName = 'profile_$userId.${_profileImage!.path.split('.').last}';
      final bytes = await _profileImage!.readAsBytes();

      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: 'image/*'),
          );

      // Get public URL
      imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      _profileImageUrl = imageUrl;
    }

    await _supabase
        .from('users')
        .update({
          'avatar_url': imageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  // Save pitch deck files
  Future<void> _savePitchDeckFiles(String userId) async {
    if (_pitchDeckFiles.isEmpty) return;

    // Create or update pitch deck record
    if (_pitchDeckId == null) {
      // Create new pitch deck record
      final pitchDeckResponse =
          await _supabase
              .from('pitch_decks')
              .insert({
                'file_count': _pitchDeckFiles.length,
                'is_submitted': false,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .select('id')
              .single();

      _pitchDeckId = pitchDeckResponse['id'];

      // Update user record with pitch deck reference
      await _supabase
          .from('users')
          .update({
            'pitch_deck_id': _pitchDeckId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    }

    // Upload files to storage
    List<String> fileUrls = [];
    List<String> fileNames = [];

    for (int i = 0; i < _pitchDeckFiles.length; i++) {
      final file = _pitchDeckFiles[i];
      final fileName =
          'pitch_deck_${userId}_${i}_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
      final bytes = await file.readAsBytes();

      await _supabase.storage
          .from('pitch-decks')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType:
                  file.path.endsWith('.pdf') ? 'application/pdf' : 'video/*',
            ),
          );

      final url = _supabase.storage.from('pitch-decks').getPublicUrl(fileName);

      fileUrls.add(url);
      fileNames.add(file.path.split('/').last);
    }

    // Update pitch deck record with file info
    await _supabase
        .from('pitch_decks')
        .update({
          'file_urls': fileUrls,
          'file_names': fileNames,
          'file_count': _pitchDeckFiles.length,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', _pitchDeckId!);
  }

  // Save pitch deck submission status
  Future<void> _savePitchDeckSubmission(String userId) async {
    if (_pitchDeckId == null) return;

    await _supabase
        .from('pitch_decks')
        .update({
          'is_submitted': _isPitchDeckSubmitted,
          'submission_date': _pitchDeckSubmissionDate?.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', _pitchDeckId!);
  }

  // Save all dirty fields
  Future<bool> saveAllChanges() async {
    if (_dirtyFields.isEmpty) return true;

    final fieldsToSave = List<String>.from(_dirtyFields);
    bool allSuccess = true;

    for (String field in fieldsToSave) {
      final success = await saveField(field);
      if (!success) allSuccess = false;
    }

    return allSuccess;
  }

  // Getters for controllers
  TextEditingController get ideaDescriptionController =>
      _ideaDescriptionController;
  TextEditingController get fundingGoalController => _fundingGoalController;

  // Getters for data
  File? get profileImage => _profileImage;
  String? get profileImageUrl => _profileImageUrl;
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

      // Save to database
      await saveField('pitchDeckSubmission');

      notifyListeners();
    } catch (e) {
      // Reset on error
      _isPitchDeckSubmitted = false;
      _pitchDeckSubmissionDate = null;
      rethrow;
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
      'profileImageUrl': _profileImageUrl,
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
    _profileImageUrl = null;
    _pitchDeckFiles.clear();
    _pitchDeckThumbnails.clear();
    _isPitchDeckSubmitted = false;
    _pitchDeckSubmissionDate = null;
    _fundingGoalAmount = null;
    _selectedFundingPhase = null;
    _pitchDeckId = null;
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
              'funding_goal': null,
              'funding_stage': null,
              'avatar_url': null,
              'idea_description': null,
              'pitch_deck_id': null,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', currentUser.id);
      }
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

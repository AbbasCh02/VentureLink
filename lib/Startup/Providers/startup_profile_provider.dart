// lib/Startup/Providers/startup_profile_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';
import '../../services/storage_service.dart';

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

  void setPitchDeckFiles(List<File> files, List<Widget> thumbnails) {
    _pitchDeckFiles = files;
    _pitchDeckThumbnails = thumbnails;
    _dirtyFields.add('pitchDeckFiles');
    notifyListeners();

    // Save the files
    saveField('pitchDeckFiles');
  }

  Widget buildFileCard(BuildContext context, File file) {
    final extension = file.path.split('.').last.toLowerCase();
    final fileName = file.path.split('/').last;

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFffa500).withValues(alpha: 0.3),
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(child: _getFileIcon(extension)),
                ),
                const SizedBox(height: 8),
                Text(
                  fileName.length > 12
                      ? '${fileName.substring(0, 12)}...'
                      : fileName,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                final index = _pitchDeckFiles.indexOf(file);
                if (index != -1) removePitchDeckFile(index);
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red[600],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Icon _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30);
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
      case 'wmv':
        return const Icon(Icons.play_circle_fill, color: Colors.blue, size: 30);
      default:
        return const Icon(
          Icons.insert_drive_file,
          color: Colors.grey,
          size: 30,
        );
    }
  }

  // Reset provider state on logout
  void _resetProviderState() {
    _isInitialized = false;
    _removeListeners();

    _ideaDescriptionController.clear();
    _fundingGoalController.clear();
    _profileImage = null;
    _profileImageUrl = null;
    _pitchDeckFiles.clear();
    _pitchDeckThumbnails.clear();
    _isPitchDeckSubmitted = false;
    _pitchDeckSubmissionDate = null;
    _pitchDeckId = null;
    _fundingGoalAmount = null;
    _selectedFundingPhase = null;
    _dirtyFields.clear();
    _error = null;

    notifyListeners();
    _addListeners();
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
    _pitchDeckId = null;
    _fundingGoalAmount = null;
    _selectedFundingPhase = null;
    _dirtyFields.clear();
    _error = null;
    _isInitialized = false;

    notifyListeners();
    _addListeners();
  }

  // Reset for new user
  Future<void> resetForNewUser() async {
    clearAllData();
    await initialize();
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
    if (_isInitializing) return;

    _dirtyFields.add(fieldName);
    notifyListeners();

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () {
      if (_dirtyFields.contains(fieldName)) {
        saveField(fieldName);
      }
    });
  }

  // Getters
  String? get ideaDescription =>
      _ideaDescriptionController.text.isEmpty
          ? null
          : _ideaDescriptionController.text;
  int? get fundingGoalAmount => _fundingGoalAmount;
  String? get selectedFundingPhase => _selectedFundingPhase;
  File? get profileImage => _profileImage;
  String? get profileImageUrl => _profileImageUrl;
  List<File> get pitchDeckFiles => List.unmodifiable(_pitchDeckFiles);
  bool get isPitchDeckSubmitted => _isPitchDeckSubmitted;
  DateTime? get pitchDeckSubmissionDate => _pitchDeckSubmissionDate;
  List<Widget> get pitchDeckThumbnails =>
      List.unmodifiable(_pitchDeckThumbnails);

  // Controllers getters
  TextEditingController get ideaDescriptionController =>
      _ideaDescriptionController;
  TextEditingController get fundingGoalController => _fundingGoalController;

  // State getters
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
      debugPrint('✅ Startup profile initialized successfully');
    } catch (e) {
      _error = 'Failed to initialize startup profile: $e';
      debugPrint('❌ Error initializing startup profile: $e');
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

      // Load user data from Supabase - CRITICAL: Filter by current user ID
      final userResponse =
          await _supabase
              .from('users')
              .select(
                'funding_goal, funding_stage, avatar_url, idea_description',
              )
              .eq('id', currentUser.id) // THIS IS THE KEY FIX
              .maybeSingle();

      if (userResponse != null) {
        // Load idea description
        _ideaDescriptionController.text =
            userResponse['idea_description'] ?? '';

        // Load funding goal
        _fundingGoalAmount = userResponse['funding_goal'];
        _fundingGoalController.text = _fundingGoalAmount?.toString() ?? '';

        // Load funding phase
        _selectedFundingPhase = userResponse['funding_stage'];

        // Load profile image URL
        _profileImageUrl = userResponse['avatar_url'];

        // If there's a pitch deck ID, load pitch deck data
        await _loadPitchDeckData(_pitchDeckId!);

        debugPrint(
          '✅ Startup profile data loaded successfully for user: ${currentUser.id}',
        );
        debugPrint(
          '   - Idea: ${_ideaDescriptionController.text.isNotEmpty ? "✓" : "✗"}',
        );
        debugPrint('   - Funding Goal: ${_fundingGoalAmount ?? "Not Set"}');
        debugPrint('   - Funding Phase: ${_selectedFundingPhase ?? "Not Set"}');
        debugPrint(
          '   - Profile Image: ${_profileImageUrl != null ? "✓" : "✗"}',
        );
        debugPrint('   - Pitch Deck: ${_pitchDeckId != null ? "✓" : "✗"}');
      } else {
        debugPrint('No startup profile data found for user: ${currentUser.id}');
      }

      // Re-add listeners
      _addListeners();
      _dirtyFields.clear(); // Clear dirty state after loading
    } catch (e) {
      _error = 'Failed to load startup profile data: $e';
      debugPrint('❌ Error loading startup profile data: $e');

      // Re-add listeners even on error
      _addListeners();
      rethrow;
    }
  }

  // Load pitch deck data from database
  Future<void> _loadPitchDeckData(String pitchDeckId) async {
    try {
      debugPrint('🔄 Loading pitch deck data for ID: $pitchDeckId');

      // CRITICAL: Filter by pitch deck ID AND ensure it belongs to current user
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      final pitchDeckResponse =
          await _supabase
              .from('pitch_decks')
              .select('*')
              .eq('id', pitchDeckId) // THIS IS THE KEY FIX
              .maybeSingle();

      if (pitchDeckResponse != null) {
        _isPitchDeckSubmitted = pitchDeckResponse['is_submitted'] ?? false;
        _pitchDeckSubmissionDate =
            pitchDeckResponse['submission_date'] != null
                ? DateTime.parse(pitchDeckResponse['submission_date'])
                : null;

        // Load stored files and recreate thumbnails
        final List<dynamic>? fileUrls = pitchDeckResponse['file_urls'];
        final List<dynamic>? originalNames = pitchDeckResponse['file_names'];

        if (fileUrls != null && originalNames != null) {
          // Clear existing thumbnails
          _pitchDeckThumbnails.clear();

          // Recreate thumbnails for stored files
          for (int i = 0; i < fileUrls.length; i++) {
            if (i < originalNames.length) {
              final thumbnail = _createStoredFileThumbnail(
                fileUrls[i],
                originalNames[i],
                i,
              );
              _pitchDeckThumbnails.add(thumbnail);
            }
          }

          debugPrint(
            '✅ Created ${_pitchDeckThumbnails.length} thumbnails for stored files',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading pitch deck data: $e');
    }
  }

  // Create thumbnail widget for stored files
  Widget _createStoredFileThumbnail(String url, String displayName, int index) {
    final isVideo =
        url.toLowerCase().contains('.mp4') ||
        url.toLowerCase().contains('.avi') ||
        url.toLowerCase().contains('.mov');

    return Container(
      margin: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: Icon(
              isVideo ? Icons.play_circle_fill : Icons.picture_as_pdf,
              color: Colors.orange,
              size: 40,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayName.length > 10
                ? '${displayName.substring(0, 10)}...'
                : displayName,
            style: const TextStyle(fontSize: 10, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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

  // Save idea description
  Future<void> _saveIdeaDescription(String userId) async {
    await _supabase
        .from('users')
        .update({
          'idea_description': _ideaDescriptionController.text,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId); // CRITICAL: Filter by user ID
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
        .eq('id', userId); // CRITICAL: Filter by user ID
  }

  // Save funding goal amount (from direct setter)
  Future<void> _saveFundingGoalAmount(String userId) async {
    await _supabase
        .from('users')
        .update({
          'funding_goal': _fundingGoalAmount,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId); // CRITICAL: Filter by user ID
  }

  // Save funding phase
  Future<void> _saveFundingPhase(String userId) async {
    await _supabase
        .from('users')
        .update({
          'funding_stage': _selectedFundingPhase,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId); // CRITICAL: Filter by user ID
  }

  // Save profile image using StorageService
  Future<void> _saveProfileImage(String userId) async {
    String? newImageUrl;

    if (_profileImage != null) {
      try {
        // Upload new image to Supabase storage
        newImageUrl = await StorageService.uploadAvatar(
          file: _profileImage!,
          userId: userId,
        );
        _profileImageUrl = newImageUrl;
      } catch (e) {
        debugPrint('Error uploading profile image: $e');
        rethrow;
      }
    }

    // Update user record with new avatar URL
    await _supabase
        .from('users')
        .update({
          'avatar_url': _profileImageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId); // CRITICAL: Filter by user ID
  }

  // Save pitch deck files and submission status
  Future<void> _savePitchDeckFiles(String userId) async {
    if (_pitchDeckFiles.isEmpty) return;

    try {
      // Upload files using StorageService
      final uploadResult = await StorageService.uploadPitchDeckFiles(
        files: _pitchDeckFiles,
        userId: userId,
        pitchDeckId: _pitchDeckId,
      );

      // Create or update pitch deck record
      if (_pitchDeckId == null) {
        // Create new pitch deck record
        final response =
            await _supabase
                .from('pitch_decks')
                .insert({
                  'file_urls': uploadResult['file_urls'],
                  'file_names': uploadResult['file_names'],
                  'file_count': uploadResult['file_count'],
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .select()
                .single();

        _pitchDeckId = response['id'];

        // Update user record with pitch deck reference
        await _supabase
            .from('users')
            .update({
              'pitch_deck_id': _pitchDeckId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId); // CRITICAL: Filter by user ID
      }

      // Clear uploaded files since they're now stored
      _pitchDeckFiles.clear();
    } catch (e) {
      debugPrint('Error saving pitch deck files: $e');
      rethrow;
    }
  }

  // Save pitch deck submission status
  Future<void> _savePitchDeckSubmission(String userId) async {
    if (_pitchDeckId == null) return;

    await _supabase
        .from('pitch_decks')
        .update({
          'is_submitted': _isPitchDeckSubmitted,
          'submission_date':
              _isPitchDeckSubmitted ? DateTime.now().toIso8601String() : null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', _pitchDeckId!); // Filter by pitch deck ID
  }

  // Public methods for updating data
  void updateIdeaDescription(String value) {
    _ideaDescriptionController.text = value;
    _onFieldChanged('ideaDescription');
  }

  void updateFundingGoalAmount(int? amount) {
    _fundingGoalAmount = amount;
    _fundingGoalController.text = amount?.toString() ?? '';
    _dirtyFields.add('fundingGoalAmount');
    notifyListeners();

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () {
      saveField('fundingGoalAmount');
    });
  }

  void updateSelectedFundingPhase(String? phase) {
    _selectedFundingPhase = phase;
    _dirtyFields.add('selectedFundingPhase');
    notifyListeners();

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () {
      saveField('selectedFundingPhase');
    });
  }

  void updateProfileImage(File? image) {
    _profileImage = image;
    _dirtyFields.add('profileImage');
    notifyListeners();

    // Save immediately for profile image
    saveField('profileImage');
  }

  // Validation methods
  String? validateIdeaDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please describe your startup idea';
    }
    if (value.trim().length < 10) {
      return 'Please provide a more detailed description (at least 10 characters)';
    }
    return null;
  }

  String? validateFundingGoal(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your funding goal';
    }

    final amount = int.tryParse(value.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      return 'Please enter a valid funding amount';
    }

    if (amount < 1000) {
      return 'Funding goal should be at least \$1,000';
    }

    return null;
  }

  String? validateFundingPhase(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a funding phase';
    }

    const validPhases = [
      'idea',
      'Pre-Seed',
      'Seed',
      'MVP',
      'Product-Market Fit',
      'Early Growth',
      'Series A',
      'Series B',
      'Series C',
      'Series D+',
      'Scaling',
      'Late Stage',
      'Revenue-Generating',
      'IPO Ready',
    ];
    if (!validPhases.contains(value)) {
      return 'Please select a valid funding phase';
    }

    return null;
  }

  bool get hasPitchDeckFiles {
    return _pitchDeckFiles.isNotEmpty || _pitchDeckThumbnails.isNotEmpty;
  }

  int get totalPitchDeckFilesCount {
    return _pitchDeckFiles.length + _pitchDeckThumbnails.length;
  }

  bool get hasStoredPitchDeckFiles {
    return _pitchDeckId != null && _pitchDeckThumbnails.isNotEmpty;
  }

  bool get hasProfileImage {
    return _profileImage != null ||
        (_profileImageUrl != null && _profileImageUrl!.isNotEmpty);
  }

  // Profile completion status
  bool get isProfileComplete {
    return ideaDescription != null &&
        _fundingGoalAmount != null &&
        _selectedFundingPhase != null;
  }

  double get completionPercentage {
    int completedFields = 0;
    if (ideaDescription != null) completedFields++;
    if (_fundingGoalAmount != null) completedFields++;
    if (_selectedFundingPhase != null) completedFields++;
    if (_profileImageUrl != null) completedFields++;
    return (completedFields / 4) * 100;
  }

  // Pitch deck methods
  void addPitchDeckFiles(List<File> files) {
    _pitchDeckFiles.addAll(files);
    _dirtyFields.add('pitchDeckFiles');
    notifyListeners();
    saveField('pitchDeckFiles');
  }

  Future<void> removePitchDeckFile(int index) async {
    if (index < _pitchDeckFiles.length) {
      _pitchDeckFiles.removeAt(index);
      _dirtyFields.add('pitchDeckFiles');
      notifyListeners();
    }
  }

  Future<void> submitPitchDeck() async {
    _isPitchDeckSubmitted = true;
    _pitchDeckSubmissionDate = DateTime.now();
    _dirtyFields.add('pitchDeckSubmission');
    notifyListeners();
    saveField('pitchDeckSubmission');
  }

  Map<String, dynamic> getProfileData() {
    return {
      'ideaDescription': ideaDescription,
      'fundingGoalAmount': fundingGoalAmount,
      'selectedFundingPhase': selectedFundingPhase,
      'profileImageUrl': profileImageUrl,
      'hasPitchDeckFiles': hasPitchDeckFiles,
      'isPitchDeckSubmitted': isPitchDeckSubmitted,
      'completionPercentage': completionPercentage,
    };
  }

  List<String> getValidationErrors() {
    List<String> errors = [];

    final ideaError = validateIdeaDescription(ideaDescription);
    if (ideaError != null) errors.add('Idea Description: $ideaError');

    final fundingError = validateFundingGoal(fundingGoalAmount?.toString());
    if (fundingError != null) errors.add('Funding Goal: $fundingError');

    final phaseError = validateFundingPhase(selectedFundingPhase);
    if (phaseError != null) errors.add('Funding Phase: $phaseError');

    return errors;
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _removeListeners();
    _ideaDescriptionController.dispose();
    _fundingGoalController.dispose();
    super.dispose();
  }
}

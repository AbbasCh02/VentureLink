// lib/Startup/Providers/startup_profile_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';
import '../services/storage_service.dart'; // Import our storage service

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
    initialize();
  }

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

  // Add controllers getters
  TextEditingController get ideaDescriptionController =>
      _ideaDescriptionController;
  TextEditingController get fundingGoalController => _fundingGoalController;

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

  // Enhanced getters for UI
  int get totalPitchDeckFilesCount {
    // Count both new uploads and stored files
    return _pitchDeckFiles.length + _getStoredFilesCount();
  }

  int _getStoredFilesCount() {
    // Count thumbnails that represent stored files (not new uploads)
    // This assumes thumbnails beyond the file count are stored files
    return _pitchDeckThumbnails.length > _pitchDeckFiles.length
        ? _pitchDeckThumbnails.length - _pitchDeckFiles.length
        : 0;
  }

  bool get hasPitchDeckFiles {
    return totalPitchDeckFilesCount > 0 || _pitchDeckThumbnails.isNotEmpty;
  }

  bool get hasStoredPitchDeckFiles {
    return _pitchDeckId != null && _getStoredFilesCount() > 0;
  }

  // Better profile image handling
  bool get hasProfileImage {
    return _profileImage != null ||
        (_profileImageUrl != null && _profileImageUrl!.isNotEmpty);
  }

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

      // Load user data from Supabase with ALL required fields
      final userResponse =
          await _supabase
              .from('users')
              .select(
                'funding_goal, funding_stage, avatar_url, idea_description, pitch_deck_id',
              )
              .eq('id', currentUser.id)
              .maybeSingle();

      if (userResponse != null) {
        // Load idea description
        _ideaDescriptionController.text =
            userResponse['idea_description'] ?? '';

        // Load funding goal
        _fundingGoalAmount = userResponse['funding_goal'];
        _fundingGoalController.text = _fundingGoalAmount?.toString() ?? '';

        // Load funding phase (this was missing proper loading!)
        _selectedFundingPhase = userResponse['funding_stage'];

        // Load profile image URL
        _profileImageUrl = userResponse['avatar_url'];

        // Load pitch deck ID
        _pitchDeckId = userResponse['pitch_deck_id'];

        // If there's a pitch deck ID, load pitch deck data
        if (_pitchDeckId != null) {
          await _loadPitchDeckData(_pitchDeckId!);
        }

        debugPrint('✅ Startup profile data loaded successfully');
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
        debugPrint('No startup profile data found for user');
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

        // CRITICAL FIX: Load stored files and recreate thumbnails
        final List<dynamic>? fileUrls = pitchDeckResponse['file_urls'];
        final List<dynamic>? originalNames =
            pitchDeckResponse['original_names'];
        final List<dynamic>? fileNames = pitchDeckResponse['file_names'];

        if (fileUrls != null && fileUrls.isNotEmpty) {
          debugPrint('📁 Found ${fileUrls.length} stored pitch deck files');

          // Clear existing thumbnails to avoid duplicates
          _pitchDeckThumbnails.clear();

          // Create thumbnails for each stored file
          for (int i = 0; i < fileUrls.length; i++) {
            final String url = fileUrls[i].toString();
            final String displayName =
                originalNames != null && i < originalNames.length
                    ? originalNames[i].toString()
                    : (fileNames != null && i < fileNames.length
                        ? fileNames[i].toString()
                        : 'File ${i + 1}');

            // Create a thumbnail widget for this stored file
            final thumbnail = _buildStoredFileCard(url, displayName, i);
            _pitchDeckThumbnails.add(thumbnail);
          }

          debugPrint(
            '✅ Created ${_pitchDeckThumbnails.length} thumbnails for stored files',
          );
        } else {
          debugPrint('📂 No stored files found for pitch deck');
        }

        debugPrint('✅ Pitch deck data loaded successfully');
        debugPrint('   - Submitted: $_isPitchDeckSubmitted');
        debugPrint('   - Files loaded: ${fileUrls?.length ?? 0}');
        debugPrint('   - Thumbnails created: ${_pitchDeckThumbnails.length}');
      } else {
        debugPrint('❌ No pitch deck data found for ID: $pitchDeckId');
      }
    } catch (e) {
      debugPrint('❌ Error loading pitch deck data: $e');
      // Don't rethrow to avoid breaking app initialization
    }
  }

  // Build thumbnail card for stored files (from database)
  Widget _buildStoredFileCard(String fileUrl, String fileName, int index) {
    final extension = fileName.split('.').last.toLowerCase();

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
                // File icon based on type
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

                // File name
                Text(
                  fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                // "Stored" indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'STORED',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // File type badge
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFffa500),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                extension.toUpperCase(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Submitted indicator
          if (_isPitchDeckSubmitted)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 10),
              ),
            ),
        ],
      ),
    );
  }

  // Add method to refresh pitch deck data
  Future<void> refreshPitchDeckDisplay() async {
    if (_pitchDeckId != null) {
      await _loadPitchDeckData(_pitchDeckId!);
      notifyListeners();
    }
  }

  Widget _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icon(Icons.picture_as_pdf, size: 30, color: Colors.red[400]);
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
      case 'wmv':
        return Icon(Icons.video_file, size: 30, color: Colors.blue[400]);
      default:
        return Icon(Icons.file_present, size: 30, color: Colors.grey[400]);
    }
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
      debugPrint('✅ Successfully saved $fieldName to Supabase');
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

  // Enhanced profile image upload using StorageService
  Future<void> _saveProfileImage(String userId) async {
    String? imageUrl;

    if (_profileImage != null) {
      try {
        // Upload using our enhanced storage service
        imageUrl = await StorageService.uploadAvatar(
          file: _profileImage!,
          userId: userId,
        );

        _profileImageUrl = imageUrl;
        debugPrint('✅ Profile image uploaded successfully');
      } catch (e) {
        debugPrint('❌ Error uploading profile image: $e');
        throw Exception('Failed to upload profile image: $e');
      }
    }

    // Update user record with new avatar URL
    await _supabase
        .from('users')
        .update({
          'avatar_url': imageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  // Enhanced pitch deck files upload using StorageService
  Future<void> _savePitchDeckFiles(String userId) async {
    if (_pitchDeckFiles.isEmpty) return;

    try {
      // Create or update pitch deck record
      if (_pitchDeckId == null) {
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

      // Upload files using our enhanced storage service
      final uploadResult = await StorageService.uploadPitchDeckFiles(
        files: _pitchDeckFiles,
        userId: userId,
        pitchDeckId: _pitchDeckId,
      );

      // Update pitch deck record with file info
      await _supabase
          .from('pitch_decks')
          .update({
            'file_urls': uploadResult['file_urls'],
            'file_names': uploadResult['file_names'],
            'file_count': uploadResult['file_count'],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _pitchDeckId!);

      debugPrint('✅ Pitch deck files uploaded successfully');
    } catch (e) {
      debugPrint('❌ Error uploading pitch deck files: $e');
      throw Exception('Failed to upload pitch deck files: $e');
    }
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

  // Enhanced setters with better error handling
  void setProfileImage(File? image) {
    _profileImage = image;
    _dirtyFields.add('profileImage');
    notifyListeners();

    // Auto-save profile image immediately
    if (image != null) {
      saveField('profileImage');
    }
  }

  void setPitchDeckFiles(List<File> files, List<Widget> thumbnails) {
    _pitchDeckFiles = files;
    _pitchDeckThumbnails = thumbnails;
    _dirtyFields.add('pitchDeckFiles');
    notifyListeners();

    // Save immediately for file operations
    saveField('pitchDeckFiles').catchError((error) {
      _error = 'Failed to upload pitch deck files: $error';
      notifyListeners();
      return false; // Add this return statement
    });
  }

  void setFundingGoalAmount(int? amount) {
    if (_fundingGoalAmount != amount) {
      _fundingGoalAmount = amount;
      _dirtyFields.add('fundingGoalAmount');

      final currentText = _fundingGoalController.text;
      final newText = amount?.toString() ?? '';
      if (currentText != newText) {
        _fundingGoalController.text = newText;
      }

      notifyListeners();

      // Auto-save after 2 seconds
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(seconds: 2), () {
        if (_dirtyFields.contains('fundingGoalAmount')) {
          saveField('fundingGoalAmount');
        }
      });
    }
  }

  void setSelectedFundingPhase(String? phase) {
    if (_selectedFundingPhase != phase) {
      _selectedFundingPhase = phase;
      _dirtyFields.add('selectedFundingPhase');
      notifyListeners();

      // Auto-save after 2 seconds
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(seconds: 2), () {
        if (_dirtyFields.contains('selectedFundingPhase')) {
          saveField('selectedFundingPhase');
        }
      });
    }
  }

  // Submit pitch deck files (MANUAL SUBMISSION ONLY)
  Future<void> submitPitchDeckFiles() async {
    if (_pitchDeckFiles.isEmpty) {
      throw Exception('No pitch deck files to submit');
    }

    if (_isPitchDeckSubmitted) {
      throw Exception('Pitch deck has already been submitted');
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      _isPitchDeckSubmitted = true;
      _pitchDeckSubmissionDate = DateTime.now();
      _dirtyFields.add('pitchDeckSubmission');

      await saveField('pitchDeckSubmission');
      debugPrint('✅ Pitch deck submitted successfully');
    } catch (e) {
      // Revert submission state on error
      _isPitchDeckSubmitted = false;
      _pitchDeckSubmissionDate = null;
      _error = 'Failed to submit pitch deck: $e';
      debugPrint('❌ Error submitting pitch deck: $e');
      throw Exception('Failed to submit pitch deck: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Add this method to your StartupProfileProvider class

  /// Delete individual pitch deck file from storage, database, and UI
  Future<void> deleteIndividualPitchDeckFile(File fileToDelete) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Find the index of the file to delete
      final fileIndex = _pitchDeckFiles.indexWhere(
        (file) => file.path == fileToDelete.path,
      );

      if (fileIndex == -1) {
        throw Exception('File not found in local list');
      }

      String? fileUrlToDelete;
      String? fileNameToDelete;

      // If we have a pitch deck ID, get the file URL from database
      if (_pitchDeckId != null) {
        try {
          final pitchDeckResponse =
              await _supabase
                  .from('pitch_decks')
                  .select('file_urls, file_names')
                  .eq('id', _pitchDeckId!)
                  .maybeSingle();

          if (pitchDeckResponse != null) {
            final fileUrls = List<String>.from(
              pitchDeckResponse['file_urls'] ?? [],
            );
            final fileNames = List<String>.from(
              pitchDeckResponse['file_names'] ?? [],
            );

            // Find the corresponding URL for this file index
            if (fileIndex < fileUrls.length) {
              fileUrlToDelete = fileUrls[fileIndex];

              // Extract file name from URL for storage deletion
              fileNameToDelete = StorageService.extractFileNameFromUrl(
                fileUrlToDelete,
              );

              // Remove from the arrays
              fileUrls.removeAt(fileIndex);
              fileNames.removeAt(fileIndex);

              // Update database with new arrays
              await _supabase
                  .from('pitch_decks')
                  .update({
                    'file_urls': fileUrls,
                    'file_names': fileNames,
                    'file_count': fileUrls.length,
                    'updated_at': DateTime.now().toIso8601String(),
                  })
                  .eq('id', _pitchDeckId!);

              debugPrint('✅ Updated pitch deck record in database');
            }
          }
        } catch (e) {
          debugPrint('Warning: Could not update database record: $e');
        }
      }

      // Delete file from Supabase storage
      if (fileNameToDelete != null) {
        try {
          await StorageService.deletePitchDeckFiles(
            fileNames: [fileNameToDelete],
          );
          debugPrint('✅ Deleted file from storage: $fileNameToDelete');
        } catch (e) {
          debugPrint('Warning: Could not delete file from storage: $e');
          // Continue with local cleanup even if storage deletion fails
        }
      }

      // Remove from local arrays
      _pitchDeckFiles.removeAt(fileIndex);
      if (fileIndex < _pitchDeckThumbnails.length) {
        _pitchDeckThumbnails.removeAt(fileIndex);
      }

      // If no files left, clean up completely
      if (_pitchDeckFiles.isEmpty) {
        await _cleanupEmptyPitchDeck(currentUser.id);
      }

      debugPrint('✅ Individual file deleted successfully');
    } catch (e) {
      _error = 'Failed to delete file: $e';
      debugPrint('❌ Error deleting individual file: $e');
      throw Exception('Failed to delete file: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Clean up when no files are left
  Future<void> _cleanupEmptyPitchDeck(String userId) async {
    try {
      // Delete pitch deck record if it exists
      if (_pitchDeckId != null) {
        await _supabase.from('pitch_decks').delete().eq('id', _pitchDeckId!);

        debugPrint('✅ Deleted empty pitch deck record');
      }

      // Update user record to remove pitch deck reference
      await _supabase
          .from('users')
          .update({
            'pitch_deck_id': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Reset local state
      _isPitchDeckSubmitted = false;
      _pitchDeckSubmissionDate = null;
      _pitchDeckId = null;
      _dirtyFields.remove('pitchDeckFiles');
      _dirtyFields.remove('pitchDeckSubmission');

      debugPrint('✅ Cleaned up empty pitch deck state');
    } catch (e) {
      debugPrint('Warning: Error during cleanup: $e');
    }
  }

  // Get pitch deck submission info
  Map<String, dynamic> getPitchDeckSubmissionInfo() {
    return {
      'filesCount': _pitchDeckFiles.length,
      'isSubmitted': _isPitchDeckSubmitted,
      'submissionDate': _pitchDeckSubmissionDate?.toIso8601String(),
      'hasFiles': _pitchDeckFiles.isNotEmpty,
    };
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
              'idea_description': null,
              'funding_goal': null,
              'funding_stage': null,
              'avatar_url': null,
              'pitch_deck_id': null,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', currentUser.id);

        // Delete storage files if they exist
        if (_profileImageUrl != null) {
          try {
            final fileName = StorageService.extractFileNameFromUrl(
              _profileImageUrl!,
            );
            await StorageService.deleteAvatar(fileName: fileName);
          } catch (e) {
            debugPrint('Warning: Could not delete avatar file: $e');
          }
        }
      }

      debugPrint('✅ All startup profile data cleared successfully');
    } catch (e) {
      _error = 'Failed to clear all data: $e';
      debugPrint('❌ Error clearing startup profile data: $e');
    }
  }

  // Refresh data from database
  Future<void> refreshFromDatabase() async {
    _isInitialized = false;
    await initialize();
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

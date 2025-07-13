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

  String? _currentUserId;
  StreamSubscription<AuthState>? _authSubscription;

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  StartupProfileProvider() {
    // Initialize automatically when provider is created and user is authenticated
    _setupAuthListener();
    _initializeWhenReady();
  }

  void _setupAuthListener() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final User? user = data.session?.user;

      if (event == AuthChangeEvent.signedIn && user != null) {
        // User signed in - check if it's a different user
        if (_currentUserId != null && _currentUserId != user.id) {
          debugPrint(
            '🔄 Different startup user detected, resetting provider state',
          );
          _resetProviderState();
        }
        _currentUserId = user.id;

        // Initialize for new user if not already initialized
        if (!_isInitialized) {
          initialize();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('🔄 Startup user signed out, resetting provider state');
        _resetProviderState();
      }
    });
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
    notifyListeners();
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
    _currentUserId = null;
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
    _saveTimer?.cancel();

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
      _resetProviderState();
      return;
    }

    // 🔥 CRITICAL: Check if we need to reset for different user
    if (_currentUserId != null && _currentUserId != currentUser.id) {
      debugPrint('🔄 User changed during initialization, resetting state');
      _resetProviderState();
    }

    _currentUserId = currentUser.id;

    if (_isInitialized) {
      debugPrint('✅ Provider already initialized for user: ${currentUser.id}');
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
      debugPrint('✅ Startup profile initialized for user: ${currentUser.id}');
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
      _removeListeners();

      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('No authenticated user found');
        return;
      }

      // 🔥 ADDITIONAL SAFETY: Verify user consistency
      if (_currentUserId != null && _currentUserId != currentUser.id) {
        debugPrint('⚠️ User mismatch detected in _loadProfileData, resetting');
        _resetProviderState();
        _currentUserId = currentUser.id;
      }

      // Load user data from Supabase - CRITICAL: Filter by current user ID
      final userResponse =
          await _supabase
              .from('startup_profiles')
              .select(
                'idea_description, funding_goal, funding_stage, avatar_url',
              )
              .eq('startup_id', currentUser.id)
              .maybeSingle();

      if (userResponse != null) {
        _ideaDescriptionController.text =
            userResponse['idea_description'] ?? '';
        _fundingGoalAmount = userResponse['funding_goal'];
        if (_fundingGoalAmount != null) {
          _fundingGoalController.text = _fundingGoalAmount.toString();
        } else {
          _fundingGoalController.clear();
        }
        _selectedFundingPhase = userResponse['funding_stage'];
        _profileImageUrl = userResponse['avatar_url'];

        debugPrint('✅ Startup profile data loaded for user: ${currentUser.id}');
      } else {
        debugPrint('No startup profile data found for user: ${currentUser.id}');
      }

      await _loadPitchDeckData(currentUser.id);

      _addListeners();
      _dirtyFields.clear();
    } catch (e) {
      _error = 'Failed to load startup profile data: $e';
      debugPrint('❌ Error loading startup profile data: $e');
      _addListeners();
      rethrow;
    }
  }

  Future<void> _loadPitchDeckData(String userId) async {
    try {
      debugPrint('🔄 Loading pitch deck data for user: $userId');

      // Query pitch_decks table for user's pitch deck
      final pitchDeckResponse =
          await _supabase
              .from('pitch_decks')
              .select('*')
              .eq('user_id', userId)
              .maybeSingle();

      if (pitchDeckResponse != null) {
        // Extract pitch deck information
        _pitchDeckId = pitchDeckResponse['id'];
        _isPitchDeckSubmitted = pitchDeckResponse['is_submitted'] ?? false;

        // Parse submission date if it exists
        if (pitchDeckResponse['submission_date'] != null) {
          _pitchDeckSubmissionDate = DateTime.parse(
            pitchDeckResponse['submission_date'],
          );
        }

        // Get file information
        final List<String>? fileUrls =
            pitchDeckResponse['file_urls']?.cast<String>();
        final List<String>? fileNames =
            pitchDeckResponse['file_names']?.cast<String>();
        final int fileCount = pitchDeckResponse['file_count'] ?? 0;

        if (fileUrls != null && fileUrls.isNotEmpty) {
          debugPrint('✅ Found ${fileUrls.length} pitch deck files');

          // Generate thumbnails for stored files
          await _generateThumbnailsForStoredFiles(fileUrls, fileNames);

          debugPrint('✅ Generated thumbnails for stored pitch deck files');
          debugPrint('   - File Count: $fileCount');
          debugPrint('   - Submitted: $_isPitchDeckSubmitted');
          debugPrint('   - Submission Date: $_pitchDeckSubmissionDate');
        } else {
          debugPrint('ℹ️ No pitch deck files found');
        }
      } else {
        debugPrint('ℹ️ No pitch deck record found for user');
      }
    } catch (e) {
      debugPrint('❌ Error loading pitch deck data: $e');
      // Don't rethrow - pitch deck data is not critical for app initialization
    }
  }

  Future<void> _generateThumbnailsForStoredFiles(
    List<String> fileUrls,
    List<String>? fileNames,
  ) async {
    try {
      List<Widget> thumbnails = [];

      for (int i = 0; i < fileUrls.length; i++) {
        final fileUrl = fileUrls[i];
        final fileName =
            fileNames != null && i < fileNames.length
                ? fileNames[i]
                : 'File ${i + 1}';

        // Extract file extension from URL or filename
        String extension = '';
        if (fileName.contains('.')) {
          extension = fileName.split('.').last.toLowerCase();
        } else if (fileUrl.contains('.')) {
          extension = fileUrl.split('.').last.toLowerCase().split('?').first;
        }

        // Generate thumbnail widget for stored file
        final thumbnail = _buildStoredFileCard(fileUrl, fileName, extension);
        thumbnails.add(thumbnail);
      }

      // Update thumbnails (but keep _pitchDeckFiles empty since these are stored files)
      _pitchDeckThumbnails = thumbnails;

      debugPrint(
        '✅ Generated ${thumbnails.length} thumbnails for stored files',
      );
    } catch (e) {
      debugPrint('❌ Error generating thumbnails for stored files: $e');
    }
  }

  Widget _buildStoredFileCard(
    String fileUrl,
    String fileName,
    String extension,
  ) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withValues(
            alpha: 0.4,
          ), // Green border for stored files
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail area
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
              _getDisplayFileName(fileName),
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Stored indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'STORED',
                style: TextStyle(
                  color: Colors.green[400],
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayFileName(String fileName) {
    // Remove user ID and timestamp from filename for display
    if (fileName.contains('_')) {
      final parts = fileName.split('_');
      if (parts.length >= 3) {
        // Remove user ID and pitch deck ID, keep meaningful part
        final meaningfulPart = parts.skip(2).join('_');
        // Remove timestamp if present
        if (meaningfulPart.contains('.')) {
          final nameParts = meaningfulPart.split('.');
          if (nameParts.length >= 2) {
            final nameWithoutTimestamp = nameParts.first;
            final extension = nameParts.last;
            return '$nameWithoutTimestamp.$extension';
          }
        }
        return meaningfulPart;
      }
    }

    // If filename format is unexpected, just truncate if too long
    if (fileName.length > 15) {
      return '${fileName.substring(0, 12)}...';
    }
    return fileName;
  }

  // Method to get startup profile data
  Future<Map<String, dynamic>?> getStartupProfile() async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return null;

    try {
      return await _supabase
          .from('startup_profiles')
          .select('*')
          .eq('startup_id', currentUser.id)
          .maybeSingle();
    } catch (e) {
      debugPrint('❌ Error getting startup profile: $e');
      return null;
    }
  }

  // Save specific field to Supabase
  Future<bool> saveField(String fieldName) async {
    if (_isInitializing) return true;

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
          // ✅ DON'T auto-upload files - just return success
          // Files will be uploaded only when submitPitchDeck() is called
          debugPrint(
            '📝 Pitch deck files staged for upload (not uploaded yet)',
          );
          _dirtyFields.remove('pitchDeckFiles');
          return true;
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
    final existingRecord =
        await _supabase
            .from('startup_profiles')
            .select('id')
            .eq('startup_id', userId)
            .maybeSingle();

    if (existingRecord != null) {
      await _supabase
          .from('startup_profiles')
          .update({
            'idea_description': _ideaDescriptionController.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('startup_id', userId);
    } else {
      await _supabase.from('startup_profiles').insert({
        'startup_id': userId,
        'idea_description': _ideaDescriptionController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Save funding goal (from text controller)
  Future<void> _saveFundingGoalAmount(String userId) async {
    final existingRecord =
        await _supabase
            .from('startup_profiles')
            .select('id')
            .eq('startup_id', userId)
            .maybeSingle();

    if (existingRecord != null) {
      await _supabase
          .from('startup_profiles')
          .update({
            'funding_goal': _fundingGoalAmount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('startup_id', userId);
    } else {
      await _supabase.from('startup_profiles').insert({
        'startup_id': userId,
        'funding_goal': _fundingGoalAmount,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _saveFundingPhase(String userId) async {
    debugPrint(
      '🔍 Attempting to save funding phase: "$_selectedFundingPhase"',
    ); // ADD THIS
    debugPrint('🔍 Type: ${_selectedFundingPhase.runtimeType}'); // ADD THIS

    if (_selectedFundingPhase == null) {
      debugPrint('❌ Selected funding phase is null');
      return;
    }
    final existingRecord =
        await _supabase
            .from('startup_profiles')
            .select('id')
            .eq('startup_id', userId)
            .maybeSingle();

    if (existingRecord != null) {
      await _supabase
          .from('startup_profiles')
          .update({
            'funding_stage':
                _selectedFundingPhase, // or whatever your variable name is
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('startup_id', userId);
    } else {
      await _supabase.from('startup_profiles').insert({
        'startup_id': userId,
        'funding_stage': _selectedFundingPhase,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _saveProfileImage(String userId) async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    String? newImageUrl;

    if (_profileImage != null) {
      try {
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

    final existingRecord =
        await _supabase
            .from('startup_profiles')
            .select('id')
            .eq('startup_id', currentUser.id)
            .maybeSingle();

    if (existingRecord != null) {
      await _supabase
          .from('startup_profiles')
          .update({
            'avatar_url': _profileImageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('startup_id', currentUser.id);
    } else {
      await _supabase.from('startup_profiles').insert({
        'startup_id': currentUser.id,
        'avatar_url': _profileImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Save pitch deck files and submission status
  // Save pitch deck files and submission status
  Future<void> _savePitchDeckFiles(String userId) async {
    if (_pitchDeckFiles.isEmpty) return;

    try {
      debugPrint(
        '🚀 Uploading ${_pitchDeckFiles.length} files to cloud storage...',
      );

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
                  'user_id': userId, // ✅ Add user_id to establish relationship
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .select()
                .single();

        _pitchDeckId = response['id'];

        // ✅ REMOVED: Don't update startups table (pitch_deck_id column doesn't exist)
        // Relationship is maintained through pitch_decks.user_id
      }

      debugPrint(
        '✅ Successfully uploaded ${_pitchDeckFiles.length} files to cloud storage',
      );

      // Clear uploaded files since they're now stored
      _pitchDeckFiles.clear();
    } catch (e) {
      debugPrint('❌ Error saving pitch deck files: $e');
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
    final validStages = [
      'Idea',
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
      'Bridge',
    ];

    if (value == null || value.isEmpty) {
      return 'Please select a valid funding phase';
    }

    if (!validStages.contains(value)) {
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

  bool get hasLocalPitchDeckFiles {
    return _pitchDeckFiles.isNotEmpty;
  }

  bool get hasStoredPitchDeckFiles {
    return _pitchDeckThumbnails.isNotEmpty && _pitchDeckId != null;
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
      // Remove corresponding thumbnail if it exists
      if (index < _pitchDeckThumbnails.length) {
        _pitchDeckThumbnails.removeAt(index);
      }
      // ✅ DON'T trigger auto-save/upload when removing files
      notifyListeners();
    }
  }

  bool get canSubmitPitchDeck {
    return _pitchDeckFiles.isNotEmpty && !_isPitchDeckSubmitted;
  }

  Future<void> refreshData() async {
    if (!_isInitialized) {
      await initialize();
    } else {
      await _loadProfileData();
    }
  }

  // 9. NEW: Method to clear only local files (not stored files)
  void clearLocalPitchDeckFiles() {
    _pitchDeckFiles.clear();
    notifyListeners();
  }

  Future<void> submitPitchDeck() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // ✅ NOW upload files to cloud storage when submitting
      if (_pitchDeckFiles.isNotEmpty) {
        await _savePitchDeckFiles(currentUser.id);
      }

      // Update submission status
      _isPitchDeckSubmitted = true;
      _pitchDeckSubmissionDate = DateTime.now();

      // Save submission status to database
      await _savePitchDeckSubmission(currentUser.id);

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error submitting pitch deck: $e');
      rethrow;
    }
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
    _authSubscription?.cancel(); // 🔥 Cancel auth listener
    _saveTimer?.cancel();
    _removeListeners();
    _ideaDescriptionController.dispose();
    _fundingGoalController.dispose();
    super.dispose();
  }
}

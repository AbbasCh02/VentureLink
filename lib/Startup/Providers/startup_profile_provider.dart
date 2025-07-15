// lib/Startup/Providers/startup_profile_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';
import '../../services/storage_service.dart';

/**
 * startup_profile_provider.dart
 * 
 * Implements a comprehensive state management provider for startup profile data,
 * handling idea descriptions, funding information, profile images, and pitch deck files.
 * 
 * Features:
 * - Complete startup profile data management (idea, funding, images, pitch decks)
 * - Auto-saving with debouncing to reduce database calls
 * - Advanced file handling for pitch deck uploads with thumbnails
 * - Profile image management with cloud storage integration
 * - Form validation for all profile fields
 * - Profile completion tracking and progress calculation
 * - Dirty field tracking for real-time UI feedback
 * - Authentication state integration with user isolation
 * - Pitch deck submission workflow with status tracking
 * - Database persistence with Supabase integration
 * - Error handling and loading state management
 */

/**
 * StartupProfileProvider - Advanced change notifier provider for managing
 * comprehensive startup profile data with cloud storage and file management.
 */
class StartupProfileProvider with ChangeNotifier {
  // Text controllers for profile data input
  final TextEditingController _ideaDescriptionController =
      TextEditingController();
  final TextEditingController _fundingGoalController = TextEditingController();

  // Profile image management
  File? _profileImage;
  String? _profileImageUrl; // URL from Supabase storage

  // Pitch deck file management with thumbnails
  List<File> _pitchDeckFiles = [];
  List<Widget> _pitchDeckThumbnails = [];
  bool _isPitchDeckSubmitted = false;
  DateTime? _pitchDeckSubmissionDate;
  String? _pitchDeckId; // Reference to pitch_deck record

  // Auto-save timer for debouncing user input
  Timer? _saveTimer;

  // Funding information storage
  int? _fundingGoalAmount;
  String? _selectedFundingPhase;

  // Loading and error states for UI feedback
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // Dirty tracking for unsaved changes indicator
  final Set<String> _dirtyFields = <String>{};

  // Initialization flags to prevent infinite loops
  bool _isInitializing = false;
  bool _isInitialized = false;

  // User authentication tracking
  String? _currentUserId;
  StreamSubscription<AuthState>? _authSubscription;

  // Supabase client for database operations
  final SupabaseClient _supabase = Supabase.instance.client;

  /**
   * Constructor that automatically sets up authentication listener
   * and initializes data when a user is authenticated.
   */
  StartupProfileProvider() {
    // Initialize automatically when provider is created and user is authenticated
    _setupAuthListener();
    _initializeWhenReady();
  }

  /**
   * Sets up an authentication state listener to handle user sign-in/sign-out events.
   * Ensures data isolation between different users and resets state appropriately.
   */
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

  /**
   * Checks for an authenticated user and initializes immediately if found.
   * Otherwise sets up listeners for future authentication events.
   */
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

  /**
   * Sets new pitch deck files and their corresponding thumbnail widgets.
   * Used when user selects files for upload.
   * 
   * @param files List of selected files
   * @param thumbnails List of thumbnail widgets for the files
   */
  void setPitchDeckFiles(List<File> files, List<Widget> thumbnails) {
    _pitchDeckFiles = files;
    _pitchDeckThumbnails = thumbnails;
    notifyListeners();
  }

  /**
   * Builds a visual card widget for displaying file information.
   * Shows file type icon, name, and provides removal functionality.
   * 
   * @param context The build context
   * @param file The file to create a card for
   * @return Widget representing the file card
   */
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

  /**
   * Returns the appropriate icon for a file based on its extension.
   * Supports PDF, video files, and generic file types.
   * 
   * @param extension The file extension to get an icon for
   * @return Icon widget representing the file type
   */
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

  /**
   * Resets the provider state when a user signs out or changes.
   * Clears all data, cancels timers, and removes listeners.
   */
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

  /**
   * Clears all profile data and resets the provider state.
   * Useful for starting fresh or handling errors.
   */
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

  /**
   * Resets the provider for a new user.
   * Clears existing data and reinitializes for the new user.
   */
  Future<void> resetForNewUser() async {
    clearAllData();
    await initialize();
  }

  /**
   * Adds text field listeners to track changes for auto-saving.
   * Each listener triggers the field change handler with debouncing.
   */
  void _addListeners() {
    _ideaDescriptionController.addListener(
      () => _onFieldChanged('ideaDescription'),
    );
    _fundingGoalController.addListener(() => _onFieldChanged('fundingGoal'));
  }

  /**
   * Removes text field listeners to prevent memory leaks.
   * Called during cleanup and state resets.
   */
  void _removeListeners() {
    _ideaDescriptionController.removeListener(
      () => _onFieldChanged('ideaDescription'),
    );
    _fundingGoalController.removeListener(() => _onFieldChanged('fundingGoal'));
  }

  /**
   * Handles field changes by marking fields as dirty and scheduling auto-save.
   * Implements debouncing to reduce frequent database calls.
   * 
   * @param fieldName The name of the field that changed
   */
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

  // Getters for accessing profile data

  /**
   * Returns the idea description text.
   * 
   * @return Idea description or null if empty
   */
  String? get ideaDescription =>
      _ideaDescriptionController.text.isEmpty
          ? null
          : _ideaDescriptionController.text;

  /**
   * Returns the funding goal amount.
   * 
   * @return Funding goal amount or null if not set
   */
  int? get fundingGoalAmount => _fundingGoalAmount;

  /**
   * Returns the selected funding phase.
   * 
   * @return Selected funding phase or null if not set
   */
  String? get selectedFundingPhase => _selectedFundingPhase;

  /**
   * Returns the local profile image file.
   * 
   * @return Profile image file or null if not set
   */
  File? get profileImage => _profileImage;

  /**
   * Returns the profile image URL from cloud storage.
   * 
   * @return Profile image URL or null if not set
   */
  String? get profileImageUrl => _profileImageUrl;

  /**
   * Returns an unmodifiable list of pitch deck files.
   * 
   * @return List of pitch deck files
   */
  List<File> get pitchDeckFiles => List.unmodifiable(_pitchDeckFiles);

  /**
   * Indicates whether the pitch deck has been submitted.
   * 
   * @return True if pitch deck is submitted
   */
  bool get isPitchDeckSubmitted => _isPitchDeckSubmitted;

  /**
   * Returns the pitch deck submission date.
   * 
   * @return Submission date or null if not submitted
   */
  DateTime? get pitchDeckSubmissionDate => _pitchDeckSubmissionDate;

  /**
   * Returns an unmodifiable list of pitch deck thumbnails.
   * 
   * @return List of thumbnail widgets
   */
  List<Widget> get pitchDeckThumbnails =>
      List.unmodifiable(_pitchDeckThumbnails);

  // Controller getters for UI binding

  /**
   * Provides access to the idea description text controller.
   * 
   * @return Text controller for idea description
   */
  TextEditingController get ideaDescriptionController =>
      _ideaDescriptionController;

  /**
   * Provides access to the funding goal text controller.
   * 
   * @return Text controller for funding goal
   */
  TextEditingController get fundingGoalController => _fundingGoalController;

  // State getters for UI feedback

  /**
   * Indicates whether data is currently loading.
   * 
   * @return Loading state
   */
  bool get isLoading => _isLoading;

  /**
   * Indicates whether a save operation is in progress.
   * 
   * @return Saving state
   */
  bool get isSaving => _isSaving;

  /**
   * Provides the latest error message if any.
   * 
   * @return Error message or null
   */
  String? get error => _error;

  /**
   * Indicates whether the provider has been initialized.
   * 
   * @return Initialization state
   */
  bool get isInitialized => _isInitialized;

  /**
   * Checks if a specific field has unsaved changes.
   * 
   * @param field The field name to check
   * @return True if the field has unsaved changes
   */
  bool hasUnsavedChanges(String field) => _dirtyFields.contains(field);

  /**
   * Indicates whether any fields have unsaved changes.
   * 
   * @return True if there are any unsaved changes
   */
  bool get hasAnyUnsavedChanges => _dirtyFields.isNotEmpty;

  /**
   * Clears the current error state.
   */
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /**
   * Initializes the provider with user data from the database.
   * Loads existing profile data if available and sets up the provider state.
   */
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

  /**
   * Loads startup profile data from the database.
   * Temporarily removes listeners to prevent auto-save during loading.
   * Loads both basic profile data and pitch deck information.
   */
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

  /**
   * Loads pitch deck data from the database for the specified user.
   * Retrieves file information and generates thumbnails for stored files.
   * 
   * @param userId The user ID to load pitch deck data for
   */
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

  /**
   * Generates thumbnail widgets for files that are already stored in cloud storage.
   * Creates visual representations of stored files for UI display.
   * 
   * @param fileUrls List of file URLs from cloud storage
   * @param fileNames List of original file names
   */
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

  /**
   * Builds a visual card widget for stored files in cloud storage.
   * Shows file information with a green border to indicate it's stored.
   * 
   * @param fileUrl URL of the stored file
   * @param fileName Original filename
   * @param extension File extension for icon selection
   * @return Widget representing the stored file card
   */
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
                color: Colors.green.withValues(alpha: 0.2),
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

  /**
   * Extracts a display-friendly filename from stored file names.
   * Removes user IDs and timestamps for cleaner UI presentation.
   * 
   * @param fileName The full filename from storage
   * @return Cleaned filename for display
   */
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

  /**
   * Retrieves the complete startup profile data from the database.
   * 
   * @return Map containing all profile data or null if user not authenticated
   */
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

  /**
   * Saves a specific field to the database with appropriate handling.
   * Implements field-specific logic for different data types.
   * 
   * @param fieldName The name of the field to save
   * @return True if save was successful, false otherwise
   */
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

  /**
   * Saves the idea description to the database.
   * Creates a new record if none exists, updates existing otherwise.
   * 
   * @param userId The user ID to save data for
   */
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

  /**
   * Saves the funding goal amount to the database.
   * Handles both new record creation and existing record updates.
   * 
   * @param userId The user ID to save data for
   */
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

  /**
   * Saves the selected funding phase to the database.
   * Includes debug logging for troubleshooting phase selection issues.
   * 
   * @param userId The user ID to save data for
   */
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

  /**
   * Saves the profile image to cloud storage and updates the database.
   * Uploads the image file first, then saves the URL to the profile.
   * 
   * @param userId The user ID to save data for
   */
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

  /**
   * Uploads pitch deck files to cloud storage and creates database records.
   * Only called during pitch deck submission, not during file selection.
   * 
   * @param userId The user ID to save files for
   */
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

  /**
   * Saves the pitch deck submission status to the database.
   * Updates the submission flag and timestamp when pitch deck is submitted.
   * 
   * @param userId The user ID to save data for
   */
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

  // Public methods for updating profile data programmatically

  /**
   * Updates the idea description field programmatically.
   * Triggers the change handler for auto-saving.
   * 
   * @param value The new idea description value
   */
  void updateIdeaDescription(String value) {
    _ideaDescriptionController.text = value;
    _onFieldChanged('ideaDescription');
  }

  /**
   * Updates the funding goal amount programmatically.
   * Converts the amount to string and triggers auto-saving.
   * 
   * @param amount The new funding goal amount
   */
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

  /**
   * Updates the selected funding phase programmatically.
   * Triggers auto-saving with debouncing.
   * 
   * @param phase The new funding phase selection
   */
  void updateSelectedFundingPhase(String? phase) {
    _selectedFundingPhase = phase;
    _dirtyFields.add('selectedFundingPhase');
    notifyListeners();

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () {
      saveField('selectedFundingPhase');
    });
  }

  /**
   * Updates the profile image and immediately saves it.
   * Profile images are saved immediately rather than with debouncing.
   * 
   * @param image The new profile image file
   */
  void updateProfileImage(File? image) {
    _profileImage = image;
    _dirtyFields.add('profileImage');
    notifyListeners();

    // Save immediately for profile image
    saveField('profileImage');
  }

  // Validation methods for form input

  /**
   * Validates the idea description field input.
   * Checks for minimum length and content requirements.
   * 
   * @param value The idea description to validate
   * @return Error message or null if valid
   */
  String? validateIdeaDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please describe your startup idea';
    }
    if (value.trim().length < 10) {
      return 'Please provide a more detailed description (at least 10 characters)';
    }
    return null;
  }

  /**
   * Validates the funding goal field input.
   * Ensures numeric format and reasonable minimum values.
   * 
   * @param value The funding goal string to validate
   * @return Error message or null if valid
   */
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

  /**
   * Validates the funding phase selection.
   * Ensures the selection is from the approved list of funding stages.
   * 
   * @param value The funding phase to validate
   * @return Error message or null if valid
   */
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

  // Computed properties for UI state

  /**
   * Indicates whether there are any pitch deck files (local or stored).
   * 
   * @return True if there are pitch deck files available
   */
  bool get hasPitchDeckFiles {
    return _pitchDeckFiles.isNotEmpty || _pitchDeckThumbnails.isNotEmpty;
  }

  /**
   * Returns the total count of pitch deck files including stored files.
   * 
   * @return Total number of pitch deck files
   */
  int get totalPitchDeckFilesCount {
    return _pitchDeckFiles.length + _pitchDeckThumbnails.length;
  }

  /**
   * Indicates whether there are local pitch deck files ready for upload.
   * 
   * @return True if there are local files staged for upload
   */
  bool get hasLocalPitchDeckFiles {
    return _pitchDeckFiles.isNotEmpty;
  }

  /**
   * Indicates whether there are stored pitch deck files in cloud storage.
   * 
   * @return True if there are files already stored in the cloud
   */
  bool get hasStoredPitchDeckFiles {
    return _pitchDeckThumbnails.isNotEmpty && _pitchDeckId != null;
  }

  /**
   * Indicates whether a profile image is available (local or stored).
   * 
   * @return True if there is a profile image
   */
  bool get hasProfileImage {
    return _profileImage != null ||
        (_profileImageUrl != null && _profileImageUrl!.isNotEmpty);
  }

  /**
   * Determines if the profile is complete with all required fields.
   * 
   * @return True if all required fields are filled
   */
  bool get isProfileComplete {
    return ideaDescription != null &&
        _fundingGoalAmount != null &&
        _selectedFundingPhase != null;
  }

  /**
   * Calculates the profile completion percentage.
   * Based on four main fields: idea, funding goal, funding phase, and profile image.
   * 
   * @return Completion percentage (0-100)
   */
  double get completionPercentage {
    int completedFields = 0;
    if (ideaDescription != null) completedFields++;
    if (_fundingGoalAmount != null) completedFields++;
    if (_selectedFundingPhase != null) completedFields++;
    if (_profileImageUrl != null) completedFields++;
    return (completedFields / 4) * 100;
  }

  // Pitch deck management methods

  /**
   * Adds new pitch deck files to the local collection.
   * Files are staged for upload but not immediately uploaded.
   * 
   * @param files List of files to add to the pitch deck
   */
  void addPitchDeckFiles(List<File> files) {
    _pitchDeckFiles.addAll(files);
    _dirtyFields.add('pitchDeckFiles');
    notifyListeners();
    saveField('pitchDeckFiles');
  }

  /**
   * Removes a pitch deck file from the local collection.
   * Removes both the file and its corresponding thumbnail.
   * 
   * @param index The index of the file to remove
   */
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

  /**
   * Determines if the pitch deck can be submitted.
   * Requires local files and that the pitch deck hasn't been submitted yet.
   * 
   * @return True if pitch deck can be submitted
   */
  bool get canSubmitPitchDeck {
    return _pitchDeckFiles.isNotEmpty && !_isPitchDeckSubmitted;
  }

  /**
   * Refreshes all profile data from the database.
   * Useful for manual refresh operations or after external changes.
   */
  Future<void> refreshData() async {
    if (!_isInitialized) {
      await initialize();
    } else {
      await _loadProfileData();
    }
  }

  /**
   * Clears only local pitch deck files, keeping stored files intact.
   * Used when user wants to reset their file selection.
   */
  void clearLocalPitchDeckFiles() {
    _pitchDeckFiles.clear();
    notifyListeners();
  }

  /**
   * Submits the pitch deck by uploading files and updating submission status.
   * This is when files are actually uploaded to cloud storage.
   */
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

  // Data export and summary methods

  /**
   * Returns the complete profile data as a map.
   * Useful for exporting or displaying profile information.
   * 
   * @return Map containing all profile data
   */
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

  /**
   * Returns a list of current validation errors for all fields.
   * Useful for displaying comprehensive error summaries.
   * 
   * @return List of validation error messages
   */
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

  /**
   * Cleans up resources when the provider is disposed.
   * Cancels timers, removes listeners, and disposes controllers.
   */
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

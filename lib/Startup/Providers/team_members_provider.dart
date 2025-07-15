// lib/Startup/Providers/team_members_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

/**
 * team_members_provider.dart
 * 
 * Implements a comprehensive state management provider for team member data,
 * handling team composition, roles, LinkedIn profiles, and member management.
 * 
 * Features:
 * - Complete team member data management (CRUD operations)
 * - Team composition analytics and role distribution tracking
 * - LinkedIn profile validation and management
 * - Bulk operations for adding multiple team members
 * - Form validation for all team member fields
 * - Team completion tracking and progress calculation
 * - Dirty field tracking for real-time UI feedback
 * - Authentication state integration with user isolation
 * - Leadership team identification and filtering
 * - Database persistence with Supabase integration
 * - Error handling and loading state management
 * - Data export/import functionality for team backup
 */

/**
 * TeamMember - Data model representing a single team member.
 * Contains all necessary information for team member management.
 */
class TeamMember {
  final String id;
  final String name;
  final String role;
  final String linkedin;
  final String avatar;
  final DateTime dateAdded;

  /**
   * Creates a new TeamMember instance.
   * 
   * @param id Unique identifier for the team member
   * @param name Full name of the team member
   * @param role Position/role within the startup
   * @param linkedin LinkedIn profile URL (optional)
   * @param avatar Avatar/profile image URL (optional)
   * @param dateAdded Date when the member was added to the team
   */
  TeamMember({
    required this.id,
    required this.name,
    required this.role,
    this.linkedin = '',
    this.avatar = '',
    required this.dateAdded,
  });

  /**
   * Creates a TeamMember instance from Supabase database data.
   * Handles data conversion and provides default values for missing fields.
   * 
   * @param map Raw data map from Supabase query
   * @return TeamMember instance with converted data
   */
  factory TeamMember.fromSupabaseMap(Map<String, dynamic> map) {
    return TeamMember(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      linkedin: map['linkedin_url'] ?? '',
      avatar: map['avatar_url'] ?? 'https://via.placeholder.com/150',
      dateAdded: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /**
   * Converts the TeamMember instance to a map for database storage.
   * 
   * @return Map containing all team member data
   */
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'linkedin_url': linkedin,
      'avatar_url': avatar,
      'created_at': dateAdded.toIso8601String(),
    };
  }

  /**
   * Creates a copy of the TeamMember with updated fields.
   * Useful for updating specific properties while preserving others.
   * 
   * @param id New ID (optional)
   * @param name New name (optional)
   * @param role New role (optional)
   * @param linkedin New LinkedIn URL (optional)
   * @param avatar New avatar URL (optional)
   * @param dateAdded New date added (optional)
   * @return New TeamMember instance with updated values
   */
  TeamMember copyWith({
    String? id,
    String? name,
    String? role,
    String? linkedin,
    String? avatar,
    DateTime? dateAdded,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      linkedin: linkedin ?? this.linkedin,
      avatar: avatar ?? this.avatar,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }
}

/**
 * TeamMembersProvider - Advanced change notifier provider for managing
 * comprehensive team member data with analytics and bulk operations.
 */
class TeamMembersProvider with ChangeNotifier {
  // Form controllers for team member input
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();

  // Team members storage
  final List<TeamMember> _teamMembers = [];

  // Auto-save timer for debouncing user input
  Timer? _saveTimer;

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
  TeamMembersProvider() {
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
            '🔄 Different startup user detected, resetting team provider state',
          );
          _resetProviderState();
        }
        _currentUserId = user.id;

        // Initialize for new user if not already initialized
        if (!_isInitialized) {
          initialize();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('🔄 Startup user signed out, resetting team provider state');
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
   * Resets the provider state when a user signs out or changes.
   * Clears all data, cancels timers, and removes listeners.
   */
  void _resetProviderState() {
    _isInitialized = false;
    _currentUserId = null;
    _teamMembers.clear();
    _nameController.clear();
    _roleController.clear();
    _linkedinController.clear();
    _dirtyFields.clear();
    _error = null;
    _saveTimer?.cancel();
    notifyListeners();
  }

  /**
   * Adds text field listeners to track changes for form validation.
   * Each listener triggers the field change handler for UI updates.
   */
  void _addListeners() {
    _nameController.addListener(() => _onFieldChanged('name'));
    _roleController.addListener(() => _onFieldChanged('role'));
    _linkedinController.addListener(() => _onFieldChanged('linkedin'));
  }

  /**
   * Removes text field listeners to prevent memory leaks.
   * Called during cleanup and state resets.
   */
  void _removeListeners() {
    _nameController.removeListener(() => _onFieldChanged('name'));
    _roleController.removeListener(() => _onFieldChanged('role'));
    _linkedinController.removeListener(() => _onFieldChanged('linkedin'));
  }

  /**
   * Handles field changes by marking fields as dirty for UI feedback.
   * Used to show users which fields have been modified.
   * 
   * @param fieldName The name of the field that changed
   */
  void _onFieldChanged(String fieldName) {
    // Don't mark as dirty during initialization
    if (_isInitializing) return;

    _dirtyFields.add(fieldName);
    notifyListeners();
  }

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
   * Loads existing team members if available and sets up the provider state.
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
      debugPrint(
        '✅ Team provider already initialized for user: ${currentUser.id}',
      );
      await _loadTeamMembers();
      return;
    }

    _isLoading = true;
    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      await _loadTeamMembers();
      _isInitialized = true;
      debugPrint('✅ Team members initialized for user: ${currentUser.id}');
    } catch (e) {
      _error = 'Failed to initialize team members: $e';
      debugPrint('❌ Error initializing team members: $e');
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /**
   * Loads team members data from the database.
   * Retrieves all team members for the current user and populates the local list.
   */
  Future<void> _loadTeamMembers() async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }

    // 🔥 ADDITIONAL SAFETY: Verify user consistency
    if (_currentUserId != null && _currentUserId != currentUser.id) {
      debugPrint('⚠️ User mismatch detected in _loadTeamMembers, resetting');
      _resetProviderState();
      _currentUserId = currentUser.id;
    }

    try {
      debugPrint('🔄 Loading team members for user: ${currentUser.id}');

      final response = await _supabase
          .from('team_members')
          .select('*')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      // 🔥 CRITICAL: Clear existing team members before loading new ones
      _teamMembers.clear();

      for (final memberData in response) {
        final teamMember = TeamMember(
          id: memberData['id'] ?? '',
          name: memberData['name'] ?? '',
          role: memberData['role'] ?? '',
          linkedin: memberData['linkedin_url'] ?? '',
          avatar: memberData['avatar_url'] ?? '',
          dateAdded:
              memberData['created_at'] != null
                  ? DateTime.parse(memberData['created_at'])
                  : DateTime.now(),
        );
        _teamMembers.add(teamMember);
      }

      debugPrint(
        '✅ Loaded ${_teamMembers.length} team members for user: ${currentUser.id}',
      );
    } catch (e) {
      _error = 'Failed to load team members: $e';
      debugPrint('❌ Error loading team members: $e');
      rethrow;
    }
  }

  // Getters for accessing team data

  /**
   * Returns an unmodifiable list of all team members.
   * 
   * @return List of team members
   */
  List<TeamMember> get teamMembers => List.unmodifiable(_teamMembers);

  /**
   * Returns the total number of team members.
   * 
   * @return Count of team members
   */
  int get teamMembersCount => _teamMembers.length;

  /**
   * Indicates whether the team has any members.
   * 
   * @return True if team has members
   */
  bool get hasTeamMembers => _teamMembers.isNotEmpty;

  /**
   * Calculates the team completion percentage based on ideal team size.
   * Assumes an ideal team size of 3 members for 100% completion.
   * 
   * @return Completion percentage (0-100)
   */
  double get completionPercentage {
    if (_teamMembers.isEmpty) return 0.0;
    if (_teamMembers.length >= 3) return 100.0;
    return (_teamMembers.length / 3) * 100; // Assuming ideal team size is 3
  }

  // Controller getters for UI binding

  /**
   * Provides access to the name text controller.
   * 
   * @return Text controller for member name
   */
  TextEditingController get nameController => _nameController;

  /**
   * Provides access to the role text controller.
   * 
   * @return Text controller for member role
   */
  TextEditingController get roleController => _roleController;

  /**
   * Provides access to the LinkedIn text controller.
   * 
   * @return Text controller for LinkedIn URL
   */
  TextEditingController get linkedinController => _linkedinController;

  /**
   * Indicates whether the current form has valid data.
   * Checks that required fields (name and role) are not empty.
   * 
   * @return True if form is valid
   */
  bool get isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _roleController.text.trim().isNotEmpty;

  // Team analysis and filtering methods

  /**
   * Returns team members filtered by a specific role.
   * Performs case-insensitive search within role names.
   * 
   * @param role The role to filter by
   * @return List of team members with matching roles
   */
  List<TeamMember> getTeamMembersByRole(String role) {
    return _teamMembers
        .where(
          (member) => member.role.toLowerCase().contains(role.toLowerCase()),
        )
        .toList();
  }

  /**
   * Returns team members in leadership positions.
   * Identifies leadership roles like CEO, CTO, CFO, Co-founder, etc.
   * 
   * @return List of leadership team members
   */
  List<TeamMember> get leadershipTeam {
    final leadershipRoles = [
      'ceo',
      'cto',
      'cfo',
      'co-founder',
      'founder',
      'president',
    ];
    return _teamMembers
        .where(
          (member) => leadershipRoles.any(
            (role) => member.role.toLowerCase().contains(role),
          ),
        )
        .toList();
  }

  /**
   * Checks if a team member with the given name and role already exists.
   * Performs case-insensitive comparison to prevent duplicates.
   * 
   * @param name The member's name to check
   * @param role The member's role to check
   * @return True if a member with this name and role exists
   */
  bool isTeamMemberExists(String name, String role) {
    return _teamMembers.any(
      (member) =>
          member.name.toLowerCase() == name.toLowerCase() &&
          member.role.toLowerCase() == role.toLowerCase(),
    );
  }

  // CRUD operations for team members

  /**
   * Adds a new team member using form data and saves to database.
   * Validates input, checks for duplicates, and handles database persistence.
   * 
   * @return True if member was added successfully, false otherwise
   */
  Future<bool> addTeamMember() async {
    final name = _nameController.text.trim();
    final role = _roleController.text.trim();
    final linkedin = _linkedinController.text.trim();

    // Validate required fields
    if (name.isEmpty) {
      _error = 'Name is required';
      notifyListeners();
      return false;
    }

    if (role.isEmpty) {
      _error = 'Role is required';
      notifyListeners();
      return false;
    }

    // Check for duplicate names
    if (_teamMembers.any(
      (member) => member.name.toLowerCase() == name.toLowerCase(),
    )) {
      _error = 'A team member with this name already exists';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Save to Supabase - FIXED: Use 'linkedin_url' instead of 'linkedin'
      final response =
          await _supabase
              .from('team_members')
              .insert({
                'user_id': currentUser.id,
                'name': name,
                'role': role,
                'linkedin_url': linkedin.isEmpty ? null : linkedin, // ✅ FIXED
                'created_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      // Create local team member object
      final newMember = TeamMember(
        id: response['id'],
        name: name,
        role: role,
        linkedin: linkedin.isEmpty ? '' : linkedin,
        dateAdded: DateTime.parse(response['created_at']),
      );

      // Add to local list
      _teamMembers.add(newMember);

      // Clear form
      _nameController.clear();
      _roleController.clear();
      _linkedinController.clear();
      _dirtyFields.clear();

      debugPrint('✅ Team member added successfully: $name');
      return true;
    } catch (e) {
      _error = 'Failed to add team member: $e';
      debugPrint('❌ Error adding team member: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /**
   * Removes a team member from both database and local storage.
   * 
   * @param memberId The ID of the member to remove
   * @return True if member was removed successfully, false otherwise
   */
  Future<bool> removeTeamMember(String memberId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Remove from Supabase
      await _supabase.from('team_members').delete().eq('id', memberId);

      // Remove from local list
      _teamMembers.removeWhere((member) => member.id == memberId);

      debugPrint('✅ Team member removed successfully');
      return true;
    } catch (e) {
      _error = 'Failed to remove team member: $e';
      debugPrint('❌ Error removing team member: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /**
   * Updates an existing team member's information.
   * Allows selective updating of specific fields while preserving others.
   * 
   * @param id The member ID to update
   * @param name New name (optional)
   * @param role New role (optional)
   * @param linkedin New LinkedIn URL (optional)
   * @param avatar New avatar URL (optional)
   * @return True if update was successful, false otherwise
   */
  Future<bool> updateTeamMember(
    String id, {
    String? name,
    String? role,
    String? linkedin,
    String? avatar,
  }) async {
    final memberIndex = _teamMembers.indexWhere((member) => member.id == id);
    if (memberIndex == -1) {
      _error = 'Team member not found';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Prepare update data
      Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (role != null) updateData['role'] = role;
      if (linkedin != null) updateData['linkedin_url'] = linkedin;
      if (avatar != null) updateData['avatar_url'] = avatar;

      // Update in Supabase
      final response =
          await _supabase
              .from('team_members')
              .update(updateData)
              .eq('id', id)
              .select('*')
              .single();

      // Update local member
      _teamMembers[memberIndex] = TeamMember.fromSupabaseMap(response);

      _markTeamMembersDirtyAndSave();
      debugPrint('Team member updated successfully');
      return true;
    } catch (e) {
      _error = 'Failed to update team member: $e';
      debugPrint('Error updating team member: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Bulk operations for team management

  /**
   * Adds multiple team members in a single bulk operation.
   * More efficient than adding members one by one for large teams.
   * 
   * @param members List of member data maps to add
   * @return True if all members were added successfully, false otherwise
   */
  Future<bool> addMultipleTeamMembers(List<Map<String, String>> members) async {
    if (members.isEmpty) return true;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Prepare data for bulk insert
      final insertData =
          members
              .map(
                (member) => {
                  'name': member['name'] ?? '',
                  'role': member['role'] ?? '',
                  'linkedin_url':
                      member['linkedin']?.isEmpty == false
                          ? member['linkedin']
                          : null,
                  'avatar_url':
                      member['avatar'] ?? 'https://via.placeholder.com/150',
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                },
              )
              .toList();

      // Bulk insert to Supabase
      final response = await _supabase
          .from('team_members')
          .insert(insertData)
          .select('*');

      // Add to local list
      final newMembers =
          (response as List)
              .map((memberData) => TeamMember.fromSupabaseMap(memberData))
              .toList();

      _teamMembers.insertAll(0, newMembers); // Add at beginning

      _markTeamMembersDirtyAndSave();
      debugPrint('Added ${newMembers.length} team members successfully');
      return true;
    } catch (e) {
      _error = 'Failed to add multiple team members: $e';
      debugPrint('Error adding multiple team members: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /**
   * Removes all team members from both database and local storage.
   * Use with caution as this operation cannot be undone.
   */
  Future<void> clearAllTeamMembers() async {
    if (_teamMembers.isEmpty) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Get all team member IDs
      final memberIds = _teamMembers.map((member) => member.id).toList();

      // Delete all from Supabase
      for (final memberId in memberIds) {
        await _supabase.from('team_members').delete().eq('id', memberId);
      }

      // Clear local list
      _teamMembers.clear();
      _dirtyFields.clear();

      debugPrint('All team members cleared successfully');
    } catch (e) {
      _error = 'Failed to clear team members: $e';
      debugPrint('Error clearing team members: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /**
   * Synchronizes team members with the database.
   * Mainly for UI consistency and clearing dirty flags.
   * 
   * @return True if sync was successful, false otherwise
   */
  Future<bool> saveTeamMembers() async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // In this implementation, team members are saved individually
      // This method is mainly for UI consistency and clearing dirty flags
      _dirtyFields.clear();
      debugPrint('Team members sync completed');
      return true;
    } catch (e) {
      _error = 'Failed to save team members: $e';
      debugPrint('Error saving team members: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /**
   * Clears all team member data and resets the provider state.
   * Useful for starting fresh or handling errors.
   */
  Future<void> clearAllData() async {
    _nameController.clear();
    _roleController.clear();
    _linkedinController.clear();

    _teamMembers.clear();
    _error = null;
    _isInitialized = false;

    notifyListeners();
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
   * Marks team members data as dirty for UI feedback.
   * Used internally to indicate changes that need saving.
   */
  void _markTeamMembersDirtyAndSave() {
    _dirtyFields.add('teamMembers');
    notifyListeners();
  }

  /**
   * Clears the form controllers without triggering dirty state.
   * Temporarily removes listeners to prevent false dirty flags.
   */
  void clearForm() {
    // Temporarily remove listeners to prevent triggering dirty state
    _removeListeners();

    _nameController.clear();
    _roleController.clear();
    _linkedinController.clear();

    // Re-add listeners
    _addListeners();

    // Remove form field dirty states
    _dirtyFields.remove('name');
    _dirtyFields.remove('role');
    _dirtyFields.remove('linkedin');

    notifyListeners();
  }

  // Validation methods for form input

  /**
   * Validates the team member name field.
   * Ensures name is provided and meets minimum length requirements.
   * 
   * @param value The name to validate
   * @return Error message or null if valid
   */
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /**
   * Validates the team member role field.
   * Ensures role is provided and meets minimum length requirements.
   * 
   * @param value The role to validate
   * @return Error message or null if valid
   */
  String? validateRole(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Role is required';
    }
    if (value.trim().length < 2) {
      return 'Role must be at least 2 characters';
    }
    return null;
  }

  /**
   * Validates the LinkedIn profile URL field.
   * LinkedIn is optional, but if provided, must be a valid LinkedIn URL.
   * 
   * @param value The LinkedIn URL to validate
   * @return Error message or null if valid
   */
  String? validateLinkedin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // LinkedIn is optional
    }

    final linkedinPattern = RegExp(
      r'^https?:\/\/(www\.)?linkedin\.com\/in\/[a-zA-Z0-9-]+\/?$',
      caseSensitive: false,
    );

    if (!linkedinPattern.hasMatch(value.trim())) {
      return 'Please enter a valid LinkedIn profile URL';
    }

    return null;
  }

  // Analytics and reporting methods

  /**
   * Generates a comprehensive summary of the team composition.
   * Includes member counts, role distribution, and team analysis.
   * 
   * @return Map containing detailed team analytics
   */

  Map<String, dynamic> getTeamSummary() {
    final roles = <String, int>{};
    for (final member in _teamMembers) {
      final role = member.role.toLowerCase();
      roles[role] = (roles[role] ?? 0) + 1;
    }

    return {
      'totalMembers': _teamMembers.length,
      'leadershipCount': leadershipTeam.length,
      'roleDistribution': roles,
      'hasFounder': _teamMembers.any(
        (m) =>
            m.role.toLowerCase().contains('founder') ||
            m.role.toLowerCase().contains('ceo'),
      ),
      'averageTeamSize': _teamMembers.length,
      'newestMember': _teamMembers.isNotEmpty ? _teamMembers.first : null,
      'oldestMember': _teamMembers.isNotEmpty ? _teamMembers.last : null,
    };
  }

  @override
  void dispose() {
    _authSubscription?.cancel(); // 🔥 Cancel auth listener
    _saveTimer?.cancel();
    _removeListeners();
    _nameController.dispose();
    _roleController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }
}

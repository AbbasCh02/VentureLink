// lib/Startup/Providers/team_members_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Team Member model
class TeamMember {
  final String id;
  final String name;
  final String role;
  final String linkedin;
  final String avatar;
  final DateTime dateAdded;

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
    this.linkedin = '',
    this.avatar = '',
    required this.dateAdded,
  });

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

class TeamMembersProvider with ChangeNotifier {
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();

  // Team members list
  final List<TeamMember> _teamMembers = [];

  // Auto-save timer
  Timer? _saveTimer;

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

  TeamMembersProvider() {
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

  // Reset provider state on logout
  void _resetProviderState() {
    _isInitialized = false;
    _teamMembers.clear();
    _nameController.clear();
    _roleController.clear();
    _linkedinController.clear();
    _dirtyFields.clear();
    _error = null;
    notifyListeners();
  }

  void _addListeners() {
    _nameController.addListener(() => _onFieldChanged('name'));
    _roleController.addListener(() => _onFieldChanged('role'));
    _linkedinController.addListener(() => _onFieldChanged('linkedin'));
  }

  void _removeListeners() {
    _nameController.removeListener(() => _onFieldChanged('name'));
    _roleController.removeListener(() => _onFieldChanged('role'));
    _linkedinController.removeListener(() => _onFieldChanged('linkedin'));
  }

  void _onFieldChanged(String fieldName) {
    // Don't mark as dirty during initialization
    if (_isInitializing) return;

    _dirtyFields.add(fieldName);
    notifyListeners();
  }

  // Getters for states
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  // Check if specific field has unsaved changes
  bool hasUnsavedChanges(String field) => _dirtyFields.contains(field);
  bool get hasAnyUnsavedChanges => _dirtyFields.isNotEmpty;

  // Clear error method
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Initialize and load team members from Supabase
  Future<void> initialize() async {
    if (_isInitialized) {
      // If already initialized, just refresh data
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
      debugPrint('✅ Team members initialized successfully');
    } catch (e) {
      _error = 'Failed to initialize team members: $e';
      debugPrint('❌ Error initializing team members: $e');
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTeamMembers() async {
    try {
      // Get current user
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('No authenticated user found for team members');
        return;
      }

      // Load team members from Supabase
      final response = await _supabase
          .from('team_members')
          .select('*')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: true);

      // Clear existing team members
      _teamMembers.clear();

      // Parse and add team members
      for (final memberData in response) {
        final teamMember = TeamMember(
          id: memberData['id'],
          name: memberData['name'] ?? '',
          role: memberData['role'] ?? '',
          linkedin: memberData['linkedin_url'] ?? '', // Changed from 'linkedin'
          avatar: memberData['avatar_url'] ?? '', // Changed from 'avatar'
          dateAdded:
              memberData['created_at'] != null
                  ? DateTime.parse(memberData['created_at'])
                  : DateTime.now(),
        );
        _teamMembers.add(teamMember);
      }

      debugPrint('✅ Loaded ${_teamMembers.length} team members');
    } catch (e) {
      _error = 'Failed to load team members: $e';
      debugPrint('❌ Error loading team members: $e');
      rethrow;
    }
  }

  // Add getter for team members list
  List<TeamMember> get teamMembers => List.unmodifiable(_teamMembers);

  // Add getter for team members count
  int get teamMembersCount => _teamMembers.length;

  // Check if team has members
  bool get hasTeamMembers => _teamMembers.isNotEmpty;

  // Get completion percentage for team setup
  double get completionPercentage {
    if (_teamMembers.isEmpty) return 0.0;
    if (_teamMembers.length >= 3) return 100.0;
    return (_teamMembers.length / 3) * 100; // Assuming ideal team size is 3
  }

  // Getters for controllers
  TextEditingController get nameController => _nameController;
  TextEditingController get roleController => _roleController;
  TextEditingController get linkedinController => _linkedinController;

  // Form validation
  bool get isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _roleController.text.trim().isNotEmpty;

  // Get team members by role
  List<TeamMember> getTeamMembersByRole(String role) {
    return _teamMembers
        .where(
          (member) => member.role.toLowerCase().contains(role.toLowerCase()),
        )
        .toList();
  }

  // Get leadership team (CEO, CTO, etc.)
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

  // Check if team member exists
  bool isTeamMemberExists(String name, String role) {
    return _teamMembers.any(
      (member) =>
          member.name.toLowerCase() == name.toLowerCase() &&
          member.role.toLowerCase() == role.toLowerCase(),
    );
  }

  // Add a new team member with Supabase save
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

  // Remove a team member
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

  // Update a team member
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

  // Add multiple team members (bulk operation)
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

  // Clear all team members with Supabase delete
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

  // Save team members to Supabase (for consistency with UI)
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

  // Mark team members as dirty
  void _markTeamMembersDirtyAndSave() {
    _dirtyFields.add('teamMembers');
    notifyListeners();
  }

  // Clear form controllers
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

  // Validation methods
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? validateRole(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Role is required';
    }
    if (value.trim().length < 2) {
      return 'Role must be at least 2 characters';
    }
    return null;
  }

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

  // Get team summary for display
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

  // Export team data for backup/sharing
  Map<String, dynamic> exportTeamData() {
    return {
      'teamMembers': _teamMembers.map((member) => member.toMap()).toList(),
      'teamCount': _teamMembers.length,
      'leadershipCount': leadershipTeam.length,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  // Import team data
  Future<bool> importTeamData(List<Map<String, String>> membersData) async {
    try {
      await addMultipleTeamMembers(membersData);
      debugPrint('Team data imported successfully');
      return true;
    } catch (e) {
      _error = 'Failed to import team data: $e';
      debugPrint('Error importing team data: $e');
      return false;
    }
  }

  // Refresh data from database
  Future<void> refreshFromDatabase() async {
    await _loadTeamMembers();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _removeListeners();
    _nameController.dispose();
    _roleController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }
}

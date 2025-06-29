// lib/Providers/team_members_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

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
    required this.linkedin,
    required this.avatar,
    required this.dateAdded,
  });

  // Convert to Map for Supabase storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'linkedin_url': linkedin,
      'avatar_url': avatar,
      'created_at': dateAdded.toIso8601String(),
      'updated_at': dateAdded.toIso8601String(),
    };
  }

  // Create from Supabase Map
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

  // Create from Map for backward compatibility
  factory TeamMember.fromMap(Map<String, dynamic> map) {
    return TeamMember(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      linkedin: map['linkedin'] ?? '',
      avatar: map['avatar'] ?? 'https://via.placeholder.com/150',
      dateAdded: DateTime.parse(
        map['dateAdded'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // Create a copy with modified fields
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
  // Controllers for the form
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();

  // Team members list
  List<TeamMember> _teamMembers = [];

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

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  // Track if provider is initialized
  bool _isInitialized = false;

  TeamMembersProvider() {
    // Initialize automatically when provider is created
    initialize();
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

    // For form fields, we use debounced auto-save but don't actually save
    // since form fields get cleared after adding a team member
    _saveTimer?.cancel();
    _saveTimer = Timer(Duration(seconds: 1), () {
      // Form fields don't auto-save - they're just for UI state consistency
      // The actual saving happens when team members are added/updated/removed
    });
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
    if (_isInitialized) return; // Prevent multiple initializations

    _isLoading = true;
    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      // Get current user
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Load all team members from the database
      // In a production app, you might want to filter by user or organization
      final teamMembersResponse = await _supabase
          .from('team_members')
          .select('*')
          .order('created_at', ascending: false);

      if (teamMembersResponse.isNotEmpty) {
        _teamMembers =
            (teamMembersResponse as List)
                .map((memberData) => TeamMember.fromSupabaseMap(memberData))
                .toList();

        debugPrint('Loaded ${_teamMembers.length} team members');
      } else {
        _teamMembers = [];
      }

      // Add listeners after initialization
      _addListeners();

      _dirtyFields.clear(); // Clear dirty state after loading
      _isInitialized = true;
      debugPrint('Team members data loaded successfully');
    } catch (e) {
      _error = 'Failed to load team members data: $e';
      debugPrint('Error loading team members data: $e');
      _teamMembers = []; // Set empty list on error
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save team members to Supabase (bulk operation)
  Future<bool> saveTeamMembers() async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Note: Individual team members are saved when added/updated/removed
      // This method is for consistency with the existing API
      _dirtyFields.remove('teamMembers');
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

  // Mark team members as dirty and auto-save
  void _markTeamMembersDirtyAndSave() {
    _dirtyFields.add('teamMembers');
    notifyListeners();
    // Auto-save team members immediately when they change
    saveTeamMembers();
  }

  // Getters for controllers
  TextEditingController get nameController => _nameController;
  TextEditingController get roleController => _roleController;
  TextEditingController get linkedinController => _linkedinController;

  // Getters for data
  List<TeamMember> get teamMembers => List.unmodifiable(_teamMembers);
  int get teamMemberCount => _teamMembers.length;

  // Computed getters
  bool get hasTeamMembers => _teamMembers.isNotEmpty;
  bool get canSave => _teamMembers.isNotEmpty || hasAnyUnsavedChanges;

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
    final leadershipRoles = ['ceo', 'cto', 'cfo', 'co-founder', 'founder'];
    return _teamMembers
        .where(
          (member) => leadershipRoles.any(
            (role) => member.role.toLowerCase().contains(role),
          ),
        )
        .toList();
  }

  // Add a new team member with Supabase save
  Future<bool> addTeamMember({
    String? customName,
    String? customRole,
    String? customLinkedin,
    String? customAvatar,
  }) async {
    final name = customName ?? _nameController.text.trim();
    final role = customRole ?? _roleController.text.trim();
    final linkedin = customLinkedin ?? _linkedinController.text.trim();

    if (name.isNotEmpty && role.isNotEmpty) {
      _isSaving = true;
      notifyListeners();

      try {
        // Create team member in Supabase
        final memberData = {
          'name': name,
          'role': role,
          'linkedin_url': linkedin.isEmpty ? null : linkedin,
          'avatar_url': customAvatar ?? 'https://via.placeholder.com/150',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final response =
            await _supabase
                .from('team_members')
                .insert(memberData)
                .select('*')
                .single();

        // Create TeamMember object and add to local list
        final newMember = TeamMember.fromSupabaseMap(response);
        _teamMembers.add(newMember);

        // Get current user and potentially link this team member
        final User? currentUser = _supabase.auth.currentUser;
        if (currentUser != null && _teamMembers.length == 1) {
          // If this is the first team member, we might want to link it to the user
          // For now, we'll skip this and manage team members separately
          debugPrint('First team member added, could link to user profile');
        }

        // Clear form controllers
        clearForm();

        // Mark as dirty for any additional processing
        _markTeamMembersDirtyAndSave();

        debugPrint('Team member added successfully: ${newMember.name}');
        return true;
      } catch (e) {
        _error = 'Failed to add team member: $e';
        debugPrint('Error adding team member: $e');
        return false;
      } finally {
        _isSaving = false;
        notifyListeners();
      }
    }
    return false;
  }

  // Remove a team member with Supabase delete
  Future<bool> removeTeamMember(String id) async {
    final memberIndex = _teamMembers.indexWhere((member) => member.id == id);
    if (memberIndex == -1) return false;

    _isSaving = true;
    notifyListeners();

    try {
      // Delete from Supabase
      await _supabase.from('team_members').delete().eq('id', id);

      // Remove from local list
      _teamMembers.removeAt(memberIndex);

      // Mark as dirty for additional processing
      _markTeamMembersDirtyAndSave();

      debugPrint('Team member removed successfully');
      return true;
    } catch (e) {
      _error = 'Failed to remove team member: $e';
      debugPrint('Error removing team member: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Remove team member by index with Supabase delete
  Future<bool> removeTeamMemberAt(int index) async {
    if (index >= 0 && index < _teamMembers.length) {
      final memberId = _teamMembers[index].id;
      return await removeTeamMember(memberId);
    }
    return false;
  }

  // Update a team member with Supabase save
  Future<bool> updateTeamMember(
    String id, {
    String? name,
    String? role,
    String? linkedin,
    String? avatar,
  }) async {
    final memberIndex = _teamMembers.indexWhere((member) => member.id == id);
    if (memberIndex == -1) return false;

    _isSaving = true;
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

      // Mark as dirty for additional processing
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

  // Clear all team members with Supabase delete
  Future<void> clearAllTeamMembers() async {
    if (_teamMembers.isEmpty) return;

    _isSaving = true;
    notifyListeners();

    try {
      // Get all team member IDs
      final memberIds = _teamMembers.map((member) => member.id).toList();

      // Delete all from Supabase using individual deletes
      // Note: Supabase doesn't support bulk delete with `in` operator directly
      for (final memberId in memberIds) {
        await _supabase.from('team_members').delete().eq('id', memberId);
      }

      // Clear local list
      _teamMembers.clear();
      _dirtyFields.clear();

      notifyListeners();
      debugPrint('All team members cleared successfully');
    } catch (e) {
      _error = 'Failed to clear team members data: $e';
      debugPrint('Error clearing team members data: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
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
      return 'Please enter team member\'s name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? validateRole(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter team member\'s role';
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
      r'^https?:\/\/(www\.)?linkedin\.com\/in\/[a-zA-Z0-9\-]+\/?$',
      caseSensitive: false,
    );

    if (!linkedinPattern.hasMatch(value.trim())) {
      return 'Please enter a valid LinkedIn URL';
    }
    return null;
  }

  // Check if team member already exists
  bool isTeamMemberExists(String name, String role) {
    return _teamMembers.any(
      (member) =>
          member.name.toLowerCase() == name.toLowerCase() &&
          member.role.toLowerCase() == role.toLowerCase(),
    );
  }

  // Get team summary for dashboard
  Map<String, dynamic> getTeamSummary() {
    return {
      'totalMembers': _teamMembers.length,
      'leadershipCount': leadershipTeam.length,
      'recentlyAdded':
          _teamMembers
              .where(
                (member) =>
                    DateTime.now().difference(member.dateAdded).inDays <= 7,
              )
              .length,
      'roles': _teamMembers.map((member) => member.role).toSet().toList(),
    };
  }

  // Export team data
  List<Map<String, dynamic>> exportTeamData() {
    return _teamMembers.map((member) => member.toMap()).toList();
  }

  // Import team data with Supabase save
  Future<bool> importTeamData(List<Map<String, dynamic>> data) async {
    _isSaving = true;
    notifyListeners();

    try {
      // Clear existing team members first
      await clearAllTeamMembers();

      // Import each team member
      for (final memberData in data) {
        await addTeamMember(
          customName: memberData['name'],
          customRole: memberData['role'],
          customLinkedin: memberData['linkedin'] ?? memberData['linkedin_url'],
          customAvatar: memberData['avatar'] ?? memberData['avatar_url'],
        );
      }

      debugPrint('Team data imported successfully');
      return true;
    } catch (e) {
      _error = 'Error importing team data: $e';
      debugPrint('Error importing team data: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Search team members
  List<TeamMember> searchTeamMembers(String query) {
    if (query.trim().isEmpty) return _teamMembers;

    final searchQuery = query.toLowerCase().trim();
    return _teamMembers
        .where(
          (member) =>
              member.name.toLowerCase().contains(searchQuery) ||
              member.role.toLowerCase().contains(searchQuery),
        )
        .toList();
  }

  // Sort team members with automatic save
  void sortTeamMembers(String sortBy) {
    switch (sortBy.toLowerCase()) {
      case 'name':
        _teamMembers.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'role':
        _teamMembers.sort((a, b) => a.role.compareTo(b.role));
        break;
      case 'date_added':
        _teamMembers.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      default:
        // Default to name sorting
        _teamMembers.sort((a, b) => a.name.compareTo(b.name));
    }

    // Mark as dirty for any additional processing
    _markTeamMembersDirtyAndSave();
    notifyListeners();
  }

  // Refresh data from Supabase
  Future<void> refreshFromDatabase() async {
    await initialize();
  }

  // Bulk operations for efficiency
  Future<bool> addMultipleTeamMembers(
    List<Map<String, dynamic>> membersData,
  ) async {
    _isSaving = true;
    notifyListeners();

    try {
      // Prepare data for bulk insert
      final insertData =
          membersData
              .map(
                (data) => {
                  'name': data['name'],
                  'role': data['role'],
                  'linkedin_url': data['linkedin'],
                  'avatar_url':
                      data['avatar'] ?? 'https://via.placeholder.com/150',
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

      _teamMembers.addAll(newMembers);

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

  @override
  void dispose() {
    _saveTimer?.cancel(); // Clean up auto-save timer
    _removeListeners();
    _nameController.dispose();
    _roleController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }
}

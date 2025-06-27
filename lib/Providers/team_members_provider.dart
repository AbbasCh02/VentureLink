import 'package:flutter/material.dart';
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

  // Convert to Map for storage/serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'linkedin': linkedin,
      'avatar': avatar,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  // Create from Map for retrieval/deserialization
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

  // Initialize and load data from SharedPreferences
  // Replace the entire initialize() method with:
  Future<void> initialize() async {
    _isLoading = true;
    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Load team members from Supabase here
      // For now, just initialize with empty list
      _teamMembers = [];

      // Add listeners after initialization
      _addListeners();

      _dirtyFields.clear(); // Clear dirty state after loading
    } catch (e) {
      _error = 'Failed to load team members data: $e';
      debugPrint('Error loading team members data: $e');
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save team members to preferences
  // Replace the entire saveTeamMembers() method with:
  Future<bool> saveTeamMembers() async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Save team members to Supabase here
      // For now, just clear the dirty state
      _dirtyFields.remove('teamMembers');
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

  // Add a new team member with automatic save
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
      final newMember = TeamMember(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        role: role,
        linkedin: linkedin,
        avatar: customAvatar ?? 'https://via.placeholder.com/150',
        dateAdded: DateTime.now(),
      );

      _teamMembers.add(newMember);

      // Clear form controllers
      clearForm();

      // Auto-save immediately when adding team member
      _markTeamMembersDirtyAndSave();
      return true;
    }
    return false;
  }

  // Remove a team member with automatic save
  Future<bool> removeTeamMember(String id) async {
    final initialLength = _teamMembers.length;
    _teamMembers.removeWhere((member) => member.id == id);

    if (_teamMembers.length != initialLength) {
      // Auto-save immediately when removing team member
      _markTeamMembersDirtyAndSave();
      return true;
    }
    return false;
  }

  // Remove team member by index with automatic save
  Future<bool> removeTeamMemberAt(int index) async {
    if (index >= 0 && index < _teamMembers.length) {
      _teamMembers.removeAt(index);

      // Auto-save immediately when removing team member
      _markTeamMembersDirtyAndSave();
      return true;
    }
    return false;
  }

  // Update a team member with automatic save
  Future<bool> updateTeamMember(
    String id, {
    String? name,
    String? role,
    String? linkedin,
    String? avatar,
  }) async {
    final index = _teamMembers.indexWhere((member) => member.id == id);
    if (index != -1) {
      _teamMembers[index] = _teamMembers[index].copyWith(
        name: name,
        role: role,
        linkedin: linkedin,
        avatar: avatar,
      );

      // Auto-save immediately when updating team member
      _markTeamMembersDirtyAndSave();
      return true;
    }
    return false;
  }

  // Clear all team members
  // Replace clearAllTeamMembers() method with:
  Future<void> clearAllTeamMembers() async {
    _teamMembers.clear();
    _dirtyFields.clear();

    notifyListeners();

    try {
      // TODO: Clear team members from Supabase if needed
    } catch (e) {
      _error = 'Failed to clear team members data: $e';
      debugPrint('Error clearing team members data: $e');
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

  // Import team data with automatic save
  Future<bool> importTeamData(List<Map<String, dynamic>> data) async {
    try {
      _teamMembers = data.map((item) => TeamMember.fromMap(item)).toList();

      // Auto-save immediately when importing data
      _markTeamMembersDirtyAndSave();
      return true;
    } catch (e) {
      _error = 'Error importing team data: $e';
      debugPrint('Error importing team data: $e');
      return false;
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

    // Auto-save immediately when sorting
    _markTeamMembersDirtyAndSave();
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

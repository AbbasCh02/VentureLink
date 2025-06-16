// lib/Providers/team_members_provider.dart
import 'package:flutter/material.dart';

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

  // Loading and error states
  bool _isLoading = false;
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
  }

  // Getters for states
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check if specific field has unsaved changes
  bool hasUnsavedChanges(String field) => _dirtyFields.contains(field);
  bool get hasAnyUnsavedChanges => _dirtyFields.isNotEmpty;

  // Clear error method
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Initialize and setup listeners
  Future<void> initialize() async {
    _isLoading = true;
    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      // Add listeners after initialization
      _addListeners();

      _dirtyFields.clear(); // Clear dirty state after loading
    } catch (e) {
      _error = 'Failed to initialize team members data: $e';
      debugPrint('Error initializing team members data: $e');
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mock save methods (kept for API compatibility)
  Future<bool> saveTeamMembers() async {
    _dirtyFields.remove('teamMembers');
    notifyListeners();
    return true;
  }

  // Mark team members as dirty (but no actual save)
  void _markTeamMembersDirtyAndSave() {
    _dirtyFields.add('teamMembers');
    notifyListeners();
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

  // Add a new team member with immediate state update
  Future<bool> addTeamMember({
    String? customName,
    String? customRole,
    String? customLinkedin,
    String? customAvatar,
  }) async {
    final name = customName ?? _nameController.text.trim();
    final role = customRole ?? _roleController.text.trim();
    final linkedin = customLinkedin ?? _linkedinController.text.trim();
    final avatar = customAvatar ?? 'https://via.placeholder.com/150';

    if (name.isEmpty || role.isEmpty) {
      _error = 'Name and role are required';
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

    final newMember = TeamMember(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      role: role,
      linkedin: linkedin,
      avatar: avatar,
      dateAdded: DateTime.now(),
    );

    _teamMembers.add(newMember);

    // Clear form after successful addition
    clearForm();

    // Mark as changed
    _markTeamMembersDirtyAndSave();
    return true;
  }

  // Remove a team member
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

  // Update an existing team member
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
  Future<void> clearAllTeamMembers() async {
    _teamMembers.clear();
    _dirtyFields.clear();
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
    );

    if (!linkedinPattern.hasMatch(value.trim())) {
      return 'Please enter a valid LinkedIn profile URL';
    }

    return null;
  }

  // Get team members data as list of maps
  List<Map<String, dynamic>> getTeamMembersData() {
    return _teamMembers.map((member) => member.toMap()).toList();
  }

  // Import team members from data
  void importTeamMembers(List<Map<String, dynamic>> data) {
    try {
      _teamMembers =
          data.map((memberMap) => TeamMember.fromMap(memberMap)).toList();
      _dirtyFields.clear();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to import team members: $e';
      notifyListeners();
    }
  }

  // Check if team member with name exists
  bool teamMemberExists(String name) {
    return _teamMembers.any(
      (member) => member.name.toLowerCase() == name.toLowerCase(),
    );
  }

  // Get team member by ID
  TeamMember? getTeamMemberById(String id) {
    try {
      return _teamMembers.firstWhere((member) => member.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search team members by name or role
  List<TeamMember> searchTeamMembers(String query) {
    if (query.isEmpty) return teamMembers;

    final lowerQuery = query.toLowerCase();
    return _teamMembers
        .where(
          (member) =>
              member.name.toLowerCase().contains(lowerQuery) ||
              member.role.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  @override
  void dispose() {
    _removeListeners();
    _nameController.dispose();
    _roleController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }
}

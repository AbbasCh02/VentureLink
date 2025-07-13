// lib/Investor/Providers/investor_profile_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/storage_service.dart';

class InvestorProfileProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Form controllers
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _linkedinUrlController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _originController = TextEditingController();

  // Private state variables
  String? _profileImageUrl;
  File? _profileImage;
  List<String> _selectedIndustries = [];
  List<String> _selectedGeographicFocus = [];
  List<String> _selectedPreferredStages = [];
  int? _portfolioSize;
  int? _age;
  bool _isVerified = false;
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _error;
  Timer? _saveTimer;
  final Set<String> _dirtyFields = {};

  // Available options
  static const List<String> availableIndustries = [
    'Technology',
    'Healthcare',
    'Finance',
    'E-commerce',
    'Education',
    'Real Estate',
    'Manufacturing',
    'Energy',
    'Transportation',
    'Food & Beverage',
    'Entertainment',
    'Agriculture',
    'Cybersecurity',
    'Biotechnology',
    'Clean Tech',
    'SaaS',
    'Fintech',
    'AI/ML',
    'Blockchain',
    'IoT',
    'Other',
  ];

  static const List<String> availableGeographicRegions = [
    'North America',
    'South America',
    'Europe',
    'Asia',
    'Africa',
    'Oceania',
    'Middle East',
    'Global',
    'United States',
    'Canada',
    'United Kingdom',
    'Germany',
    'France',
    'China',
    'Japan',
    'India',
    'Australia',
    'Brazil',
    'Other',
  ];

  // Available investment stages list
  static const List<String> availableInvestmentStages = [
    'Pre-Seed',
    'Seed',
    'Series A',
    'Series B',
    'Series C',
    'Series D+',
    'Growth',
    'Late Stage',
    'IPO Ready',
    'Bridge',
    'Convertible',
    'Revenue Based',
  ];

  // Getters
  TextEditingController get bioController => _bioController;
  TextEditingController get linkedinUrlController => _linkedinUrlController;
  TextEditingController get fullNameController => _fullNameController;
  TextEditingController get originController => _originController;

  String? get bio => _bioController.text.isEmpty ? null : _bioController.text;
  String? get linkedinUrl =>
      _linkedinUrlController.text.isEmpty ? null : _linkedinUrlController.text;

  String? get fullName =>
      _fullNameController.text.isEmpty ? null : _fullNameController.text;
  String? get origin =>
      _originController.text.isEmpty ? null : _originController.text;
  int? get age => _age;

  List<String> get selectedIndustries => List.unmodifiable(_selectedIndustries);
  List<String> get selectedGeographicFocus =>
      List.unmodifiable(_selectedGeographicFocus);
  List<String> get selectedPreferredStages =>
      List.unmodifiable(_selectedPreferredStages);
  int? get portfolioSize => _portfolioSize;
  bool get isVerified => _isVerified;
  File? get profileImage => _profileImage;
  String? get profileImageUrl => _profileImageUrl;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  bool get hasProfileImage {
    return _profileImage != null ||
        (_profileImageUrl != null && _profileImageUrl!.isNotEmpty);
  }

  bool get hasUnsavedChanges => _dirtyFields.isNotEmpty;

  bool hasUnsavedChangesForField(String fieldName) =>
      _dirtyFields.contains(fieldName);

  // Profile completion status
  bool get isProfileComplete {
    return bio != null &&
        bio!.trim().isNotEmpty &&
        fullName != null && // NEW: Include full name in completion
        fullName!.trim().isNotEmpty &&
        _selectedIndustries.isNotEmpty &&
        _selectedGeographicFocus.isNotEmpty;
  }

  double get completionPercentage {
    int completed = 0;
    int total =
        6; // bio, full name, industries, geographic focus, profile image, age

    if (bio != null && bio!.trim().isNotEmpty) completed++;
    if (fullName != null && fullName!.trim().isNotEmpty) completed++; // NEW
    if (_age != null) completed++; // NEW
    if (_selectedIndustries.isNotEmpty) completed++;
    if (_selectedGeographicFocus.isNotEmpty) completed++;
    if (hasProfileImage) completed++;

    return (completed / total) * 100;
  }

  // Initialize provider
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    _error = null;

    try {
      await _loadInvestorProfileData();
      _isInitialized = true;
      _addListeners();

      // Listen for auth state changes
      _supabase.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        if (event == AuthChangeEvent.signedOut) {
          // User signed out, reset state
          _resetProviderState();
        }
      });
    } catch (e) {
      _error = 'Failed to initialize investor profile: $e';
      debugPrint('❌ Error initializing investor profile: $e');
      rethrow;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // Load investor profile data from database
  Future<void> _loadInvestorProfileData() async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }

    debugPrint('🔄 Loading investor profile data for user: ${currentUser.id}');

    try {
      // Temporarily remove listeners to prevent auto-save during load
      _removeListeners();

      // FIXED: Load data directly from tables instead of using RPC
      // First check if investor record exists
      final investorRecord =
          await _supabase
              .from('investors')
              .select('*') // ✅ Removed avatar_url from select
              .eq('id', currentUser.id)
              .maybeSingle();

      if (investorRecord != null) {
        _isVerified = investorRecord['is_verified'] ?? false;
        // ✅ Removed avatar_url loading from here - will be loaded from profiles
        debugPrint('✅ Investor record found');
      } else {
        debugPrint('⚠️ Creating initial investor record...');
        await _createInitialInvestorRecord(currentUser);
      }

      // Load investor profile data
      final profileData =
          await _supabase
              .from('investor_profiles')
              .select('*')
              .eq('investor_id', currentUser.id)
              .maybeSingle();

      if (profileData != null) {
        debugPrint('✅ Profile data found, loading...');

        // Load basic investor info
        _portfolioSize = profileData['portfolio_size'];

        // ✅ Load avatar_url from investor_profiles table
        _profileImageUrl = profileData['avatar_url'];

        // Load professional information
        _bioController.text = profileData['bio'] ?? '';
        _linkedinUrlController.text = profileData['linkedin_url'] ?? '';
        _fullNameController.text = profileData['full_name'] ?? '';
        _originController.text = profileData['country'] ?? '';
        _age = profileData['age'];

        // CRITICAL: Load investment preferences with proper casting
        try {
          final industriesData = profileData['industries'];
          if (industriesData is List) {
            _selectedIndustries = industriesData.cast<String>();
            debugPrint(
              '✅ Loaded ${_selectedIndustries.length} industries: $_selectedIndustries',
            );
          } else {
            _selectedIndustries = [];
            debugPrint('⚠️ No industries data found or invalid format');
          }
        } catch (e) {
          debugPrint('❌ Error loading industries: $e');
          _selectedIndustries = [];
        }

        try {
          final geographicData = profileData['geographic_focus'];
          if (geographicData is List) {
            _selectedGeographicFocus = geographicData.cast<String>();
            debugPrint(
              '✅ Loaded ${_selectedGeographicFocus.length} geographic focus: $_selectedGeographicFocus',
            );
          } else {
            _selectedGeographicFocus = [];
            debugPrint('⚠️ No geographic focus data found or invalid format');
          }
        } catch (e) {
          debugPrint('❌ Error loading geographic focus: $e');
          _selectedGeographicFocus = [];
        }

        try {
          final stagesData = profileData['preferred_stages'];
          if (stagesData is List) {
            _selectedPreferredStages = stagesData.cast<String>();
            debugPrint(
              '✅ Loaded ${_selectedPreferredStages.length} preferred stages: $_selectedPreferredStages',
            );
          } else {
            _selectedPreferredStages = [];
            debugPrint('⚠️ No preferred stages data found or invalid format');
          }
        } catch (e) {
          debugPrint('❌ Error loading preferred stages: $e');
          _selectedPreferredStages = [];
        }

        debugPrint('✅ Investor profile data loaded successfully');
        debugPrint('   - Full Name: ${fullName ?? "Not Set"}');
        debugPrint('   - Age: ${_age ?? "Not Set"}');
        debugPrint('   - Place of Residence: ${origin ?? "Not Set"}');
        debugPrint('   - Bio: ${bio != null ? "✓" : "✗"}');
      } else {
        debugPrint('⚠️ No profile data found, creating initial profile...');
        await _createInitialInvestorProfile(currentUser);
      }

      // Re-add listeners
      _addListeners();
      _dirtyFields.clear(); // Clear dirty state after loading
    } catch (e) {
      _error = 'Failed to load investor profile data: $e';
      debugPrint('❌ Error loading investor profile data: $e');
      // Re-add listeners even on error
      _addListeners();
      rethrow;
    }
  }

  // Create initial investor record
  Future<void> _createInitialInvestorRecord(User user) async {
    try {
      debugPrint('🔄 Creating initial investor record for user: ${user.id}');

      // Check if investor record already exists
      final existing =
          await _supabase
              .from('investors')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();

      if (existing != null) {
        debugPrint('✅ Investor record already exists');
        return;
      }

      // Insert into investors table
      await _supabase.from('investors').insert({
        'id': user.id,
        'email': user.email,
        'username': user.userMetadata?['username'] ?? user.email?.split('@')[0],
        'is_verified': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Initial investor record created successfully');
    } catch (e) {
      debugPrint('❌ Error creating initial investor record: $e');
      // Don't throw if it's a duplicate key error
      if (!e.toString().contains('duplicate key')) {
        rethrow;
      }
    }
  }

  // NEW: Create initial investor profile
  Future<void> _createInitialInvestorProfile(User user) async {
    try {
      debugPrint('🔄 Creating initial investor profile for user: ${user.id}');

      await _supabase.from('investor_profiles').insert({
        'investor_id': user.id,
        'bio': null,
        'linkedin_url': null,
        'full_name': null,
        'age': null,
        'country': null,
        'avatar_url': null,
        'industries': <String>[],
        'geographic_focus': <String>[],
        'preferred_stages': <String>[],
        'portfolio_size': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Initial investor profile created successfully');
    } catch (e) {
      debugPrint('❌ Error creating initial investor profile: $e');
      rethrow;
    }
  }

  // Save individual field
  Future<void> saveField(String fieldName) async {
    if (!_dirtyFields.contains(fieldName)) return;

    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      debugPrint('💾 Saving field: $fieldName');

      switch (fieldName) {
        case 'bio':
          await _saveToInvestorProfiles({'bio': bio});
          break;

        case 'linkedinUrl':
          await _saveToInvestorProfiles({'linkedin_url': linkedinUrl});
          break;

        case 'fullName': // NEW
          await _saveToInvestorProfiles({'full_name': fullName});
          break;

        case 'age': // NEW
          await _saveToInvestorProfiles({'age': _age});
          break;

        case 'origin': // NEW
          await _saveToInvestorProfiles({'country': origin});
          break;

        case 'industries':
          await _saveToInvestorProfiles({'industries': _selectedIndustries});
          break;

        case 'geographicFocus':
          await _saveToInvestorProfiles({
            'geographic_focus': _selectedGeographicFocus,
          });
          break;

        case 'preferredStages':
          await _saveToInvestorProfiles({
            'preferred_stages': _selectedPreferredStages,
          });
          break;

        case 'portfolioSize':
          await _saveToInvestorProfiles({'portfolio_size': _portfolioSize});
          break;

        case 'profileImage':
          await _saveProfileImage();
          break;
      }

      _dirtyFields.remove(fieldName);
      notifyListeners();
      debugPrint('✅ Field saved successfully: $fieldName');
    } catch (e) {
      debugPrint('❌ Error saving field $fieldName: $e');
      _error = 'Failed to save $fieldName: $e';
      notifyListeners();
    }
  }

  // Save to investor_profiles table
  Future<void> _saveToInvestorProfiles(Map<String, dynamic> data) async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    data['updated_at'] = DateTime.now().toIso8601String();

    await _supabase
        .from('investor_profiles')
        .update(data)
        .eq('investor_id', currentUser.id);
  }

  // Save to investor_companies table

  // Save profile image
  Future<void> _saveProfileImage() async {
    if (_profileImage == null) return;

    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      debugPrint('🔄 Uploading profile image...');

      final String imageUrl = await StorageService.uploadAvatar(
        file: _profileImage!,
        userId: currentUser.id,
      );

      _profileImageUrl = imageUrl;
      await _saveToInvestorProfiles({
        'avatar_url': imageUrl,
      }); // ✅ Correct table
      debugPrint('✅ Profile image uploaded and saved');
    } catch (e) {
      debugPrint('❌ Error saving profile image: $e');
      rethrow;
    }
  }

  // Public update methods
  void updateBio(String value) {
    _bioController.text = value;
    _onFieldChanged('bio');
  }

  void updateLinkedinUrl(String value) {
    _linkedinUrlController.text = value;
    _onFieldChanged('linkedinUrl');
  }

  void updateFullName(String value) {
    _fullNameController.text = value;
    _onFieldChanged('fullName');
  }

  void updateAge(int? value) {
    _age = value;
    _dirtyFields.add('age');
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () {
      saveField('age');
    });
  }

  void updateorigin(String value) {
    _originController.text = value;
    _onFieldChanged('origin');
  }

  void updatePortfolioSize(int? size) {
    _portfolioSize = size;
    _dirtyFields.add('portfolioSize');
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () {
      saveField('portfolioSize');
    });
  }

  void updateProfileImage(File? image) {
    _profileImage = image;
    _dirtyFields.add('profileImage');
    notifyListeners();
    // Save immediately for profile image
    saveField('profileImage');
  }

  // Method to update selected industries
  void updateSelectedIndustries(List<String> industries) {
    _selectedIndustries = List.from(industries);
    _dirtyFields.add('industries');
    notifyListeners();
  }

  // Method to update selected geographic focus
  void updateSelectedGeographicFocus(List<String> geographicFocus) {
    _selectedGeographicFocus = List.from(geographicFocus);
    _dirtyFields.add('geographicFocus');
    notifyListeners();
  }

  // Method to add a single industry
  void addIndustry(String industry) {
    if (!_selectedIndustries.contains(industry)) {
      _selectedIndustries.add(industry);
      _dirtyFields.add('industries');
      notifyListeners();
    }
  }

  // Method to remove a single industry
  void removeIndustry(String industry) {
    if (_selectedIndustries.remove(industry)) {
      _dirtyFields.add('industries');
      notifyListeners();
    }
  }

  // Method to add a single geographic focus
  void addGeographicFocus(String region) {
    if (!_selectedGeographicFocus.contains(region)) {
      _selectedGeographicFocus.add(region);
      _dirtyFields.add('geographicFocus');
      notifyListeners();
    }
  }

  // Method to remove a single geographic focus
  void removeGeographicFocus(String region) {
    if (_selectedGeographicFocus.remove(region)) {
      _dirtyFields.add('geographicFocus');
      notifyListeners();
    }
  }

  // Method to clear all industries
  void clearAllIndustries() {
    if (_selectedIndustries.isNotEmpty) {
      _selectedIndustries.clear();
      _dirtyFields.add('industries');
      notifyListeners();
    }
  }

  // Method to clear all geographic focus
  void clearAllGeographicFocus() {
    if (_selectedGeographicFocus.isNotEmpty) {
      _selectedGeographicFocus.clear();
      _dirtyFields.add('geographicFocus');
      notifyListeners();
    }
  }

  // Methods to update preferred stages
  void updateSelectedPreferredStages(List<String> stages) {
    _selectedPreferredStages = List.from(stages);
    _dirtyFields.add('preferredStages');
    notifyListeners();
  }

  void addPreferredStage(String stage) {
    if (!_selectedPreferredStages.contains(stage)) {
      _selectedPreferredStages.add(stage);
      _dirtyFields.add('preferredStages');
      notifyListeners();
    }
  }

  void removePreferredStage(String stage) {
    if (_selectedPreferredStages.remove(stage)) {
      _dirtyFields.add('preferredStages');
      notifyListeners();
    }
  }

  void clearAllPreferredStages() {
    if (_selectedPreferredStages.isNotEmpty) {
      _selectedPreferredStages.clear();
      _dirtyFields.add('preferredStages');
      notifyListeners();
    }
  }

  bool isPreferredStageSelected(String stage) {
    return _selectedPreferredStages.contains(stage);
  }

  // Method to get industry selection status
  bool isIndustrySelected(String industry) {
    return _selectedIndustries.contains(industry);
  }

  // Method to get geographic focus selection status
  bool isGeographicFocusSelected(String region) {
    return _selectedGeographicFocus.contains(region);
  }

  // Validation methods
  String? validateBio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please provide a brief bio about yourself';
    }
    if (value.trim().length < 20) {
      return 'Please provide a more detailed bio (at least 20 characters)';
    }
    return null;
  }

  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    return null;
  }

  String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Age is optional
    }

    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }
    if (age < 18 || age > 120) {
      return 'Age must be between 18 and 120';
    }
    return null;
  }

  String? validateorigin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    if (value.trim().length < 2) {
      return 'Place of residence must be at least 2 characters';
    }
    return null;
  }

  String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // URLs are optional
    }

    final trimmedValue = value.trim();

    // Basic URL validation
    final Uri? uri = Uri.tryParse(trimmedValue);

    if (uri == null) {
      return 'Please enter a valid URL';
    }

    // Check for valid scheme (http or https only)
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'URL must start with http:// or https://';
    }

    // Check if host exists and is not empty
    if (uri.host.isEmpty) {
      return 'Please enter a valid URL with a domain';
    }

    // Additional validation: check for valid domain format
    if (!RegExp(
          r'^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.([a-zA-Z]{2,}|[a-zA-Z]{2,}\.[a-zA-Z]{2,})$',
        ).hasMatch(uri.host) &&
        uri.host != 'localhost') {
      return 'Please enter a valid domain name';
    }

    return null;
  }

  // Save all profile data
  Future<void> saveProfile() async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      debugPrint('💾 Saving complete investor profile...');

      // Save all dirty fields
      for (String field in _dirtyFields.toList()) {
        await saveField(field);
      }

      debugPrint('✅ Complete investor profile saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving investor profile: $e');
      _error = 'Failed to save profile: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Field change handlers
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

  void _addListeners() {
    _bioController.addListener(() => _onFieldChanged('bio'));
    _linkedinUrlController.addListener(() => _onFieldChanged('linkedinUrl'));
    _fullNameController.addListener(() => _onFieldChanged('fullName')); // NEW
    _originController.addListener(() => _onFieldChanged('origin')); // NEW
  }

  void _removeListeners() {
    _bioController.removeListener(() => _onFieldChanged('bio'));
    _linkedinUrlController.removeListener(() => _onFieldChanged('linkedinUrl'));
    _fullNameController.removeListener(
      () => _onFieldChanged('fullName'),
    ); // NEW
    _originController.removeListener(() => _onFieldChanged('origin'));
  }

  // Reset provider state
  void _resetProviderState() {
    _isInitialized = false;
    _removeListeners();

    _bioController.clear();
    _linkedinUrlController.clear();
    _profileImage = null;
    _profileImageUrl = null;
    _fullNameController.clear(); // NEW
    _originController.clear(); // NEW
    _age = null; // NEW
    _selectedIndustries.clear();
    _selectedGeographicFocus.clear();
    _selectedPreferredStages.clear();
    _portfolioSize = null;
    _isVerified = false;
    _dirtyFields.clear();
    _error = null;

    notifyListeners();
    _addListeners();
  }

  // Clear all data
  Future<void> clearAllData() async {
    _resetProviderState();
  }

  // Reset for new user
  Future<void> resetForNewUser() async {
    _resetProviderState();
    await initialize();
  }

  @override
  void dispose() {
    _removeListeners();
    _saveTimer?.cancel();
    _bioController.dispose();
    _fullNameController.dispose(); // NEW
    _originController.dispose();
    _linkedinUrlController.dispose();
    super.dispose();
  }
}

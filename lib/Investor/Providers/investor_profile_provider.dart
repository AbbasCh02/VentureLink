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
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkedinUrlController = TextEditingController();
  final TextEditingController _websiteUrlController = TextEditingController();

  // Private state variables
  String? _profileImageUrl;
  File? _profileImage;
  List<String> _selectedIndustries = [];
  List<String> _selectedGeographicFocus = [];
  List<String> _selectedPreferredStages = [];
  int? _portfolioSize;
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
  TextEditingController get companyNameController => _companyNameController;
  TextEditingController get titleController => _titleController;
  TextEditingController get linkedinUrlController => _linkedinUrlController;
  TextEditingController get websiteUrlController => _websiteUrlController;

  String? get bio => _bioController.text.isEmpty ? null : _bioController.text;
  String? get companyName =>
      _companyNameController.text.isEmpty ? null : _companyNameController.text;
  String? get title =>
      _titleController.text.isEmpty ? null : _titleController.text;
  String? get linkedinUrl =>
      _linkedinUrlController.text.isEmpty ? null : _linkedinUrlController.text;
  String? get websiteUrl =>
      _websiteUrlController.text.isEmpty ? null : _websiteUrlController.text;

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
        companyName != null &&
        title != null &&
        _selectedIndustries.isNotEmpty &&
        _selectedGeographicFocus.isNotEmpty;
  }

  double get completionPercentage {
    int completed = 0;
    int total =
        6; // bio, company, title, industries, geographic focus, profile image

    if (bio != null) completed++;
    if (companyName != null) completed++;
    if (title != null) completed++;
    if (_selectedIndustries.isNotEmpty) completed++;
    if (_selectedGeographicFocus.isNotEmpty) completed++;
    if (hasProfileImage) completed++;

    return completed / total;
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

      // Use the helper function to get complete investor profile
      final response =
          await _supabase
              .rpc(
                'get_complete_investor_profile',
                params: {'investor_user_id': currentUser.id},
              )
              .maybeSingle();

      if (response != null) {
        // Load basic investor info
        _portfolioSize = response['portfolio_size'];
        _isVerified = response['is_verified'] ?? false;
        _profileImageUrl = response['avatar_url'];

        // Load professional information
        _companyNameController.text = response['company_name'] ?? '';
        _titleController.text = response['title'] ?? '';
        _bioController.text = response['bio'] ?? '';
        _linkedinUrlController.text = response['linkedin_url'] ?? '';
        _websiteUrlController.text = response['website_url'] ?? '';

        // Load investment preferences
        final List<dynamic>? industries = response['industries'];
        _selectedIndustries = industries?.cast<String>() ?? [];

        final List<dynamic>? geographicFocus = response['geographic_focus'];
        _selectedGeographicFocus = geographicFocus?.cast<String>() ?? [];

        final List<dynamic>? preferredStages = response['preferred_stages'];
        _selectedPreferredStages = preferredStages?.cast<String>() ?? [];

        debugPrint('✅ Investor profile data loaded successfully');
        debugPrint('   - Company: ${companyName ?? "Not Set"}');
        debugPrint('   - Title: ${title ?? "Not Set"}');
        debugPrint('   - Bio: ${bio != null ? "✓" : "✗"}');
        debugPrint('   - Industries: ${_selectedIndustries.length}');
        debugPrint('   - Geographic Focus: ${_selectedGeographicFocus.length}');
        debugPrint('   - Portfolio Size: ${_portfolioSize ?? "Not Set"}');
        debugPrint(
          '   - Profile Image: ${_profileImageUrl != null ? "✓" : "✗"}',
        );
      } else {
        debugPrint(
          'No investor profile data found for user: ${currentUser.id}',
        );
        // Create initial investor record if it doesn't exist
        await _createInitialInvestorRecord(currentUser);
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

      // Insert into investors table
      await _supabase.from('investors').insert({
        'id': user.id,
        'email': user.email,
        'username': user.userMetadata?['username'] ?? user.email?.split('@')[0],
        'is_verified': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Create investor profile using the helper function
      await _supabase.rpc(
        'ensure_investor_profile',
        params: {'investor_user_id': user.id},
      );

      debugPrint('✅ Initial investor record created successfully');
    } catch (e) {
      debugPrint('❌ Error creating initial investor record: $e');
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
        case 'companyName':
          await _saveToInvestorCompanies({'company_name': companyName});
          break;
        case 'title':
          await _saveToInvestorCompanies({'investor_title_in_compnay': title});
          break;
        case 'linkedinUrl':
          await _saveToInvestorProfiles({'linkedin_url': linkedinUrl});
          break;
        case 'websiteUrl':
          await _saveToInvestorCompanies({'website_url': websiteUrl});
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

  // Save to investors table
  Future<void> _saveToInvestors(Map<String, dynamic> data) async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    data['updated_at'] = DateTime.now().toIso8601String();

    await _supabase.from('investors').update(data).eq('id', currentUser.id);
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
  Future<void> _saveToInvestorCompanies(Map<String, dynamic> data) async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    data['updated_at'] = DateTime.now().toIso8601String();

    // First get the investor_profile_id
    final profile =
        await _supabase
            .from('investor_profiles')
            .select('id')
            .eq('investor_id', currentUser.id)
            .single();

    await _supabase.from('investor_companies').upsert({
      'investor_id': profile['id'],
      ...data,
    });
  }

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
      await _saveToInvestors({'avatar_url': imageUrl});
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

  void updateCompanyName(String value) {
    _companyNameController.text = value;
    _onFieldChanged('companyName');
  }

  void updateTitle(String value) {
    _titleController.text = value;
    _onFieldChanged('title');
  }

  void updateLinkedinUrl(String value) {
    _linkedinUrlController.text = value;
    _onFieldChanged('linkedinUrl');
  }

  void updateWebsiteUrl(String value) {
    _websiteUrlController.text = value;
    _onFieldChanged('websiteUrl');
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

  String? validateCompanyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your company/firm name';
    }
    if (value.trim().length < 2) {
      return 'Company name must be at least 2 characters';
    }
    return null;
  }

  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your job title';
    }
    if (value.trim().length < 2) {
      return 'Title must be at least 2 characters';
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
    _companyNameController.addListener(() => _onFieldChanged('companyName'));
    _titleController.addListener(() => _onFieldChanged('title'));
    _linkedinUrlController.addListener(() => _onFieldChanged('linkedinUrl'));
    _websiteUrlController.addListener(() => _onFieldChanged('websiteUrl'));
  }

  void _removeListeners() {
    _bioController.removeListener(() => _onFieldChanged('bio'));
    _companyNameController.removeListener(() => _onFieldChanged('companyName'));
    _titleController.removeListener(() => _onFieldChanged('title'));
    _linkedinUrlController.removeListener(() => _onFieldChanged('linkedinUrl'));
    _websiteUrlController.removeListener(() => _onFieldChanged('websiteUrl'));
  }

  // Reset provider state
  void _resetProviderState() {
    _isInitialized = false;
    _removeListeners();

    _bioController.clear();
    _companyNameController.clear();
    _titleController.clear();
    _linkedinUrlController.clear();
    _websiteUrlController.clear();
    _profileImage = null;
    _profileImageUrl = null;
    _selectedIndustries.clear();
    _selectedGeographicFocus.clear();
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
    _companyNameController.dispose();
    _titleController.dispose();
    _linkedinUrlController.dispose();
    _websiteUrlController.dispose();
    super.dispose();
  }
}

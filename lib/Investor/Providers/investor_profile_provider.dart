// lib/Investor/Providers/investor_profile_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/storage_service.dart';

/**
 * investor_profile_provider.dart
 * 
 * Implements a comprehensive state management provider for investor profiles with 
 * Supabase backend integration, form handling, and data validation.
 * 
 * Features:
 * - Complete investor profile data management
 * - Form state tracking with auto-save functionality
 * - Profile image upload and storage
 * - Multi-select preferences (industries, regions, stages)
 * - Profile completion tracking
 * - Form validation
 * - Database persistence with error handling
 * - User authentication integration
 */

/**
 * InvestorProfileProvider - Change notifier provider for managing investor profile data.
 * Handles state management, data persistence, and form validation.
 */
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

  /**
   * Available industry options for selection.
   */
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

  /**
   * Available geographic region options for selection.
   */
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

  /**
   * Available investment stage options for selection.
   */
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

  /**
   * Provides access to the bio text controller.
   * 
   * @return Text controller for bio
   */
  TextEditingController get bioController => _bioController;

  /**
   * Provides access to the LinkedIn URL text controller.
   * 
   * @return Text controller for LinkedIn URL
   */
  TextEditingController get linkedinUrlController => _linkedinUrlController;

  /**
   * Provides access to the full name text controller.
   * 
   * @return Text controller for full name
   */
  TextEditingController get fullNameController => _fullNameController;

  /**
   * Provides access to the origin/country text controller.
   * 
   * @return Text controller for origin/country
   */
  TextEditingController get originController => _originController;

  /**
   * Returns the investor's professional bio text.
   * 
   * @return Bio text or null if empty
   */
  String? get bio => _bioController.text.isEmpty ? null : _bioController.text;

  /**
   * Returns the investor's LinkedIn profile URL.
   * 
   * @return LinkedIn URL or null if empty
   */
  String? get linkedinUrl =>
      _linkedinUrlController.text.isEmpty ? null : _linkedinUrlController.text;

  /**
   * Returns the investor's full name.
   * 
   * @return Full name or null if empty
   */
  String? get fullName =>
      _fullNameController.text.isEmpty ? null : _fullNameController.text;

  /**
   * Returns the investor's place of residence/origin.
   * 
   * @return Origin or null if empty
   */
  String? get origin =>
      _originController.text.isEmpty ? null : _originController.text;

  /**
   * Returns the investor's age.
   * 
   * @return Age or null if not set
   */
  int? get age => _age;

  /**
   * Provides access to the selected industries list.
   * 
   * @return Unmodifiable list of selected industries
   */
  List<String> get selectedIndustries => List.unmodifiable(_selectedIndustries);

  /**
   * Provides access to the selected geographic focus regions.
   * 
   * @return Unmodifiable list of selected regions
   */
  List<String> get selectedGeographicFocus =>
      List.unmodifiable(_selectedGeographicFocus);

  /**
   * Provides access to the selected preferred investment stages.
   * 
   * @return Unmodifiable list of selected stages
   */
  List<String> get selectedPreferredStages =>
      List.unmodifiable(_selectedPreferredStages);

  /**
   * Returns the investor's portfolio size.
   * 
   * @return Portfolio size or null if not set
   */
  int? get portfolioSize => _portfolioSize;

  /**
   * Indicates whether the investor is verified.
   * 
   * @return Verification status
   */
  bool get isVerified => _isVerified;

  /**
   * Provides access to the profile image file (if newly selected).
   * 
   * @return Profile image file or null
   */
  File? get profileImage => _profileImage;

  /**
   * Provides access to the profile image URL (if previously saved).
   * 
   * @return Profile image URL or null
   */
  String? get profileImageUrl => _profileImageUrl;

  /**
   * Indicates whether the provider has been initialized.
   * 
   * @return Initialization state
   */
  bool get isInitialized => _isInitialized;

  /**
   * Provides the latest error message if any.
   * 
   * @return Error message or null
   */
  String? get error => _error;

  /**
   * Determines if the investor has a profile image set.
   * 
   * @return True if either a new image is selected or a saved image URL exists
   */
  bool get hasProfileImage {
    return _profileImage != null ||
        (_profileImageUrl != null && _profileImageUrl!.isNotEmpty);
  }

  /**
   * Indicates whether there are any unsaved changes.
   * 
   * @return True if there are unsaved changes
   */
  bool get hasUnsavedChanges => _dirtyFields.isNotEmpty;

  /**
   * Checks if a specific field has unsaved changes.
   * 
   * @param fieldName The field name to check
   * @return True if the field has unsaved changes
   */
  bool hasUnsavedChangesForField(String fieldName) =>
      _dirtyFields.contains(fieldName);

  /**
   * Determines if the investor profile is complete.
   * A complete profile requires bio, full name, industries, and geographic focus.
   * 
   * @return True if profile is complete
   */
  bool get isProfileComplete {
    return bio != null &&
        bio!.trim().isNotEmpty &&
        fullName != null &&
        fullName!.trim().isNotEmpty &&
        _selectedIndustries.isNotEmpty &&
        _selectedGeographicFocus.isNotEmpty;
  }

  /**
   * Calculates the profile completion percentage.
   * 
   * @return Percentage (0-100) of profile completion
   */
  double get completionPercentage {
    int completed = 0;
    int total =
        6; // bio, full name, industries, geographic focus, profile image, age

    if (bio != null && bio!.trim().isNotEmpty) completed++;
    if (fullName != null && fullName!.trim().isNotEmpty) completed++;
    if (_age != null) completed++;
    if (_selectedIndustries.isNotEmpty) completed++;
    if (_selectedGeographicFocus.isNotEmpty) completed++;
    if (hasProfileImage) completed++;

    return (completed / total) * 100;
  }

  /**
   * Initializes the provider with user data.
   * Loads profile from database and sets up listeners.
   */
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

  /**
   * Loads investor profile data from the database.
   * Creates initial records if they don't exist.
   */
  Future<void> _loadInvestorProfileData() async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }

    debugPrint('🔄 Loading investor profile data for user: ${currentUser.id}');

    try {
      // Temporarily remove listeners to prevent auto-save during load
      _removeListeners();

      // First check if investor record exists
      final investorRecord =
          await _supabase
              .from('investors')
              .select('*')
              .eq('id', currentUser.id)
              .maybeSingle();

      if (investorRecord != null) {
        _isVerified = investorRecord['is_verified'] ?? false;
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

        // Load avatar_url from investor_profiles table
        _profileImageUrl = profileData['avatar_url'];

        // Load professional information
        _bioController.text = profileData['bio'] ?? '';
        _linkedinUrlController.text = profileData['linkedin_url'] ?? '';
        _fullNameController.text = profileData['full_name'] ?? '';
        _originController.text = profileData['country'] ?? '';
        _age = profileData['age'];

        // Load investment preferences with proper casting
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

  /**
   * Creates an initial investor record in the database.
   * 
   * @param user The authenticated user
   */
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

  /**
   * Creates an initial investor profile record in the database.
   * 
   * @param user The authenticated user
   */
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

  /**
   * Saves a specific field to the database.
   * Only saves if the field is marked as dirty.
   * 
   * @param fieldName The name of the field to save
   */
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

        case 'fullName':
          await _saveToInvestorProfiles({'full_name': fullName});
          break;

        case 'age':
          await _saveToInvestorProfiles({'age': _age});
          break;

        case 'origin':
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

  /**
   * Saves data to the investor_profiles table.
   * 
   * @param data Map of field names to values to save
   */
  Future<void> _saveToInvestorProfiles(Map<String, dynamic> data) async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    data['updated_at'] = DateTime.now().toIso8601String();

    await _supabase
        .from('investor_profiles')
        .update(data)
        .eq('investor_id', currentUser.id);
  }

  /**
   * Uploads and saves the profile image.
   * Uses StorageService to handle the upload.
   */
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
      await _saveToInvestorProfiles({'avatar_url': imageUrl});
      debugPrint('✅ Profile image uploaded and saved');
    } catch (e) {
      debugPrint('❌ Error saving profile image: $e');
      rethrow;
    }
  }

  /**
   * Updates the investor's bio.
   * 
   * @param value The new bio text
   */
  void updateBio(String value) {
    _bioController.text = value;
    _onFieldChanged('bio');
  }

  /**
   * Updates the investor's LinkedIn URL.
   * 
   * @param value The new LinkedIn URL
   */
  void updateLinkedinUrl(String value) {
    _linkedinUrlController.text = value;
    _onFieldChanged('linkedinUrl');
  }

  /**
   * Updates the investor's full name.
   * 
   * @param value The new full name
   */
  void updateFullName(String value) {
    _fullNameController.text = value;
    _onFieldChanged('fullName');
  }

  /**
   * Updates the investor's age.
   * Triggers auto-save after a delay.
   * 
   * @param value The new age
   */
  void updateAge(int? value) {
    _age = value;
    _dirtyFields.add('age');
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () {
      saveField('age');
    });
  }

  /**
   * Updates the investor's place of origin/residence.
   * 
   * @param value The new origin/country
   */
  void updateorigin(String value) {
    _originController.text = value;
    _onFieldChanged('origin');
  }

  /**
   * Updates the investor's portfolio size.
   * Triggers auto-save after a delay.
   * 
   * @param size The new portfolio size
   */
  void updatePortfolioSize(int? size) {
    _portfolioSize = size;
    _dirtyFields.add('portfolioSize');
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () {
      saveField('portfolioSize');
    });
  }

  /**
   * Updates the investor's profile image.
   * Triggers immediate save.
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

  /**
   * Updates the list of selected industries.
   * 
   * @param industries The new list of industries
   */
  void updateSelectedIndustries(List<String> industries) {
    _selectedIndustries = List.from(industries);
    _dirtyFields.add('industries');
    notifyListeners();
  }

  /**
   * Updates the list of selected geographic focus regions.
   * 
   * @param geographicFocus The new list of regions
   */
  void updateSelectedGeographicFocus(List<String> geographicFocus) {
    _selectedGeographicFocus = List.from(geographicFocus);
    _dirtyFields.add('geographicFocus');
    notifyListeners();
  }

  /**
   * Adds a single industry to the selected industries list.
   * 
   * @param industry The industry to add
   */
  void addIndustry(String industry) {
    if (!_selectedIndustries.contains(industry)) {
      _selectedIndustries.add(industry);
      _dirtyFields.add('industries');
      notifyListeners();
    }
  }

  /**
   * Removes a single industry from the selected industries list.
   * 
   * @param industry The industry to remove
   */
  void removeIndustry(String industry) {
    if (_selectedIndustries.remove(industry)) {
      _dirtyFields.add('industries');
      notifyListeners();
    }
  }

  /**
   * Adds a single geographic region to the selected focus list.
   * 
   * @param region The region to add
   */
  void addGeographicFocus(String region) {
    if (!_selectedGeographicFocus.contains(region)) {
      _selectedGeographicFocus.add(region);
      _dirtyFields.add('geographicFocus');
      notifyListeners();
    }
  }

  /**
   * Removes a single geographic region from the selected focus list.
   * 
   * @param region The region to remove
   */
  void removeGeographicFocus(String region) {
    if (_selectedGeographicFocus.remove(region)) {
      _dirtyFields.add('geographicFocus');
      notifyListeners();
    }
  }

  /**
   * Clears all selected industries.
   */
  void clearAllIndustries() {
    if (_selectedIndustries.isNotEmpty) {
      _selectedIndustries.clear();
      _dirtyFields.add('industries');
      notifyListeners();
    }
  }

  /**
   * Clears all selected geographic focus regions.
   */
  void clearAllGeographicFocus() {
    if (_selectedGeographicFocus.isNotEmpty) {
      _selectedGeographicFocus.clear();
      _dirtyFields.add('geographicFocus');
      notifyListeners();
    }
  }

  /**
   * Updates the list of selected preferred investment stages.
   * 
   * @param stages The new list of stages
   */
  void updateSelectedPreferredStages(List<String> stages) {
    _selectedPreferredStages = List.from(stages);
    _dirtyFields.add('preferredStages');
    notifyListeners();
  }

  /**
   * Adds a single investment stage to the selected stages list.
   * 
   * @param stage The stage to add
   */
  void addPreferredStage(String stage) {
    if (!_selectedPreferredStages.contains(stage)) {
      _selectedPreferredStages.add(stage);
      _dirtyFields.add('preferredStages');
      notifyListeners();
    }
  }

  /**
   * Removes a single investment stage from the selected stages list.
   * 
   * @param stage The stage to remove
   */
  void removePreferredStage(String stage) {
    if (_selectedPreferredStages.remove(stage)) {
      _dirtyFields.add('preferredStages');
      notifyListeners();
    }
  }

  /**
   * Clears all selected preferred investment stages.
   */
  void clearAllPreferredStages() {
    if (_selectedPreferredStages.isNotEmpty) {
      _selectedPreferredStages.clear();
      _dirtyFields.add('preferredStages');
      notifyListeners();
    }
  }

  /**
   * Checks if a particular investment stage is selected.
   * 
   * @param stage The stage to check
   * @return True if the stage is selected
   */
  bool isPreferredStageSelected(String stage) {
    return _selectedPreferredStages.contains(stage);
  }

  /**
   * Checks if a particular industry is selected.
   * 
   * @param industry The industry to check
   * @return True if the industry is selected
   */
  bool isIndustrySelected(String industry) {
    return _selectedIndustries.contains(industry);
  }

  /**
   * Checks if a particular geographic region is selected.
   * 
   * @param region The region to check
   * @return True if the region is selected
   */
  bool isGeographicFocusSelected(String region) {
    return _selectedGeographicFocus.contains(region);
  }

  /**
   * Validates the bio field.
   * 
   * @param value The bio text to validate
   * @return Error message or null if valid
   */
  String? validateBio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please provide a brief bio about yourself';
    }
    if (value.trim().length < 20) {
      return 'Please provide a more detailed bio (at least 20 characters)';
    }
    return null;
  }

  /**
   * Validates the full name field.
   * 
   * @param value The full name to validate
   * @return Error message or null if valid
   */
  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    return null;
  }

  /**
   * Validates the age field.
   * 
   * @param value The age string to validate
   * @return Error message or null if valid
   */
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

  /**
   * Validates the origin/country field.
   * 
   * @param value The origin to validate
   * @return Error message or null if valid
   */
  String? validateorigin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    if (value.trim().length < 2) {
      return 'Place of residence must be at least 2 characters';
    }
    return null;
  }

  /**
   * Validates a URL field.
   * 
   * @param value The URL to validate
   * @return Error message or null if valid
   */
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

  /**
   * Saves all dirty fields in the profile.
   * Used for bulk save operations.
   */
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

  /**
   * Handles field changes by marking fields as dirty and scheduling auto-save.
   * 
   * @param fieldName The field that changed
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

  /**
   * Sets up listeners for text field changes.
   */
  void _addListeners() {
    _bioController.addListener(() => _onFieldChanged('bio'));
    _linkedinUrlController.addListener(() => _onFieldChanged('linkedinUrl'));
    _fullNameController.addListener(() => _onFieldChanged('fullName'));
    _originController.addListener(() => _onFieldChanged('origin'));
  }

  /**
   * Removes listeners for text field changes.
   */
  void _removeListeners() {
    _bioController.removeListener(() => _onFieldChanged('bio'));
    _linkedinUrlController.removeListener(() => _onFieldChanged('linkedinUrl'));
    _fullNameController.removeListener(() => _onFieldChanged('fullName'));
    _originController.removeListener(() => _onFieldChanged('origin'));
  }

  /**
   * Resets the provider state.
   * Clears all data and form fields.
   */
  void _resetProviderState() {
    _isInitialized = false;
    _removeListeners();

    _bioController.clear();
    _linkedinUrlController.clear();
    _profileImage = null;
    _profileImageUrl = null;
    _fullNameController.clear();
    _originController.clear();
    _age = null;
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

  /**
   * Clears all profile data.
   */
  Future<void> clearAllData() async {
    _resetProviderState();
  }

  /**
   * Resets provider for a new user.
   * Clears state and reinitializes.
   */
  Future<void> resetForNewUser() async {
    _resetProviderState();
    await initialize();
  }

  /**
   * Cleans up resources when the provider is disposed.
   */
  @override
  void dispose() {
    _removeListeners();
    _saveTimer?.cancel();
    _bioController.dispose();
    _fullNameController.dispose();
    _originController.dispose();
    _linkedinUrlController.dispose();
    super.dispose();
  }
}

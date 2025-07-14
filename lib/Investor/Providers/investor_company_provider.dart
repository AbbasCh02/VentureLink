// lib/Investor/Providers/investor_company_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

/**
 * investor_company_provider.dart
 * 
 * Implements a data model and state management provider for investor company 
 * information, handling CRUD operations with Supabase backend integration.
 * 
 * Features:
 * - Company data model with serialization
 * - Supabase database integration
 * - Form management with validation
 * - Real-time form state tracking
 * - User authentication state handling
 * - Data persistence with error handling
 * - Multi-user isolation and security checks
 */

/**
 * InvestorCompany - Data model representing a company associated with an investor.
 * Includes serialization methods for database operations.
 */
class InvestorCompany {
  final String id;
  final String companyName;
  final String title;
  final String website;
  final DateTime dateAdded;

  /**
   * Constructs an InvestorCompany with required fields.
   * 
   * @param id Unique identifier for the company
   * @param companyName Name of the company
   * @param title Investor's title or position in the company
   * @param website Optional website URL
   * @param dateAdded Date when the company was added
   */
  InvestorCompany({
    required this.id,
    required this.companyName,
    required this.title,
    this.website = '',
    required this.dateAdded,
  });

  /**
   * Creates an InvestorCompany instance from a Supabase database map.
   * 
   * @param map The database record as a map
   * @return A new InvestorCompany instance
   */
  factory InvestorCompany.fromSupabaseMap(Map<String, dynamic> map) {
    return InvestorCompany(
      id: map['id']?.toString() ?? '',
      companyName: map['company_name'] ?? '',
      title: map['investor_title_in_company'] ?? '',
      website: map['website_url'] ?? '',
      dateAdded: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /**
   * Converts the company object to a map for database operations.
   * 
   * @return A map representation of the company
   */
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'investor_title_in_company': title,
      'website_url': website,
      'created_at': dateAdded.toIso8601String(),
    };
  }

  /**
   * Creates a copy of this company with optional field updates.
   * 
   * @param id Optional new ID
   * @param companyName Optional new company name
   * @param title Optional new title
   * @param website Optional new website
   * @param dateAdded Optional new date
   * @return A new InvestorCompany with updated fields
   */
  InvestorCompany copyWith({
    String? id,
    String? companyName,
    String? title,
    String? website,
    DateTime? dateAdded,
  }) {
    return InvestorCompany(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      title: title ?? this.title,
      website: website ?? this.website,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }
}

/**
 * InvestorCompaniesProvider - Change notifier provider for managing investor companies.
 * Handles state management, data persistence, and form validation.
 */
class InvestorCompaniesProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Form controllers
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  // Companies list
  final List<InvestorCompany> _companies = [];

  // Auto-save timer
  Timer? _saveTimer;

  // Loading and error states
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  bool _isInitialized = false;
  final Set<String> _dirtyFields = {};

  // Track current user to detect user switches
  String? _currentUserId;
  StreamSubscription<AuthState>? _authSubscription;

  /**
   * Provides access to the unmodifiable list of companies.
   * 
   * @return An unmodifiable list of InvestorCompany objects
   */
  List<InvestorCompany> get companies => List.unmodifiable(_companies);

  /**
   * Returns the total count of companies.
   * 
   * @return Number of companies
   */
  int get companiesCount => _companies.length;

  /**
   * Indicates whether there are any companies.
   * 
   * @return True if companies exist, false otherwise
   */
  bool get hasCompanies => _companies.isNotEmpty;

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
   * Provides access to the company name form controller.
   * 
   * @return Text controller for company name
   */
  TextEditingController get companyNameController => _companyNameController;

  /**
   * Provides access to the title form controller.
   * 
   * @return Text controller for title
   */
  TextEditingController get titleController => _titleController;

  /**
   * Provides access to the website form controller.
   * 
   * @return Text controller for website
   */
  TextEditingController get websiteController => _websiteController;

  /**
   * Determines if the form has valid required fields.
   * 
   * @return Form validity state
   */
  bool get isFormValid =>
      _companyNameController.text.trim().isNotEmpty &&
      _titleController.text.trim().isNotEmpty;

  /**
   * Indicates whether there are any unsaved changes.
   * 
   * @return True if there are unsaved changes
   */
  bool get hasAnyUnsavedChanges => _dirtyFields.isNotEmpty;

  /**
   * Calculates the completion percentage for companies setup.
   * 
   * @return Percentage (0-100) of company setup completion
   */
  double get completionPercentage {
    if (_companies.isEmpty) return 0.0;
    if (_companies.length >= 2) return 100.0;
    return (_companies.length / 2) * 100;
  }

  /**
   * Filters companies to return only current ones (determined by title).
   * 
   * @return A list of current companies
   */
  List<InvestorCompany> get currentCompanies {
    return _companies
        .where(
          (company) =>
              company.title.toLowerCase().contains('ceo') ||
              company.title.toLowerCase().contains('founder') ||
              company.title.toLowerCase().contains('managing') ||
              company.title.toLowerCase().contains('partner'),
        )
        .toList();
  }

  /**
   * Constructor that sets up authentication listener.
   */
  InvestorCompaniesProvider() {
    _setupAuthListener();
  }

  /**
   * Sets up authentication state listener for user isolation.
   */
  void _setupAuthListener() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final User? user = data.session?.user;

      if (event == AuthChangeEvent.signedIn && user != null) {
        // User signed in - check if it's a different user
        if (_currentUserId != null && _currentUserId != user.id) {
          debugPrint('🔄 Different user detected, resetting provider state');
          _resetProviderState();
        }
        _currentUserId = user.id;

        // Initialize for new user if not already initialized
        if (!_isInitialized) {
          initialize();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('🔄 User signed out, resetting provider state');
        _resetProviderState();
      }
    });
  }

  /**
   * Resets provider state for user isolation.
   * Clears all data and cancels timers.
   */
  void _resetProviderState() {
    _isInitialized = false;
    _currentUserId = null;
    _companies.clear();
    _companyNameController.clear();
    _titleController.clear();
    _websiteController.clear();
    _dirtyFields.clear();
    _error = null;
    _isLoading = false;
    _isSaving = false;
    _saveTimer?.cancel();
    notifyListeners();
  }

  /**
   * Initializes the provider with user data.
   * Loads companies from database and sets up listeners.
   */
  Future<void> initialize() async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      debugPrint('❌ No authenticated user found during initialization');
      return;
    }

    // Check if we need to reset for different user
    if (_currentUserId != null && _currentUserId != currentUser.id) {
      debugPrint('🔄 User changed during initialization, resetting state');
      _resetProviderState();
    }

    _currentUserId = currentUser.id;

    if (_isInitialized) {
      debugPrint('✅ Provider already initialized for user: ${currentUser.id}');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadCompaniesData();
      _addListeners();
      _isInitialized = true;
      debugPrint(
        '✅ InvestorCompaniesProvider initialized for user: ${currentUser.id}',
      );
    } catch (e) {
      _error = 'Failed to initialize companies data: $e';
      debugPrint('❌ Error initializing companies: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /**
   * Loads companies data from database for the current user.
   * Clears existing data before loading new data.
   */
  Future<void> _loadCompaniesData() async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }

    // Additional safety check for user consistency
    if (_currentUserId != null && _currentUserId != currentUser.id) {
      debugPrint('⚠️ User mismatch detected in _loadCompaniesData, resetting');
      _resetProviderState();
      _currentUserId = currentUser.id;
    }

    try {
      debugPrint('🔄 Loading investor companies for user: ${currentUser.id}');

      final response = await _supabase
          .from('investor_companies')
          .select('*')
          .eq('investor_id', currentUser.id)
          .order('created_at', ascending: false);

      // Clear existing companies before loading new ones
      _companies.clear();

      for (final companyData in response) {
        final company = InvestorCompany.fromSupabaseMap(companyData);
        _companies.add(company);
      }

      debugPrint(
        '✅ Loaded ${_companies.length} companies for user: ${currentUser.id}',
      );
    } catch (e) {
      debugPrint('❌ Error loading companies: $e');
      throw Exception('Failed to load companies: $e');
    }
  }

  /**
   * Adds a new company with form data to the database.
   * Validates form and updates state on success.
   */
  Future<void> addCompany() async {
    if (!isFormValid) {
      _error = 'Please fill in all required fields';
      notifyListeners();
      return;
    }

    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      _error = 'No authenticated user found';
      notifyListeners();
      return;
    }

    // Verify working with correct user
    if (_currentUserId != currentUser.id) {
      debugPrint('⚠️ User mismatch in addCompany, reinitializing');
      await initialize();
      return;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔄 Adding new company for user: ${currentUser.id}');

      final companyData = {
        'investor_id': currentUser.id,
        'company_name': _companyNameController.text.trim(),
        'investor_title_in_company': _titleController.text.trim(),
        'website_url':
            _websiteController.text.trim().isNotEmpty
                ? _websiteController.text.trim()
                : null,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response =
          await _supabase
              .from('investor_companies')
              .insert(companyData)
              .select()
              .single();

      final newCompany = InvestorCompany.fromSupabaseMap(response);
      _companies.insert(0, newCompany);

      // Clear form
      _companyNameController.clear();
      _titleController.clear();
      _websiteController.clear();
      _dirtyFields.clear();

      debugPrint('✅ Company added successfully for user: ${currentUser.id}');
    } catch (e) {
      _error = 'Failed to add company: $e';
      debugPrint('❌ Error adding company: $e');
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /**
   * Updates an existing company in the database.
   * Verifies user ownership before updating.
   * 
   * @param company The updated company object
   */
  Future<void> updateCompany(InvestorCompany company) async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      _error = 'No authenticated user found';
      notifyListeners();
      return;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔄 Updating company: ${company.companyName}');

      final updateData = {
        'company_name': company.companyName,
        'investor_title_in_company': company.title,
        'website_url': company.website.isNotEmpty ? company.website : null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('investor_companies')
          .update(updateData)
          .eq('id', company.id)
          .eq(
            'investor_id',
            currentUser.id,
          ); // Double-check: Ensure user owns this company

      // Update local data
      final index = _companies.indexWhere((c) => c.id == company.id);
      if (index != -1) {
        _companies[index] = company;
        notifyListeners();
      }

      debugPrint('✅ Company updated successfully');
    } catch (e) {
      _error = 'Failed to update company: $e';
      debugPrint('❌ Error updating company: $e');
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /**
   * Deletes a company from the database.
   * Verifies user ownership before deletion.
   * 
   * @param company The company to delete
   */
  Future<void> deleteCompany(InvestorCompany company) async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      _error = 'No authenticated user found';
      notifyListeners();
      return;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔄 Deleting company: ${company.companyName}');

      await _supabase
          .from('investor_companies')
          .delete()
          .eq('id', company.id)
          .eq(
            'investor_id',
            currentUser.id,
          ); // Double-check: Ensure user owns this company

      _companies.removeWhere((c) => c.id == company.id);

      debugPrint('✅ Company deleted successfully');
    } catch (e) {
      _error = 'Failed to delete company: $e';
      debugPrint('❌ Error deleting company: $e');
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /**
   * Refreshes the companies data from the database.
   * Useful for manual refresh operations.
   */
  Future<void> refreshData() async {
    await _loadCompaniesData();
    notifyListeners();
  }

  /**
   * Sets up listeners for form field changes.
   */
  void _addListeners() {
    _companyNameController.addListener(_onFormChanged);
    _titleController.addListener(_onFormChanged);
    _websiteController.addListener(_onFormChanged);
  }

  /**
   * Removes listeners for form field changes.
   */
  void _removeListeners() {
    _companyNameController.removeListener(_onFormChanged);
    _titleController.removeListener(_onFormChanged);
    _websiteController.removeListener(_onFormChanged);
  }

  /**
   * Handles form changes by marking fields as dirty.
   */
  void _onFormChanged() {
    _dirtyFields.add('form');
    notifyListeners();
  }

  /**
   * Validates the company name field.
   * 
   * @param value The company name to validate
   * @return Error message or null if valid
   */
  String? validateCompanyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Company name is required';
    }
    if (value.trim().length < 2) {
      return 'Company name must be at least 2 characters';
    }
    return null;
  }

  /**
   * Validates the title field.
   * 
   * @param value The title to validate
   * @return Error message or null if valid
   */
  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.trim().length < 2) {
      return 'Title must be at least 2 characters';
    }
    return null;
  }

  /**
   * Validates the website field.
   * 
   * @param value The website URL to validate
   * @return Error message or null if valid
   */
  String? validateWebsite(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Website is optional
    }

    final websiteRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );

    if (!websiteRegex.hasMatch(value.trim())) {
      return 'Please enter a valid website URL';
    }
    return null;
  }

  /**
   * Clears the current error state.
   */
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /**
   * Cleans up resources when the provider is disposed.
   */
  @override
  void dispose() {
    _authSubscription?.cancel(); // Cancel auth listener
    _removeListeners();
    _companyNameController.dispose();
    _titleController.dispose();
    _websiteController.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }
}

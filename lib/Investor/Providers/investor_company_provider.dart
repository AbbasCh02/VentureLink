// lib/Investor/Providers/investor_company_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Company model
class InvestorCompany {
  final String id;
  final String companyName;
  final String title;
  final String website;
  final DateTime dateAdded;

  InvestorCompany({
    required this.id,
    required this.companyName,
    required this.title,
    this.website = '',
    required this.dateAdded,
  });

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'investor_title_in_company': title,
      'website_url': website,
      'created_at': dateAdded.toIso8601String(),
    };
  }

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

  // 🔥 ADD: Track current user to detect user switches
  String? _currentUserId;
  StreamSubscription<AuthState>? _authSubscription;

  // Getters
  List<InvestorCompany> get companies => List.unmodifiable(_companies);
  int get companiesCount => _companies.length;
  bool get hasCompanies => _companies.isNotEmpty;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  TextEditingController get companyNameController => _companyNameController;
  TextEditingController get titleController => _titleController;
  TextEditingController get websiteController => _websiteController;

  // Form validation
  bool get isFormValid =>
      _companyNameController.text.trim().isNotEmpty &&
      _titleController.text.trim().isNotEmpty;

  // Check for unsaved changes
  bool get hasAnyUnsavedChanges => _dirtyFields.isNotEmpty;

  // Get completion percentage for companies setup
  double get completionPercentage {
    if (_companies.isEmpty) return 0.0;
    if (_companies.length >= 2) return 100.0;
    return (_companies.length / 2) * 100;
  }

  // Current companies (most recent entries)
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

  // 🔥 CONSTRUCTOR: Set up auth listener
  InvestorCompaniesProvider() {
    _setupAuthListener();
  }

  // 🔥 NEW: Set up auth state listener for user isolation
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

  // 🔥 NEW: Reset provider state for user isolation
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

  // Initialize provider
  Future<void> initialize() async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      debugPrint('❌ No authenticated user found during initialization');
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

  // Load companies data from database
  Future<void> _loadCompaniesData() async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }

    // 🔥 ADDITIONAL SAFETY: Verify user consistency
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
          .eq('investor_id', currentUser.id) // This is correct
          .order('created_at', ascending: false);

      // 🔥 CRITICAL: Clear existing companies before loading new ones
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

  // Add new company
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

    // 🔥 VERIFY: Ensure we're working with the correct user
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

  // Update company
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
          ); // 🔥 DOUBLE-CHECK: Ensure user owns this company

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

  // Delete company
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
          ); // 🔥 DOUBLE-CHECK: Ensure user owns this company

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

  // 🔥 NEW: Refresh data (useful for manual refresh)
  Future<void> refreshData() async {
    await _loadCompaniesData();
    notifyListeners();
  }

  // Add listeners for form changes
  void _addListeners() {
    _companyNameController.addListener(_onFormChanged);
    _titleController.addListener(_onFormChanged);
    _websiteController.addListener(_onFormChanged);
  }

  // Remove listeners
  void _removeListeners() {
    _companyNameController.removeListener(_onFormChanged);
    _titleController.removeListener(_onFormChanged);
    _websiteController.removeListener(_onFormChanged);
  }

  // Handle form changes
  void _onFormChanged() {
    _dirtyFields.add('form');
    notifyListeners();
  }

  // Validation methods
  String? validateCompanyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Company name is required';
    }
    if (value.trim().length < 2) {
      return 'Company name must be at least 2 characters';
    }
    return null;
  }

  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.trim().length < 2) {
      return 'Title must be at least 2 characters';
    }
    return null;
  }

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

  // Reset error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel(); // 🔥 Cancel auth listener
    _removeListeners();
    _companyNameController.dispose();
    _titleController.dispose();
    _websiteController.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }
}

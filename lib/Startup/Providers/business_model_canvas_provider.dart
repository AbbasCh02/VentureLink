// lib/Startup/Providers/business_model_canvas_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class BusinessModelCanvasProvider extends ChangeNotifier {
  // Business Model Canvas data
  String _keyPartners = '';
  String _keyActivities = '';
  String _keyResources = '';
  String _valuePropositions = '';
  String _customerRelationships = '';
  String _customerSegments = '';
  String _channels = '';
  String _costStructure = '';
  String _revenueStreams = '';

  // Loading and error states
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // Dirty tracking for unsaved changes - ESSENTIAL for UI
  final Set<String> _dirtyFields = <String>{};

  // Auto-save timer
  Timer? _saveTimer;

  // BMC record ID for linking to user
  String? _bmcId;

  // Flag to prevent infinite loops during initialization
  bool _isInitializing = false;
  bool _isInitialized = false;

  String? _currentUserId;
  StreamSubscription<AuthState>? _authSubscription;

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  BusinessModelCanvasProvider() {
    // Initialize automatically when provider is created and user is authenticated
    _setupAuthListener();
    _initializeWhenReady();
  }

  void _setupAuthListener() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final User? user = data.session?.user;

      if (event == AuthChangeEvent.signedIn && user != null) {
        // User signed in - check if it's a different user
        if (_currentUserId != null && _currentUserId != user.id) {
          debugPrint(
            '🔄 Different startup user detected, resetting BMC provider state',
          );
          _resetProviderState();
        }
        _currentUserId = user.id;

        // Initialize for new user if not already initialized
        if (!_isInitialized) {
          initialize();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('🔄 Startup user signed out, resetting BMC provider state');
        _resetProviderState();
      }
    });
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
  }

  // Reset provider state on logout
  void _resetProviderState() {
    _isInitialized = false;
    _currentUserId = null;
    _keyPartners = '';
    _keyActivities = '';
    _keyResources = '';
    _valuePropositions = '';
    _customerRelationships = '';
    _customerSegments = '';
    _channels = '';
    _costStructure = '';
    _revenueStreams = '';
    _dirtyFields.clear();
    _error = null;
    _bmcId = null;
    _saveTimer?.cancel();
    notifyListeners();
  }

  // Getters
  String get keyPartners => _keyPartners;
  String get keyActivities => _keyActivities;
  String get keyResources => _keyResources;
  String get valuePropositions => _valuePropositions;
  String get customerRelationships => _customerRelationships;
  String get customerSegments => _customerSegments;
  String get channels => _channels;
  String get costStructure => _costStructure;
  String get revenueStreams => _revenueStreams;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Check if specific field has unsaved changes - ESSENTIAL for UI
  bool hasUnsavedChanges(String field) => _dirtyFields.contains(field);
  bool get hasAnyUnsavedChanges => _dirtyFields.isNotEmpty;

  // Clear error method
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all BMC data
  Future<void> clearAllData() async {
    _keyPartners = '';
    _keyActivities = '';
    _keyResources = '';
    _valuePropositions = '';
    _customerRelationships = '';
    _customerSegments = '';
    _channels = '';
    _costStructure = '';
    _revenueStreams = '';

    _dirtyFields.clear();
    _error = null;
    _isInitialized = false;
    _bmcId = null;

    notifyListeners();
  }

  // Reset for new user
  Future<void> resetForNewUser() async {
    clearAllData();
    await initialize();
  }

  // Initialize and load data from Supabase
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
        '✅ BMC provider already initialized for user: ${currentUser.id}',
      );
      await _loadBMCData();
      return;
    }

    _isLoading = true;
    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      await _loadBMCData();
      _isInitialized = true;
      debugPrint('✅ BMC initialized for user: ${currentUser.id}');
    } catch (e) {
      _error = 'Failed to initialize BMC: $e';
      debugPrint('❌ Error initializing BMC: $e');
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadBMCData() async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }

    // 🔥 ADDITIONAL SAFETY: Verify user consistency
    if (_currentUserId != null && _currentUserId != currentUser.id) {
      debugPrint('⚠️ User mismatch detected in _loadBMCData, resetting');
      _resetProviderState();
      _currentUserId = currentUser.id;
    }

    try {
      debugPrint('🔄 Loading BMC data for user: ${currentUser.id}');

      final bmcData =
          await _supabase
              .from('business_model_canvas')
              .select('*')
              .eq('user_id', currentUser.id)
              .maybeSingle();

      if (bmcData != null) {
        _bmcId = bmcData['id'];
        _keyPartners = bmcData['key_partners'] ?? '';
        _keyActivities = bmcData['key_activities'] ?? '';
        _keyResources = bmcData['key_resources'] ?? '';
        _valuePropositions = bmcData['value_propositions'] ?? '';
        _customerRelationships = bmcData['customer_relationships'] ?? '';
        _customerSegments = bmcData['customer_segments'] ?? '';
        _channels = bmcData['channels'] ?? '';
        _costStructure = bmcData['cost_structure'] ?? '';
        _revenueStreams = bmcData['revenue_streams'] ?? '';

        debugPrint('✅ BMC data loaded for user: ${currentUser.id}');
      } else {
        debugPrint('No BMC record found for user: ${currentUser.id}');
      }

      _dirtyFields.clear();
    } catch (e) {
      _error = 'Failed to load BMC data: $e';
      debugPrint('❌ Error loading BMC data: $e');
      rethrow;
    }
  }

  // Internal method to handle field updates
  void _updateField(String fieldName, String value) {
    switch (fieldName) {
      case 'keyPartners':
        _keyPartners = value;
        break;
      case 'keyActivities':
        _keyActivities = value;
        break;
      case 'keyResources':
        _keyResources = value;
        break;
      case 'valuePropositions':
        _valuePropositions = value;
        break;
      case 'customerRelationships':
        _customerRelationships = value;
        break;
      case 'customerSegments':
        _customerSegments = value;
        break;
      case 'channels':
        _channels = value;
        break;
      case 'costStructure':
        _costStructure = value;
        break;
      case 'revenueStreams':
        _revenueStreams = value;
        break;
    }

    // Don't mark as dirty during initialization
    if (!_isInitializing) {
      _dirtyFields.add(fieldName);
      notifyListeners();

      // Auto-save with debouncing (2 seconds after user stops typing)
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(seconds: 2), () {
        if (_dirtyFields.contains(fieldName)) {
          saveField(fieldName);
        }
      });
    }
  }

  // Save specific field to Supabase
  Future<bool> saveField(String fieldName) async {
    if (!_dirtyFields.contains(fieldName)) return true;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Get current user
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create BMC record if it doesn't exist
      if (_bmcId == null) {
        await _createBMCRecord(currentUser.id);
      }

      // Prepare update data based on field name
      Map<String, dynamic> updateData = {};

      switch (fieldName) {
        case 'keyPartners':
          updateData['key_partners'] = _keyPartners;
          break;
        case 'keyActivities':
          updateData['key_activities'] = _keyActivities;
          break;
        case 'keyResources':
          updateData['key_resources'] = _keyResources;
          break;
        case 'valuePropositions':
          updateData['value_propositions'] = _valuePropositions;
          break;
        case 'customerRelationships':
          updateData['customer_relationships'] = _customerRelationships;
          break;
        case 'customerSegments':
          updateData['customer_segments'] = _customerSegments;
          break;
        case 'channels':
          updateData['channels'] = _channels;
          break;
        case 'costStructure':
          updateData['cost_structure'] = _costStructure;
          break;
        case 'revenueStreams':
          updateData['revenue_streams'] = _revenueStreams;
          break;
        default:
          debugPrint('Unknown field: $fieldName');
          return false;
      }

      // Calculate and update completion percentage
      updateData['completion_percentage'] = _calculateCompletionPercentage();
      updateData['updated_at'] = DateTime.now().toIso8601String();

      // Update in Supabase - Filter by BMC ID
      await _supabase
          .from('business_model_canvas')
          .update(updateData)
          .eq('id', _bmcId!);

      _dirtyFields.remove(fieldName);
      debugPrint(
        '✅ Successfully saved $fieldName to Supabase for BMC: $_bmcId',
      );
      return true;
    } catch (e) {
      _error = 'Failed to save $fieldName: $e';
      debugPrint('❌ Error saving $fieldName: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Create new BMC record and link to user
  Future<void> _createBMCRecord(String userId) async {
    try {
      debugPrint('Creating new BMC record for user: $userId');

      // Create new BMC record with all fields initialized and user_id set
      final bmcResponse =
          await _supabase
              .from('business_model_canvas')
              .insert({
                'user_id': userId, // FIXED: Set user_id directly
                'key_partners': _keyPartners,
                'key_activities': _keyActivities,
                'key_resources': _keyResources,
                'value_propositions': _valuePropositions,
                'customer_relationships': _customerRelationships,
                'customer_segments': _customerSegments,
                'channels': _channels,
                'cost_structure': _costStructure,
                'revenue_streams': _revenueStreams,
                'completion_percentage': _calculateCompletionPercentage(),
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .select('id')
              .single();

      _bmcId = bmcResponse['id'];
      debugPrint('✅ Created BMC record with ID: $_bmcId for user: $userId');
    } catch (e) {
      debugPrint('❌ Error creating BMC record: $e');
      throw Exception('Failed to create BMC record: $e');
    }
  }

  // Calculate completion percentage
  double _calculateCompletionPercentage() {
    int completedSections = 0;
    const int totalSections = 9;

    if (_keyPartners.trim().isNotEmpty) completedSections++;
    if (_keyActivities.trim().isNotEmpty) completedSections++;
    if (_keyResources.trim().isNotEmpty) completedSections++;
    if (_valuePropositions.trim().isNotEmpty) completedSections++;
    if (_customerRelationships.trim().isNotEmpty) completedSections++;
    if (_customerSegments.trim().isNotEmpty) completedSections++;
    if (_channels.trim().isNotEmpty) completedSections++;
    if (_costStructure.trim().isNotEmpty) completedSections++;
    if (_revenueStreams.trim().isNotEmpty) completedSections++;

    double percentage = (completedSections / totalSections) * 100;
    // Ensure it's between 0 and 100
    return percentage.clamp(0.0, 100.0);
  }

  // Save all dirty fields to Supabase
  Future<bool> saveAllFields() async {
    if (_dirtyFields.isEmpty) return true;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Get current user
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create BMC record if it doesn't exist
      if (_bmcId == null) {
        await _createBMCRecord(currentUser.id);
      }

      // Prepare update data for all dirty fields
      Map<String, dynamic> updateData = {};

      if (_dirtyFields.contains('keyPartners')) {
        updateData['key_partners'] = _keyPartners;
      }
      if (_dirtyFields.contains('keyActivities')) {
        updateData['key_activities'] = _keyActivities;
      }
      if (_dirtyFields.contains('keyResources')) {
        updateData['key_resources'] = _keyResources;
      }
      if (_dirtyFields.contains('valuePropositions')) {
        updateData['value_propositions'] = _valuePropositions;
      }
      if (_dirtyFields.contains('customerRelationships')) {
        updateData['customer_relationships'] = _customerRelationships;
      }
      if (_dirtyFields.contains('customerSegments')) {
        updateData['customer_segments'] = _customerSegments;
      }
      if (_dirtyFields.contains('channels')) {
        updateData['channels'] = _channels;
      }
      if (_dirtyFields.contains('costStructure')) {
        updateData['cost_structure'] = _costStructure;
      }
      if (_dirtyFields.contains('revenueStreams')) {
        updateData['revenue_streams'] = _revenueStreams;
      }

      // Always update completion percentage and timestamp
      updateData['completion_percentage'] = _calculateCompletionPercentage();
      updateData['updated_at'] = DateTime.now().toIso8601String();

      // Update in Supabase - Filter by BMC ID
      await _supabase
          .from('business_model_canvas')
          .update(updateData)
          .eq('id', _bmcId!);

      _dirtyFields.clear();
      debugPrint(
        '✅ Successfully saved all BMC changes to Supabase for BMC: $_bmcId',
      );
      return true;
    } catch (e) {
      _error = 'Failed to save BMC changes: $e';
      debugPrint('❌ Error saving BMC changes: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Refresh data from database
  Future<void> refreshFromDatabase() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadBMCData();
      debugPrint('✅ BMC data refreshed from database');
    } catch (e) {
      _error = 'Failed to refresh BMC data: $e';
      debugPrint('❌ Error refreshing BMC data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Public update methods
  void updateKeyPartners(String value) => _updateField('keyPartners', value);
  void updateKeyActivities(String value) =>
      _updateField('keyActivities', value);
  void updateKeyResources(String value) => _updateField('keyResources', value);
  void updateValuePropositions(String value) =>
      _updateField('valuePropositions', value);
  void updateCustomerRelationships(String value) =>
      _updateField('customerRelationships', value);
  void updateCustomerSegments(String value) =>
      _updateField('customerSegments', value);
  void updateChannels(String value) => _updateField('channels', value);
  void updateCostStructure(String value) =>
      _updateField('costStructure', value);
  void updateRevenueStreams(String value) =>
      _updateField('revenueStreams', value);

  // Completion status getters
  bool get isKeyPartnersComplete => _keyPartners.trim().isNotEmpty;
  bool get isKeyActivitiesComplete => _keyActivities.trim().isNotEmpty;
  bool get isKeyResourcesComplete => _keyResources.trim().isNotEmpty;
  bool get isValuePropositionsComplete => _valuePropositions.trim().isNotEmpty;
  bool get isCustomerRelationshipsComplete =>
      _customerRelationships.trim().isNotEmpty;
  bool get isCustomerSegmentsComplete => _customerSegments.trim().isNotEmpty;
  bool get isChannelsComplete => _channels.trim().isNotEmpty;
  bool get isCostStructureComplete => _costStructure.trim().isNotEmpty;
  bool get isRevenueStreamsComplete => _revenueStreams.trim().isNotEmpty;

  // Overall completion status
  bool get isComplete {
    return isKeyPartnersComplete &&
        isKeyActivitiesComplete &&
        isKeyResourcesComplete &&
        isValuePropositionsComplete &&
        isCustomerRelationshipsComplete &&
        isCustomerSegmentsComplete &&
        isChannelsComplete &&
        isCostStructureComplete &&
        isRevenueStreamsComplete;
  }

  int get completedSectionsCount {
    int count = 0;
    if (_keyPartners.trim().isNotEmpty) count++;
    if (_keyActivities.trim().isNotEmpty) count++;
    if (_keyResources.trim().isNotEmpty) count++;
    if (_valuePropositions.trim().isNotEmpty) count++;
    if (_customerRelationships.trim().isNotEmpty) count++;
    if (_customerSegments.trim().isNotEmpty) count++;
    if (_channels.trim().isNotEmpty) count++;
    if (_costStructure.trim().isNotEmpty) count++;
    if (_revenueStreams.trim().isNotEmpty) count++;
    return count;
  }

  double get completionPercentage => _calculateCompletionPercentage();

  // Get incomplete sections
  List<String> getIncompleteSections() {
    List<String> incompleteSections = [];

    if (!isKeyPartnersComplete) incompleteSections.add('Key Partners');
    if (!isKeyActivitiesComplete) incompleteSections.add('Key Activities');
    if (!isKeyResourcesComplete) incompleteSections.add('Key Resources');
    if (!isValuePropositionsComplete) {
      incompleteSections.add('Value Propositions');
    }
    if (!isCustomerRelationshipsComplete) {
      incompleteSections.add('Customer Relationships');
    }
    if (!isCustomerSegmentsComplete) {
      incompleteSections.add('Customer Segments');
    }
    if (!isChannelsComplete) incompleteSections.add('Channels');
    if (!isCostStructureComplete) incompleteSections.add('Cost Structure');
    if (!isRevenueStreamsComplete) incompleteSections.add('Revenue Streams');

    return incompleteSections;
  }

  // Get BMC data as Map
  Map<String, dynamic> getBMCData() {
    return {
      'keyPartners': _keyPartners,
      'keyActivities': _keyActivities,
      'keyResources': _keyResources,
      'valuePropositions': _valuePropositions,
      'customerRelationships': _customerRelationships,
      'customerSegments': _customerSegments,
      'channels': _channels,
      'costStructure': _costStructure,
      'revenueStreams': _revenueStreams,
      'completionPercentage': completionPercentage,
      'completedSectionsCount': completedSectionsCount,
      'isComplete': isComplete,
    };
  }

  @override
  void dispose() {
    _authSubscription?.cancel(); // 🔥 Cancel auth listener
    _saveTimer?.cancel();
    super.dispose();
  }
}

// lib/Startup/Providers/business_model_canvas_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

/**
 * business_model_canvas_provider.dart
 * 
 * Implements a state management provider for the Business Model Canvas (BMC)
 * component of startup profiles. Handles data persistence, auto-saving,
 * and completion tracking.
 * 
 * Features:
 * - Complete BMC data management (9 sections)
 * - Auto-saving with debouncing
 * - Completion percentage calculation
 * - Dirty field tracking for UI updates
 * - Authentication state integration
 * - User-specific data isolation
 * - Error handling and state management
 */

/**
 * BusinessModelCanvasProvider - Change notifier provider for managing
 * a startup's Business Model Canvas data with Supabase integration.
 */
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

  // Current user tracking for isolation
  String? _currentUserId;
  StreamSubscription<AuthState>? _authSubscription;

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  /**
   * Constructor that sets up authentication listener and
   * initializes data when authenticated.
   */
  BusinessModelCanvasProvider() {
    // Initialize automatically when provider is created and user is authenticated
    _setupAuthListener();
    _initializeWhenReady();
  }

  /**
   * Sets up an authentication state listener to handle user changes.
   * Ensures data is isolated between different users.
   */
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

  /**
   * Checks for authenticated user and initializes data if found.
   * Otherwise sets up listeners for future authentication events.
   */
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

  /**
   * Resets the provider state when user signs out or changes.
   * Clears all data and cancels pending operations.
   */
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

  /**
   * Provides access to the key partners section.
   * 
   * @return Current key partners text
   */
  String get keyPartners => _keyPartners;

  /**
   * Provides access to the key activities section.
   * 
   * @return Current key activities text
   */
  String get keyActivities => _keyActivities;

  /**
   * Provides access to the key resources section.
   * 
   * @return Current key resources text
   */
  String get keyResources => _keyResources;

  /**
   * Provides access to the value propositions section.
   * 
   * @return Current value propositions text
   */
  String get valuePropositions => _valuePropositions;

  /**
   * Provides access to the customer relationships section.
   * 
   * @return Current customer relationships text
   */
  String get customerRelationships => _customerRelationships;

  /**
   * Provides access to the customer segments section.
   * 
   * @return Current customer segments text
   */
  String get customerSegments => _customerSegments;

  /**
   * Provides access to the channels section.
   * 
   * @return Current channels text
   */
  String get channels => _channels;

  /**
   * Provides access to the cost structure section.
   * 
   * @return Current cost structure text
   */
  String get costStructure => _costStructure;

  /**
   * Provides access to the revenue streams section.
   * 
   * @return Current revenue streams text
   */
  String get revenueStreams => _revenueStreams;

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
   * Checks if a specific field has unsaved changes.
   * 
   * @param field The field name to check
   * @return True if the field has unsaved changes
   */
  bool hasUnsavedChanges(String field) => _dirtyFields.contains(field);

  /**
   * Indicates whether any fields have unsaved changes.
   * 
   * @return True if there are any unsaved changes
   */
  bool get hasAnyUnsavedChanges => _dirtyFields.isNotEmpty;

  /**
   * Clears the current error state.
   */
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /**
   * Clears all BMC data and resets the provider state.
   */
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

  /**
   * Resets the provider for a new user.
   * Clears state and reinitializes.
   */
  Future<void> resetForNewUser() async {
    clearAllData();
    await initialize();
  }

  /**
   * Initializes the provider with user data.
   * Loads BMC from database if exists.
   */
  Future<void> initialize() async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      _resetProviderState();
      return;
    }

    // Check if we need to reset for different user
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

  /**
   * Loads Business Model Canvas data from the database.
   * Creates the record if it doesn't exist.
   */
  Future<void> _loadBMCData() async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }

    // Verify user consistency
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

  /**
   * Updates a specific BMC field and schedules auto-save.
   * 
   * @param fieldName The field to update
   * @param value The new value for the field
   */
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

  /**
   * Saves a specific field to the database.
   * Only saves if the field has been marked as dirty.
   * 
   * @param fieldName The field to save
   * @return True if save was successful, false otherwise
   */
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

  /**
   * Creates a new BMC record in the database.
   * Links it to the specified user.
   * 
   * @param userId The user ID to link the record to
   */
  Future<void> _createBMCRecord(String userId) async {
    try {
      debugPrint('Creating new BMC record for user: $userId');

      // Create new BMC record with all fields initialized and user_id set
      final bmcResponse =
          await _supabase
              .from('business_model_canvas')
              .insert({
                'user_id': userId,
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

  /**
   * Calculates the completion percentage of the Business Model Canvas.
   * Based on how many sections have content.
   * 
   * @return Percentage (0-100) of completion
   */
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

  /**
   * Saves all dirty fields to the database in a single operation.
   * 
   * @return True if save was successful, false otherwise
   */
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

  /**
   * Refreshes BMC data from the database.
   * Useful for manual refresh operations.
   */
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

  /**
   * Updates the key partners section.
   * 
   * @param value The new key partners text
   */
  void updateKeyPartners(String value) => _updateField('keyPartners', value);

  /**
   * Updates the key activities section.
   * 
   * @param value The new key activities text
   */
  void updateKeyActivities(String value) =>
      _updateField('keyActivities', value);

  /**
   * Updates the key resources section.
   * 
   * @param value The new key resources text
   */
  void updateKeyResources(String value) => _updateField('keyResources', value);

  /**
   * Updates the value propositions section.
   * 
   * @param value The new value propositions text
   */
  void updateValuePropositions(String value) =>
      _updateField('valuePropositions', value);

  /**
   * Updates the customer relationships section.
   * 
   * @param value The new customer relationships text
   */
  void updateCustomerRelationships(String value) =>
      _updateField('customerRelationships', value);

  /**
   * Updates the customer segments section.
   * 
   * @param value The new customer segments text
   */
  void updateCustomerSegments(String value) =>
      _updateField('customerSegments', value);

  /**
   * Updates the channels section.
   * 
   * @param value The new channels text
   */
  void updateChannels(String value) => _updateField('channels', value);

  /**
   * Updates the cost structure section.
   * 
   * @param value The new cost structure text
   */
  void updateCostStructure(String value) =>
      _updateField('costStructure', value);

  /**
   * Updates the revenue streams section.
   * 
   * @param value The new revenue streams text
   */
  void updateRevenueStreams(String value) =>
      _updateField('revenueStreams', value);

  /**
   * Indicates whether the key partners section is complete.
   * 
   * @return True if section has content
   */
  bool get isKeyPartnersComplete => _keyPartners.trim().isNotEmpty;

  /**
   * Indicates whether the key activities section is complete.
   * 
   * @return True if section has content
   */
  bool get isKeyActivitiesComplete => _keyActivities.trim().isNotEmpty;

  /**
   * Indicates whether the key resources section is complete.
   * 
   * @return True if section has content
   */
  bool get isKeyResourcesComplete => _keyResources.trim().isNotEmpty;

  /**
   * Indicates whether the value propositions section is complete.
   * 
   * @return True if section has content
   */
  bool get isValuePropositionsComplete => _valuePropositions.trim().isNotEmpty;

  /**
   * Indicates whether the customer relationships section is complete.
   * 
   * @return True if section has content
   */
  bool get isCustomerRelationshipsComplete =>
      _customerRelationships.trim().isNotEmpty;

  /**
   * Indicates whether the customer segments section is complete.
   * 
   * @return True if section has content
   */
  bool get isCustomerSegmentsComplete => _customerSegments.trim().isNotEmpty;

  /**
   * Indicates whether the channels section is complete.
   * 
   * @return True if section has content
   */
  bool get isChannelsComplete => _channels.trim().isNotEmpty;

  /**
   * Indicates whether the cost structure section is complete.
   * 
   * @return True if section has content
   */
  bool get isCostStructureComplete => _costStructure.trim().isNotEmpty;

  /**
   * Indicates whether the revenue streams section is complete.
   * 
   * @return True if section has content
   */
  bool get isRevenueStreamsComplete => _revenueStreams.trim().isNotEmpty;

  /**
   * Indicates whether the entire BMC is complete.
   * All sections must have content.
   * 
   * @return True if all sections are complete
   */
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

  /**
   * Returns the number of completed sections.
   * 
   * @return Count of sections with content (0-9)
   */
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

  /**
   * Returns the completion percentage of the BMC.
   * 
   * @return Percentage (0-100) of completion
   */
  double get completionPercentage => _calculateCompletionPercentage();

  /**
   * Returns a list of section names that are not yet complete.
   * 
   * @return List of incomplete section names
   */
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

  /**
   * Returns the BMC data as a map for export or display.
   * 
   * @return Map containing all BMC sections and metadata
   */
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

  /**
   * Cleans up resources when the provider is disposed.
   */
  @override
  void dispose() {
    _authSubscription?.cancel(); // Cancel auth listener
    _saveTimer?.cancel();
    super.dispose();
  }
}

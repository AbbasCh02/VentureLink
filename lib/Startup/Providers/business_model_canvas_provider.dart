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

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  BusinessModelCanvasProvider() {
    // Initialize automatically when provider is created
    initialize();
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

  // Check if specific field has unsaved changes - ESSENTIAL for UI
  bool hasUnsavedChanges(String field) => _dirtyFields.contains(field);
  bool get hasAnyUnsavedChanges => _dirtyFields.isNotEmpty;

  // Clear error method
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Initialize and load data from Supabase
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
        debugPrint('No authenticated user found');
        return;
      }

      // First, get user's BMC ID from the users table
      final userResponse =
          await _supabase
              .from('users')
              .select('bmc_id')
              .eq('id', currentUser.id)
              .maybeSingle();

      _bmcId = userResponse?['bmc_id'];
      debugPrint('User BMC ID: $_bmcId');

      // If user has a BMC ID, load the BMC data
      if (_bmcId != null) {
        final bmcResponse =
            await _supabase
                .from('business_model_canvas')
                .select('*')
                .eq('id', _bmcId!)
                .maybeSingle();

        if (bmcResponse != null) {
          // Populate all BMC fields with loaded data
          _keyPartners = bmcResponse['key_partners'] ?? '';
          _keyActivities = bmcResponse['key_activities'] ?? '';
          _keyResources = bmcResponse['key_resources'] ?? '';
          _valuePropositions = bmcResponse['value_propositions'] ?? '';
          _customerRelationships = bmcResponse['customer_relationships'] ?? '';
          _customerSegments = bmcResponse['customer_segments'] ?? '';
          _channels = bmcResponse['channels'] ?? '';
          _costStructure = bmcResponse['cost_structure'] ?? '';
          _revenueStreams = bmcResponse['revenue_streams'] ?? '';

          debugPrint('BMC data loaded successfully');
        }
      } else {
        // No BMC exists yet, initialize with empty values
        debugPrint('No BMC found for user, starting with empty canvas');
      }

      _dirtyFields.clear(); // Clear dirty state after loading
      _isInitialized = true;
    } catch (e) {
      _error = 'Failed to load BMC data: $e';
      debugPrint('Error loading BMC data: $e');
    } finally {
      _isInitializing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generic method to update field and track dirty state
  void _updateField(String fieldName, String value) {
    // Don't mark as dirty during initialization
    if (_isInitializing) return;

    // Update the field value
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

    // Mark field as dirty - ESSENTIAL for save button functionality
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

      // Update in Supabase
      await _supabase
          .from('business_model_canvas')
          .update(updateData)
          .eq('id', _bmcId!);

      _dirtyFields.remove(fieldName);
      debugPrint('Successfully saved $fieldName to Supabase');
      return true;
    } catch (e) {
      _error = 'Failed to save $fieldName: $e';
      debugPrint('Error saving $fieldName: $e');
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

      // Create new BMC record with all fields initialized
      final bmcResponse =
          await _supabase
              .from('business_model_canvas')
              .insert({
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
      debugPrint('Created BMC record with ID: $_bmcId');

      // Update user record to link the BMC
      await _supabase
          .from('users')
          .update({
            'bmc_id': _bmcId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      debugPrint('Linked BMC $_bmcId to user $userId');
    } catch (e) {
      debugPrint('Error creating BMC record: $e');
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

    return (completedSections / totalSections) * 100;
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

      // Update in Supabase
      await _supabase
          .from('business_model_canvas')
          .update(updateData)
          .eq('id', _bmcId!);

      _dirtyFields.clear();
      debugPrint('Successfully saved all BMC changes to Supabase');
      return true;
    } catch (e) {
      _error = 'Failed to save BMC changes: $e';
      debugPrint('Error saving BMC changes: $e');
      return false;
    } finally {
      _isSaving = false;
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

  // Get completion status for each section
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

  // Get overall completion percentage
  double get completionPercentage {
    return _calculateCompletionPercentage() / 100;
  }

  // Get completed sections count
  int get completedSectionsCount =>
      (_calculateCompletionPercentage() / 100 * 9).round();

  // Check if BMC is fully complete
  bool get isFullyComplete => completedSectionsCount == 9;

  // Get BMC summary data
  Map<String, dynamic> getBMCSummary() {
    return {
      'completionPercentage': _calculateCompletionPercentage(),
      'completedSections': completedSectionsCount,
      'totalSections': 9,
      'isComplete': isFullyComplete,
      'bmcId': _bmcId,
      'hasUnsavedChanges': hasAnyUnsavedChanges,
    };
  }

  // Export BMC data for backup/sharing
  Map<String, dynamic> exportBMCData() {
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
      'completionPercentage': _calculateCompletionPercentage(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  // Import BMC data with Supabase save
  Future<bool> importBMCData(Map<String, dynamic> data) async {
    try {
      _isInitializing = true;

      // Update all fields
      _keyPartners = data['keyPartners'] ?? '';
      _keyActivities = data['keyActivities'] ?? '';
      _keyResources = data['keyResources'] ?? '';
      _valuePropositions = data['valuePropositions'] ?? '';
      _customerRelationships = data['customerRelationships'] ?? '';
      _customerSegments = data['customerSegments'] ?? '';
      _channels = data['channels'] ?? '';
      _costStructure = data['costStructure'] ?? '';
      _revenueStreams = data['revenueStreams'] ?? '';

      // Mark all fields as dirty
      _dirtyFields.addAll([
        'keyPartners',
        'keyActivities',
        'keyResources',
        'valuePropositions',
        'customerRelationships',
        'customerSegments',
        'channels',
        'costStructure',
        'revenueStreams',
      ]);

      _isInitializing = false;
      notifyListeners();

      // Save all changes to Supabase
      await saveAllFields();

      debugPrint('BMC data imported successfully');
      return true;
    } catch (e) {
      _error = 'Failed to import BMC data: $e';
      debugPrint('Error importing BMC data: $e');
      _isInitializing = false;
      return false;
    }
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

    // Mark all fields as dirty for saving
    _dirtyFields.addAll([
      'keyPartners',
      'keyActivities',
      'keyResources',
      'valuePropositions',
      'customerRelationships',
      'customerSegments',
      'channels',
      'costStructure',
      'revenueStreams',
    ]);

    notifyListeners();

    try {
      // Clear data in Supabase
      if (_bmcId != null) {
        await _supabase
            .from('business_model_canvas')
            .update({
              'key_partners': '',
              'key_activities': '',
              'key_resources': '',
              'value_propositions': '',
              'customer_relationships': '',
              'customer_segments': '',
              'channels': '',
              'cost_structure': '',
              'revenue_streams': '',
              'completion_percentage': 0.0,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', _bmcId!);

        _dirtyFields.clear();
        debugPrint('BMC data cleared successfully');
      }
    } catch (e) {
      _error = 'Failed to clear BMC data: $e';
      debugPrint('Error clearing BMC data: $e');
    }
  }

  // Refresh data from database
  Future<void> refreshFromDatabase() async {
    _isInitialized = false;
    await initialize();
  }

  // Validate BMC completeness for specific sections
  List<String> getIncompleteSection() {
    List<String> incomplete = [];

    if (!isKeyPartnersComplete) incomplete.add('Key Partners');
    if (!isKeyActivitiesComplete) incomplete.add('Key Activities');
    if (!isKeyResourcesComplete) incomplete.add('Key Resources');
    if (!isValuePropositionsComplete) incomplete.add('Value Propositions');
    if (!isCustomerRelationshipsComplete) {
      incomplete.add('Customer Relationships');
    }
    if (!isCustomerSegmentsComplete) incomplete.add('Customer Segments');
    if (!isChannelsComplete) incomplete.add('Channels');
    if (!isCostStructureComplete) incomplete.add('Cost Structure');
    if (!isRevenueStreamsComplete) incomplete.add('Revenue Streams');

    return incomplete;
  }

  // Get recommendations for improving BMC
  List<String> getBMCRecommendations() {
    List<String> recommendations = [];

    if (!isValuePropositionsComplete) {
      recommendations.add(
        'Start with Value Propositions - this is the heart of your business model',
      );
    }
    if (!isCustomerSegmentsComplete) {
      recommendations.add(
        'Define your Customer Segments to understand who you serve',
      );
    }
    if (!isKeyActivitiesComplete) {
      recommendations.add(
        'Identify Key Activities needed to deliver your value proposition',
      );
    }
    if (!isRevenueStreamsComplete) {
      recommendations.add(
        'Define Revenue Streams to understand how you make money',
      );
    }

    return recommendations;
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

import 'package:flutter/material.dart';

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

  // Dirty tracking for unsaved changes - KEEP THIS, it's essential!
  final Set<String> _dirtyFields = <String>{};

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

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Load data from Supabase here
      // For now, just set loading to false
      _dirtyFields.clear();
    } catch (e) {
      _error = 'Failed to load data: $e';
      debugPrint('Error loading BMC data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generic method to update field and track dirty state
  void _updateField(String fieldName, String value) {
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
  }

  Future<bool> saveField(String fieldName) async {
    if (!_dirtyFields.contains(fieldName)) return true;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Save to Supabase here
      // For now, just clear the dirty state
      _dirtyFields.remove(fieldName);
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
    int completedSections = 0;
    const int totalSections = 9;

    if (isKeyPartnersComplete) completedSections++;
    if (isKeyActivitiesComplete) completedSections++;
    if (isKeyResourcesComplete) completedSections++;
    if (isValuePropositionsComplete) completedSections++;
    if (isCustomerRelationshipsComplete) completedSections++;
    if (isCustomerSegmentsComplete) completedSections++;
    if (isChannelsComplete) completedSections++;
    if (isCostStructureComplete) completedSections++;
    if (isRevenueStreamsComplete) completedSections++;

    return completedSections / totalSections;
  }

  // Get completed sections count
  int get completedSectionsCount => (completionPercentage * 9).round();

  // Clear all data
  // Replace clearAllData() method with:
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

    notifyListeners();

    try {
      // TODO: Clear data from Supabase if needed
    } catch (e) {
      _error = 'Failed to clear data: $e';
      debugPrint('Error clearing data: $e');
    }
  }
}

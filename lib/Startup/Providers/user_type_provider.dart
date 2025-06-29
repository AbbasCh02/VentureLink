// lib/Providers/user_type_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class UserTypeProvider extends ChangeNotifier {
  // Private fields
  String? _userType; // Either "startup" or "investor"
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  // Auth state subscription
  StreamSubscription<AuthState>? _authSubscription;

  UserTypeProvider() {
    _initialize();
  }

  // Getters
  String? get userType => _userType;
  bool get isStartup => _userType == 'startup';
  bool get isInvestor => _userType == 'investor';
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get hasUserType => _userType != null;

  // Initialize and listen to auth changes
  void _initialize() {
    // Load current user type if authenticated
    _loadUserType();

    // Listen to auth state changes
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      switch (data.event) {
        case AuthChangeEvent.signedIn:
          _loadUserType();
          break;
        case AuthChangeEvent.signedOut:
          _clearUserType();
          break;
        default:
          break;
      }
    });
  }

  // Load user type from Supabase
  Future<void> _loadUserType() async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get user type from users table
      final response =
          await _supabase
              .from('users')
              .select('user_status')
              .eq('id', currentUser.id)
              .maybeSingle();

      if (response != null && response['user_status'] != null) {
        _userType = response['user_status'] as String;
        debugPrint('Loaded user type: $_userType');
      } else {
        _userType = null;
        debugPrint('No user type found for user');
      }
    } catch (e) {
      _error = 'Failed to load user type: $e';
      debugPrint('Error loading user type: $e');
      _userType = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set user type and save to Supabase
  Future<bool> setUserType(String type) async {
    // Validate input
    if (type != 'startup' && type != 'investor') {
      _error = 'Invalid user type. Must be "startup" or "investor"';
      notifyListeners();
      return false;
    }

    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Update user type in Supabase
      await _supabase
          .from('users')
          .update({
            'user_status': type,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentUser.id);

      // Update local state
      _userType = type;
      debugPrint('User type set to: $type');
      return true;
    } catch (e) {
      _error = 'Failed to save user type: $e';
      debugPrint('Error saving user type: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Clear user type (for sign out)
  void _clearUserType() {
    _userType = null;
    _error = null;
    debugPrint('User type cleared');
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh user type from database
  Future<void> refreshUserType() async {
    await _loadUserType();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// lib/services/user_type_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized service for detecting and managing user types
/// This service determines whether a user is a startup or investor
/// by checking which database table contains their record
class UserTypeService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Detects user type by checking both users and investors tables
  /// Returns 'startup', 'investor', or null if not found
  static Future<String?> detectUserType(String userId) async {
    try {
      // Check startup users table first
      final startupCheck =
          await _supabase
              .from('users')
              .select('id')
              .eq('id', userId)
              .maybeSingle();

      if (startupCheck != null) {
        debugPrint('🟢 User $userId detected as STARTUP');
        return 'startup';
      }

      // Check investors table
      final investorCheck =
          await _supabase
              .from('investors')
              .select('id')
              .eq('id', userId)
              .maybeSingle();

      if (investorCheck != null) {
        debugPrint('🔵 User $userId detected as INVESTOR');
        return 'investor';
      }

      debugPrint('❌ User $userId not found in either table');
      return null;
    } catch (e) {
      debugPrint('❌ Error detecting user type for $userId: $e');
      return null;
    }
  }

  /// Checks if a user exists in the startup users table
  static Future<bool> isStartupUser(String userId) async {
    try {
      final result =
          await _supabase
              .from('users')
              .select('id')
              .eq('id', userId)
              .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint('❌ Error checking startup user: $e');
      return false;
    }
  }

  /// Checks if a user exists in the investors table
  static Future<bool> isInvestorUser(String userId) async {
    try {
      final result =
          await _supabase
              .from('investors')
              .select('id')
              .eq('id', userId)
              .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint('❌ Error checking investor user: $e');
      return false;
    }
  }

  /// Cleans up all user sessions and signs out
  static Future<void> cleanupUserSessions() async {
    try {
      await _supabase.auth.signOut();
      debugPrint('✅ All user sessions cleaned up');
    } catch (e) {
      debugPrint('❌ Error cleaning up sessions: $e');
    }
  }

  /// Gets user details from the appropriate table based on user type
  static Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final userType = await detectUserType(userId);

      if (userType == 'startup') {
        return await _supabase
            .from('users')
            .select('*')
            .eq('id', userId)
            .maybeSingle();
      } else if (userType == 'investor') {
        return await _supabase
            .from('investors')
            .select('*')
            .eq('id', userId)
            .maybeSingle();
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting user details: $e');
      return null;
    }
  }

  /// Validates that a user exists in the correct table for their auth provider
  static Future<bool> validateUserTypeConsistency(
    String userId,
    String expectedType,
  ) async {
    try {
      final actualType = await detectUserType(userId);
      return actualType == expectedType;
    } catch (e) {
      debugPrint('❌ Error validating user type consistency: $e');
      return false;
    }
  }
}

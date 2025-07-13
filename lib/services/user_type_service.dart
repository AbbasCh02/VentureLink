// lib/services/user_type_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enhanced centralized service for detecting and managing user types
/// This service determines whether a user is a startup or investor
/// by checking which database table contains their record
/// and ensures proper authentication isolation
class UserTypeService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Detects user type by checking both users and investors tables
  /// Returns 'startup', 'investor', or null if not found
  /// CRITICAL: This function ensures proper user type isolation
  static Future<String?> detectUserType(String userId) async {
    try {
      debugPrint('🔍 Detecting user type for ID: $userId');

      // Check startup users table first
      final startupCheck =
          await _supabase
              .from('startups')
              .select('id, email, username')
              .eq('id', userId)
              .maybeSingle();

      if (startupCheck != null) {
        debugPrint('🟢 User $userId detected as STARTUP');
        debugPrint('   Email: ${startupCheck['email']}');
        debugPrint('   Username: ${startupCheck['username']}');
        return 'startup';
      }

      // Check investors table
      final investorCheck =
          await _supabase
              .from('investors')
              .select('id, email, username')
              .eq('id', userId)
              .maybeSingle();

      if (investorCheck != null) {
        debugPrint('🔵 User $userId detected as INVESTOR');
        debugPrint('   Email: ${investorCheck['email']}');
        debugPrint('   Username: ${investorCheck['username']}');
        return 'investor';
      }

      debugPrint('❌ User $userId not found in either table');
      return null;
    } catch (e) {
      debugPrint('❌ Error detecting user type for $userId: $e');
      return null;
    }
  }

  /// Enhanced method to check if a user exists in the startup users table
  /// with additional validation
  static Future<bool> isStartupUser(String userId) async {
    try {
      final result =
          await _supabase
              .from('startups')
              .select('id, email, is_verified')
              .eq('id', userId)
              .maybeSingle();

      final exists = result != null;
      debugPrint('🔍 Startup user check for $userId: $exists');

      if (exists) {
        debugPrint('   Verified: ${result['is_verified']}');
      }

      return exists;
    } catch (e) {
      debugPrint('❌ Error checking startup user: $e');
      return false;
    }
  }

  /// Enhanced method to check if a user exists in the investors table
  /// with additional validation
  static Future<bool> isInvestorUser(String userId) async {
    try {
      final result =
          await _supabase
              .from('investors')
              .select('id, email, is_verified')
              .eq('id', userId)
              .maybeSingle();

      final exists = result != null;
      debugPrint('🔍 Investor user check for $userId: $exists');

      if (exists) {
        debugPrint('   Verified: ${result['is_verified']}');
      }

      return exists;
    } catch (e) {
      debugPrint('❌ Error checking investor user: $e');
      return false;
    }
  }

  /// Enhanced cleanup method that properly isolates user sessions
  /// This ensures no cross-contamination between startup and investor sessions
  static Future<void> cleanupUserSessions() async {
    try {
      // Get current session info before cleanup
      final session = _supabase.auth.currentSession;
      if (session?.user != null) {
        debugPrint('🧹 Cleaning up session for user: ${session!.user.email}');
        debugPrint('   User ID: ${session.user.id}');
      }

      // Sign out from Supabase
      await _supabase.auth.signOut();

      debugPrint('✅ All user sessions cleaned up successfully');
    } catch (e) {
      debugPrint('❌ Error cleaning up sessions: $e');
    }
  }

  /// Gets user details from the appropriate table based on user type
  /// with enhanced error handling and validation
  static Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      debugPrint('📋 Getting user details for: $userId');

      final userType = await detectUserType(userId);

      if (userType == 'startup') {
        final details =
            await _supabase
                .from('startups')
                .select('*')
                .eq('id', userId)
                .maybeSingle();

        debugPrint('✅ Retrieved startup user details');
        return details;
      } else if (userType == 'investor') {
        final details =
            await _supabase
                .from('investors')
                .select('*')
                .eq('id', userId)
                .maybeSingle();

        debugPrint('✅ Retrieved investor user details');
        return details;
      }

      debugPrint('❌ No user details found for type: $userType');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user details: $e');
      return null;
    }
  }

  /// Validates that a user exists in the correct table for their expected type
  /// This is critical for preventing authentication confusion
  static Future<bool> validateUserTypeConsistency(
    String userId,
    String expectedType,
  ) async {
    try {
      debugPrint('🔒 Validating user type consistency');
      debugPrint('   User ID: $userId');
      debugPrint('   Expected type: $expectedType');

      final actualType = await detectUserType(userId);
      final isConsistent = actualType == expectedType;

      debugPrint('   Actual type: $actualType');
      debugPrint('   Consistent: $isConsistent');

      if (!isConsistent) {
        debugPrint('⚠️ User type inconsistency detected!');
        debugPrint('   This indicates a potential authentication issue');
      }

      return isConsistent;
    } catch (e) {
      debugPrint('❌ Error validating user type consistency: $e');
      return false;
    }
  }

  /// Enhanced method to ensure proper user isolation
  /// This prevents startup users from accessing investor features and vice versa
  static Future<bool> enforceUserTypeIsolation(
    String userId,
    String requiredType,
  ) async {
    try {
      debugPrint('🛡️ Enforcing user type isolation');
      debugPrint('   User ID: $userId');
      debugPrint('   Required type: $requiredType');

      // First check if user exists in the correct table
      final isValidType = await validateUserTypeConsistency(
        userId,
        requiredType,
      );

      if (!isValidType) {
        debugPrint('❌ User type isolation violated!');
        debugPrint('   User $userId cannot access $requiredType features');

        // Clean up the session to prevent further issues
        await cleanupUserSessions();
        return false;
      }

      debugPrint('✅ User type isolation enforced successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error enforcing user type isolation: $e');
      return false;
    }
  }

  /// Checks if current authenticated user matches expected type
  /// Returns true only if user is authenticated and in correct table
  static Future<bool> isCurrentUserOfType(String expectedType) async {
    try {
      final currentUser = _supabase.auth.currentUser;

      if (currentUser == null) {
        debugPrint('❌ No current user authenticated');
        return false;
      }

      return await validateUserTypeConsistency(currentUser.id, expectedType);
    } catch (e) {
      debugPrint('❌ Error checking current user type: $e');
      return false;
    }
  }

  /// Gets the current authenticated user's type
  /// Returns 'startup', 'investor', or null
  static Future<String?> getCurrentUserType() async {
    try {
      final currentUser = _supabase.auth.currentUser;

      if (currentUser == null) {
        debugPrint('❌ No current user authenticated');
        return null;
      }

      return await detectUserType(currentUser.id);
    } catch (e) {
      debugPrint('❌ Error getting current user type: $e');
      return null;
    }
  }

  /// Enhanced debugging method to log current authentication state
  static Future<void> debugCurrentAuthState() async {
    try {
      final session = _supabase.auth.currentSession;
      final user = session?.user;

      debugPrint('🔍 === CURRENT AUTH STATE DEBUG ===');
      debugPrint('Session exists: ${session != null}');
      debugPrint('User exists: ${user != null}');

      if (user != null) {
        debugPrint('User ID: ${user.id}');
        debugPrint('User Email: ${user.email}');
        debugPrint('Email Confirmed: ${user.emailConfirmedAt != null}');
        debugPrint('Created At: ${user.createdAt}');

        final userType = await detectUserType(user.id);
        debugPrint('Detected Type: $userType');

        final startupExists = await isStartupUser(user.id);
        final investorExists = await isInvestorUser(user.id);
        debugPrint('In Startup Table: $startupExists');
        debugPrint('In Investor Table: $investorExists');

        if (startupExists && investorExists) {
          debugPrint('⚠️ WARNING: User exists in both tables!');
        }
      }

      debugPrint('=== END AUTH STATE DEBUG ===');
    } catch (e) {
      debugPrint('❌ Error debugging auth state: $e');
    }
  }
}

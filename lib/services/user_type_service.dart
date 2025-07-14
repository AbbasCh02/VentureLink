// lib/services/user_type_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/**
 * user_type_service.dart
 * 
 * Implements a centralized service for detecting and managing user types within the application.
 * Provides utilities for determining whether a user is a startup or investor by checking
 * database tables, enforcing proper authentication isolation, and preventing unauthorized access.
 * 
 * Features:
 * - User type detection and validation
 * - Authentication isolation between user types
 * - User session management
 * - User details retrieval based on type
 * - Security enforcement for type-specific features
 * - Consistency validation to prevent authorization issues
 * - Debugging utilities for authentication state
 */

/**
 * UserTypeService - Utility class for managing user types and authentication boundaries.
 * Ensures users can only access features appropriate for their account type.
 */
class UserTypeService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /**
   * Detects a user's type by checking database tables.
   * Examines both startup and investor tables to determine user classification.
   * 
   * @param userId The user ID to check
   * @return 'startup', 'investor', or null if not found in either table
   */
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

  /**
   * Checks if a user exists in the startup users table.
   * Includes verification status in debug output.
   * 
   * @param userId The user ID to check
   * @return True if user exists in startups table, false otherwise
   */
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

  /**
   * Checks if a user exists in the investors table.
   * Includes verification status in debug output.
   * 
   * @param userId The user ID to check
   * @return True if user exists in investors table, false otherwise
   */
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

  /**
   * Cleans up user sessions by signing out.
   * Ensures no cross-contamination between startup and investor sessions.
   */
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

  /**
   * Retrieves user details from the appropriate table based on detected user type.
   * 
   * @param userId The user ID to get details for
   * @return Map containing user details or null if not found
   */
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

  /**
   * Validates that a user exists in the correct table for their expected type.
   * Critical for preventing authentication confusion between user types.
   * 
   * @param userId The user ID to validate
   * @param expectedType The expected user type ('startup' or 'investor')
   * @return True if user's actual type matches expected type, false otherwise
   */
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

  /**
   * Enforces proper user type isolation to prevent unauthorized access.
   * Prevents startup users from accessing investor features and vice versa.
   * 
   * @param userId The user ID to check
   * @param requiredType The required user type for access ('startup' or 'investor')
   * @return True if user is of required type, false otherwise
   */
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

  /**
   * Checks if the current authenticated user matches the expected type.
   * 
   * @param expectedType The expected user type ('startup' or 'investor')
   * @return True if current user is of expected type, false otherwise
   */
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

  /**
   * Gets the current authenticated user's type.
   * 
   * @return 'startup', 'investor', or null if no user is authenticated
   */
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

  /**
   * Logs detailed information about the current authentication state.
   * Useful for debugging authentication and user type issues.
   */
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

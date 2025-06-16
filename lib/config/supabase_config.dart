// lib/config/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Load from environment variables
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Initialize Supabase
  static Future<void> initialize() async {
    // Load environment variables
    await dotenv.load();

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true,
    );
  }

  // Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  // Get current user
  static User? get currentUser => client.auth.currentUser;

  // Check if user is signed in
  static bool get isSignedIn => currentUser != null;
}

// Global getter for easy access throughout the app
SupabaseClient get supabase => SupabaseConfig.client;

// lib/Investor/investor_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/unified_authentication_provider.dart';

class InvestorDashboard extends StatelessWidget {
  const InvestorDashboard({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Get auth provider and sign out
      final authProvider = context.read<UnifiedAuthProvider>();
      await authProvider.signOut();

      // Navigate back to welcome page
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/welcome', (route) => false);
      }
    } catch (e) {
      // Show error if logout fails
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investor Dashboard'),
        actions: [
          IconButton(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: const Center(child: Text('Welcome to the Investor dashboard!')),
    );
  }
}

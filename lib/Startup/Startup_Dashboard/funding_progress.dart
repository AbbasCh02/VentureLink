import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/startup_profile_provider.dart';

/**
 * Implements a comprehensive funding information widget for startup profile management.
 * Provides interactive components for capturing funding goals and funding phase selection.
 * 
 * Features:
 * - Real-time funding goal input with numeric validation
 * - Comprehensive funding phase dropdown with startup lifecycle stages
 * - Seamless integration with StartupProfileProvider for state management
 * - Auto-save functionality with debounced updates
 * - Form validation for funding amount and phase selection
 * - Responsive UI with loading states and visual feedback
 * - Professional styling with consistent color scheme
 * - Error handling and validation feedback
 * - Automatic data parsing and type conversion
 * - Startup funding lifecycle stage tracking
 */

/**
 * Funding - Reusable widget component for capturing startup funding information.
 * Handles funding goal amount input and funding phase selection with validation.
 */
class Funding extends StatefulWidget {
  const Funding({super.key});

  @override
  State<Funding> createState() => _FundingState();
}

/**
 * _FundingState - State management for the Funding widget component.
 * Manages form interactions, validation, and provider integration for funding data.
 */
class _FundingState extends State<Funding> {
  /**
   * Initializes the widget state.
   * Sets up any necessary initialization for the funding form components.
   */
  @override
  void initState() {
    super.initState();
  }

  /**
   * Builds the main Funding widget interface.
   * Uses Consumer pattern to listen to StartupProfileProvider changes and update UI accordingly.
   * 
   * @return Widget containing the complete funding information form
   */
  @override
  Widget build(BuildContext context) {
    return Consumer<StartupProfileProvider>(
      builder: (context, provider, child) {
        // Show loading state while provider is initializing
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFffa500)),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFundingGoalField(provider),
            const SizedBox(height: 16),
            _buildFundingPhaseDropdown(provider),
          ],
        );
      },
    );
  }

  /**
   * Builds the funding goal input field with validation and styling.
   * Handles numeric input, parsing, and real-time updates to the provider.
   * 
   * @param provider The StartupProfileProvider instance for state management
   * @return Widget containing the funding goal text field
   */
  Widget _buildFundingGoalField(StartupProfileProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        cursorColor: const Color(0xFFffa500),
        controller: provider.fundingGoalController,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: 'Enter funding goal (USD)',
          labelStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.monetization_on_outlined,
            color: const Color(0xFFffa500),
            size: 22,
          ),
          filled: true,
          fillColor: Colors.grey[800]!.withValues(alpha: 0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFffa500), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: (value) {
          // Parse and store the funding goal as integer
          if (value.isNotEmpty) {
            final amount = int.tryParse(value.replaceAll(',', ''));
            provider.updateFundingGoalAmount(amount);
          } else {
            provider.updateFundingGoalAmount(null);
          }
        },
        validator: provider.validateFundingGoal,
      ),
    );
  }

  /**
   * Builds the funding phase dropdown with comprehensive startup lifecycle stages.
   * Provides selection from idea stage through IPO readiness with validation.
   * 
   * @param provider The StartupProfileProvider instance for state management
   * @return Widget containing the funding phase dropdown
   */
  Widget _buildFundingPhaseDropdown(StartupProfileProvider provider) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Funding Phase',
          labelStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.trending_up,
            color: const Color(0xFF4CAF50),
            size: 22,
          ),
          filled: true,
          fillColor: Colors.grey[800]!.withValues(alpha: 0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFffa500), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        dropdownColor: Colors.grey[800],
        value: provider.selectedFundingPhase,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: Colors.grey[400],
          size: 24,
        ),
        items: _buildFundingPhaseItems(),
        onChanged: provider.updateSelectedFundingPhase,
        validator: provider.validateFundingPhase,
      ),
    );
  }

  /**
   * Builds the list of funding phase dropdown items.
   * Covers the complete startup funding lifecycle from idea to IPO readiness.
   * 
   * @return List of DropdownMenuItem widgets for funding phases
   */
  List<DropdownMenuItem<String>> _buildFundingPhaseItems() {
    final phases = [
      'Idea',
      'Pre-Seed',
      'MVP',
      'Seed',
      'Product-Market Fit',
      'Early Growth',
      'Series A',
      'Series B',
      'Series C',
      'Series D+',
      'Scaling',
      'Late Stage',
      'Revenue-Generating',
      'IPO Ready',
      'Bridge',
    ];

    return phases.map((phase) {
      return DropdownMenuItem(
        value: phase,
        child: Text(
          phase,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }).toList();
  }
}

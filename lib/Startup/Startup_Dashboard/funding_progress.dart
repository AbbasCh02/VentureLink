import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/startup_profile_provider.dart';

class Funding extends StatefulWidget {
  const Funding({super.key});

  @override
  State<Funding> createState() => _FundingState();
}

class _FundingState extends State<Funding> {
  @override
  void initState() {
    super.initState();
    // Ensure provider is initialized when this widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StartupProfileProvider>();
      if (!provider.isInitialized) {
        provider.initialize();
      }
    });
  }

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
            // Funding Goal Field
            Container(
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
                    borderSide: const BorderSide(
                      color: Color(0xFFffa500),
                      width: 2,
                    ),
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
            ),

            // Funding Phase Dropdown
            Container(
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
                    borderSide: const BorderSide(
                      color: Color(0xFFffa500),
                      width: 2,
                    ),
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
                items: const [
                  DropdownMenuItem(
                    value: 'Idea',
                    child: Text(
                      'Idea',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Pre-Seed',
                    child: Text(
                      'Pre-Seed',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'MVP',
                    child: Text(
                      'MVP',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Seed',
                    child: Text(
                      'Seed',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Product-Market Fit',
                    child: Text(
                      'Product-Market Fit',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Early Growth',
                    child: Text(
                      'Early Growth',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Series A',
                    child: Text(
                      'Series A',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Series B',
                    child: Text(
                      'Series B',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Series C',
                    child: Text(
                      'Series C',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Series D+',
                    child: Text(
                      'Series D+',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Scaling ',
                    child: Text(
                      'Scaling ',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Late Stage ',
                    child: Text(
                      'Late Stage ',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Revenue-Generating',
                    child: Text(
                      'Revenue-Generating',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'IPO Ready',
                    child: Text(
                      'IPO Ready',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Bridge ',
                    child: Text(
                      'Bridge ',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
                onChanged: provider.updateSelectedFundingPhase,
                validator: provider.validateFundingPhase,
              ),
            ),
          ],
        );
      },
    );
  }
}

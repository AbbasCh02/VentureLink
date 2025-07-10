// lib/Investor/Investor_Dashboard/investor_preferences_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/investor_profile_provider.dart';

class InvestorPreferencesPage extends StatefulWidget {
  const InvestorPreferencesPage({super.key});

  @override
  State<InvestorPreferencesPage> createState() =>
      _InvestorPreferencesPageState();
}

class _InvestorPreferencesPageState extends State<InvestorPreferencesPage> {
  List<String> _tempSelectedIndustries = [];
  List<String> _tempSelectedGeographic = [];
  List<String> _tempSelectedStages = [];
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<InvestorProfileProvider>(
      context,
      listen: false,
    );
    // Initialize with current selections
    _tempSelectedIndustries = List.from(provider.selectedIndustries);
    _tempSelectedGeographic = List.from(provider.selectedGeographicFocus);
    _tempSelectedStages = List.from(provider.selectedPreferredStages);
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _savePreferences() async {
    final provider = Provider.of<InvestorProfileProvider>(
      context,
      listen: false,
    );

    try {
      // Update provider with new selections
      provider.updateSelectedIndustries(_tempSelectedIndustries);
      provider.updateSelectedGeographicFocus(_tempSelectedGeographic);
      provider.updateSelectedPreferredStages(_tempSelectedStages);

      // Save to database
      await provider.saveField('industries');
      await provider.saveField('geographicFocus');
      await provider.saveField('preferredStages');

      setState(() {
        _hasChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Preferences saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save preferences: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _resetPreferences() {
    final provider = Provider.of<InvestorProfileProvider>(
      context,
      listen: false,
    );
    setState(() {
      _tempSelectedIndustries = List.from(provider.selectedIndustries);
      _tempSelectedGeographic = List.from(provider.selectedGeographicFocus);
      _hasChanges = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF65c6f4).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF65c6f4)),
            onPressed: () {
              if (_hasChanges) {
                _showUnsavedChangesDialog();
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        title: const Text(
          'Investment Preferences',
          style: TextStyle(
            color: Color(0xFF65c6f4),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            _buildIndustriesSection(),
            const SizedBox(height: 32),
            _buildGeographicSection(),
            const SizedBox(height: 32),
            _buildPreferredStageSection(),
            const SizedBox(height: 32),
            _buildSummaryCard(),
            const SizedBox(height: 24),
            if (_hasChanges) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF65c6f4), Color(0xFF2476C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.tune, color: Colors.black, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Define Your Investment Focus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Select the industries, geographic regions and the investment stages you prefer to invest in. This helps startups find you more easily.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndustriesSection() {
    return _buildCleanSectionCard(
      title: 'Preferred Industries',
      subtitle: '${_tempSelectedIndustries.length} selected',
      icon: Icons.business_center,
      accentColor: const Color(0xFF65c6f4),
      child: _buildEnhancedChipSelection(
        items: InvestorProfileProvider.availableIndustries,
        selectedItems: _tempSelectedIndustries,
        onSelectionChanged: (selected) {
          setState(() {
            _tempSelectedIndustries = selected;
          });
          _markAsChanged();
        },
        emptyMessage: 'Select the industries you prefer to invest in',
        emptyIcon: Icons.business_center,
        accentColor: const Color(0xFF65c6f4),
        sectionType: 'industries',
      ),
    );
  }

  Widget _buildGeographicSection() {
    return _buildCleanSectionCard(
      title: 'Geographic Focus',
      subtitle: '${_tempSelectedGeographic.length} selected',
      icon: Icons.public,
      accentColor: const Color(0xFF65c6f4),
      child: _buildEnhancedChipSelection(
        items: InvestorProfileProvider.availableGeographicRegions,
        selectedItems: _tempSelectedGeographic,
        onSelectionChanged: (selected) {
          setState(() {
            _tempSelectedGeographic = selected;
          });
          _markAsChanged();
        },
        emptyMessage: 'Select the regions you prefer to invest in',
        emptyIcon: Icons.public,
        accentColor: const Color(0xFF65c6f4),
        sectionType: 'regions',
      ),
    );
  }

  Widget _buildPreferredStageSection() {
    return _buildCleanSectionCard(
      title: 'Preferred Investment Stage',
      subtitle: '${_tempSelectedStages.length} selected',
      icon: Icons.trending_up,
      accentColor: const Color(0xFF65c6f4),
      child: _buildEnhancedChipSelection(
        items: InvestorProfileProvider.availableInvestmentStages,
        selectedItems: _tempSelectedStages,
        onSelectionChanged: (selected) {
          setState(() {
            _tempSelectedStages = selected;
          });
          _markAsChanged();
        },
        emptyMessage: 'Select the investment stages you prefer',
        emptyIcon: Icons.trending_up,
        accentColor: const Color(0xFF65c6f4),
        sectionType: 'stages',
      ),
    );
  }

  Widget _buildCleanSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.grey[850]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clean Header - similar to old design but with better spacing
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedChipSelection({
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onSelectionChanged,
    required String emptyMessage,
    required IconData emptyIcon,
    required Color accentColor,
    required String sectionType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clean status bar - less overwhelming than before
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                selectedItems.isNotEmpty
                    ? accentColor.withValues(alpha: 0.1)
                    : Colors.grey[800]!.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  selectedItems.isNotEmpty
                      ? accentColor.withValues(alpha: 0.3)
                      : Colors.grey[700]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selectedItems.isNotEmpty ? Icons.check_circle : emptyIcon,
                color:
                    selectedItems.isNotEmpty ? accentColor : Colors.grey[400],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedItems.isNotEmpty
                      ? 'You have selected ${selectedItems.length} $sectionType'
                      : emptyMessage,
                  style: TextStyle(
                    color:
                        selectedItems.isNotEmpty
                            ? accentColor
                            : Colors.grey[400],
                    fontSize: 14,
                    fontWeight:
                        selectedItems.isNotEmpty
                            ? FontWeight.w500
                            : FontWeight.w400,
                  ),
                ),
              ),
              if (selectedItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${selectedItems.length}',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Elegant Grid Layout - 2 items per row
        if (items.isNotEmpty) ...[
          _buildElegantChipGrid(
            items: items,
            selectedItems: selectedItems,
            onSelectionChanged: onSelectionChanged,
            accentColor: accentColor,
          ),
        ],

        const SizedBox(height: 16),

        // Clean action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () {
                onSelectionChanged(List.from(items));
              },
              icon: Icon(Icons.select_all, size: 16, color: accentColor),
              label: Text('Select All'),
              style: TextButton.styleFrom(
                foregroundColor: accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () {
                onSelectionChanged([]);
              },
              icon: Icon(Icons.clear, size: 16, color: Colors.grey[400]),
              label: Text('Clear All'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[400],
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildElegantChipGrid({
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onSelectionChanged,
    required Color accentColor,
  }) {
    return Column(
      children: [
        // Build rows of 2 items each
        for (int i = 0; i < items.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                // First item in the row
                Expanded(
                  child: _buildElegantChip(
                    item: items[i],
                    isSelected: selectedItems.contains(items[i]),
                    onTap: () {
                      List<String> newSelection = List.from(selectedItems);
                      if (selectedItems.contains(items[i])) {
                        newSelection.remove(items[i]);
                      } else {
                        newSelection.add(items[i]);
                      }
                      onSelectionChanged(newSelection);
                    },
                    accentColor: accentColor,
                  ),
                ),
                // Second item in the row (if exists)
                if (i + 1 < items.length) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildElegantChip(
                      item: items[i + 1],
                      isSelected: selectedItems.contains(items[i + 1]),
                      onTap: () {
                        List<String> newSelection = List.from(selectedItems);
                        if (selectedItems.contains(items[i + 1])) {
                          newSelection.remove(items[i + 1]);
                        } else {
                          newSelection.add(items[i + 1]);
                        }
                        onSelectionChanged(newSelection);
                      },
                      accentColor: accentColor,
                    ),
                  ),
                ] else
                  // Empty space if odd number of items
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildElegantChip({
    required String item,
    required bool isSelected,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? LinearGradient(
                      colors: [Color(0xFF65c6f4), Color(0xFF2476C9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
            color: isSelected ? null : Colors.grey[800],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accentColor : Colors.grey[600]!,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            children: [
              if (isSelected) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
                const SizedBox(width: 12),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, size: 12, color: Colors.grey[400]),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[300],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalSelected =
        _tempSelectedIndustries.length +
        _tempSelectedGeographic.length +
        _tempSelectedStages.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.grey[850]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: const Color(0xFF65c6f4),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Selection Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCleanSummaryRow(
            'Industries',
            _tempSelectedIndustries.length,
            InvestorProfileProvider.availableIndustries.length,
            Icons.business_center,
          ),
          const SizedBox(height: 12),
          _buildCleanSummaryRow(
            'Geographic Regions',
            _tempSelectedGeographic.length,
            InvestorProfileProvider.availableGeographicRegions.length,
            Icons.public,
          ),
          const SizedBox(height: 12),
          _buildCleanSummaryRow(
            'Investment Stages',
            _tempSelectedStages.length,
            InvestorProfileProvider.availableInvestmentStages.length,
            Icons.trending_up,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  totalSelected > 0
                      ? const Color(0xFF65c6f4).withValues(alpha: 0.15)
                      : Colors.orange[900]!.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    totalSelected > 0
                        ? const Color(0xFF65c6f4)
                        : Colors.orange[700]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  totalSelected > 0 ? Icons.check_circle : Icons.warning,
                  color:
                      totalSelected > 0
                          ? const Color(0xFF65c6f4)
                          : Colors.orange[400],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    totalSelected > 0
                        ? 'Good! You have $totalSelected preferences selected.'
                        : 'Select your preferred industries, regions, and investment stages to help startups find you.',
                    style: TextStyle(
                      color:
                          totalSelected > 0
                              ? const Color(0xFF65c6f4)
                              : Colors.orange[300],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanSummaryRow(
    String label,
    int selected,
    int total,
    IconData icon,
  ) {
    final percentage = total > 0 ? (selected / total) : 0.0;

    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[300], fontSize: 14),
          ),
        ),
        Text(
          '$selected / $total',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 60,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color:
                    selected > 0 ? const Color(0xFF65c6f4) : Colors.grey[600],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _resetPreferences,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[600]!),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Reset Changes',
              style: TextStyle(color: Colors.grey[300]),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF65c6f4), Color(0xFF2476C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _savePreferences,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Text(
                    'Save Preferences',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Unsaved Changes',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'You have unsaved changes. Do you want to save them before leaving?',
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back without saving
                },
                child: Text(
                  'Discard',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _resetPreferences();
                },
                child: const Text(
                  'Reset',
                  style: TextStyle(color: Color(0xFF65c6f4)),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  await _savePreferences();
                  if (mounted) {
                    Navigator.pop(context); // Go back after saving
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF65c6f4),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save & Exit'),
              ),
            ],
          ),
    );
  }
}

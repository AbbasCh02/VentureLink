// lib/Startup/Startup_Dashboard/Business_Model_Canvas/business_model_canvas.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/business_model_canvas_provider.dart';
import 'package:venturelink/Startup/Startup_Dashboard/Business_Model_Canvas/channels_page.dart';
import 'package:venturelink/Startup/Startup_Dashboard/Business_Model_Canvas/cost_structure_page.dart';
import 'package:venturelink/Startup/Startup_Dashboard/Business_Model_Canvas/customer_relationships_page.dart';
import 'package:venturelink/Startup/Startup_Dashboard/Business_Model_Canvas/customer_segments_page.dart';
import 'package:venturelink/Startup/Startup_Dashboard/Business_Model_Canvas/key_activities_page.dart';
import 'package:venturelink/Startup/Startup_Dashboard/Business_Model_Canvas/key_partners_page.dart';
import 'package:venturelink/Startup/Startup_Dashboard/Business_Model_Canvas/key_resources_page.dart';
import 'package:venturelink/Startup/Startup_Dashboard/Business_Model_Canvas/revenue_streams_page.dart';
import 'package:venturelink/Startup/Startup_Dashboard/Business_Model_Canvas/value_propositions_page.dart';

class BusinessModelCanvas extends StatefulWidget {
  const BusinessModelCanvas({super.key});

  @override
  State<BusinessModelCanvas> createState() => _BusinessModelCanvasState();
}

class _BusinessModelCanvasState extends State<BusinessModelCanvas>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();

    // Initialize the BMC provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bmcProvider = context.read<BusinessModelCanvasProvider>();
      bmcProvider.initialize();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: _buildAppBar(),
      body: Consumer<BusinessModelCanvasProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFffa500)),
                  SizedBox(height: 16),
                  Text(
                    'Loading Business Model Canvas...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading BMC',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          provider.clearError();
                          provider.refreshFromDatabase();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFffa500),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Retry'),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Go Back',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(provider),
                    const SizedBox(height: 32),
                    _buildProgressSection(provider),
                    const SizedBox(height: 32),
                    _buildBMCSections(provider),
                    const SizedBox(height: 32),
                    _buildActionButtons(provider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.grey[900],
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFFffa500)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Business Model Canvas',
        style: TextStyle(
          color: Color(0xFFffa500),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Consumer<BusinessModelCanvasProvider>(
          builder: (context, provider, child) {
            if (provider.isSaving) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFffa500),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildHeader(BusinessModelCanvasProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFffa500), Color(0xFFff8c00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFffa500).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business_center, color: Colors.black, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Business Model Canvas',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Create a strategic plan for your startup by defining the key elements of your business model.',
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BusinessModelCanvasProvider provider) {
    final completionPercentage = provider.completionPercentage;
    final completedSections = provider.completedSectionsCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[200],
                ),
              ),
              Text(
                '${(completionPercentage * 100).toInt()}% Complete',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFffa500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: completionPercentage,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFffa500)),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Text(
            '$completedSections of 9 sections completed',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          if (provider.hasAnyUnsavedChanges) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.edit, color: Colors.orange[400], size: 16),
                const SizedBox(width: 8),
                Text(
                  'You have unsaved changes',
                  style: TextStyle(color: Colors.orange[400], fontSize: 14),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBMCSections(BusinessModelCanvasProvider provider) {
    final sections = _getBMCSections(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Canvas Sections',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[200],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            return _buildSectionCard(
              title: section['title'],
              description: section['description'],
              icon: section['icon'],
              isComplete: section['isComplete'],
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => section['page']),
                  ),
              hasUnsavedChanges: provider.hasUnsavedChanges(
                section['fieldName'],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isComplete,
    required VoidCallback onTap,
    required bool hasUnsavedChanges,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isComplete ? const Color(0xFFffa500) : Colors.grey[800]!,
            width: isComplete ? 2 : 1,
          ),
          boxShadow:
              isComplete
                  ? [
                    BoxShadow(
                      color: const Color(0xFFffa500).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isComplete
                            ? const Color(0xFFffa500).withValues(alpha: 0.2)
                            : Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color:
                        isComplete ? const Color(0xFFffa500) : Colors.grey[400],
                    size: 20,
                  ),
                ),
                if (isComplete)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFFffa500),
                    size: 20,
                  )
                else if (hasUnsavedChanges)
                  Icon(Icons.edit, color: Colors.orange[400], size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isComplete ? const Color(0xFFffa500) : Colors.grey[200],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                  height: 1.3,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BusinessModelCanvasProvider provider) {
    return Column(
      children: [
        if (provider.hasAnyUnsavedChanges)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  provider.isSaving
                      ? null
                      : () async {
                        final success = await provider.saveAllFields();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'All changes saved successfully!'
                                    : 'Failed to save changes: ${provider.error}',
                              ),
                              backgroundColor:
                                  success
                                      ? const Color(0xFFffa500)
                                      : Colors.red,
                            ),
                          );
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFffa500),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  provider.isSaving
                      ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Saving...'),
                        ],
                      )
                      : const Text(
                        'Save All Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          backgroundColor: Colors.grey[900],
                          title: const Text(
                            'Clear All Data',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'Are you sure you want to clear all Business Model Canvas data? This action cannot be undone.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Clear All'),
                            ),
                          ],
                        ),
                  );

                  if (confirm == true) {
                    await provider.clearAllData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All BMC data cleared'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[600]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Clear All',
                  style: TextStyle(color: Colors.grey[300]),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await provider.refreshFromDatabase();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data refreshed from database'),
                        backgroundColor: Color(0xFFffa500),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFffa500)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Refresh',
                  style: TextStyle(color: Color(0xFFffa500)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getBMCSections(
    BusinessModelCanvasProvider provider,
  ) {
    return [
      {
        'title': 'Key Partners',
        'description': 'Who are your key partners and suppliers?',
        'icon': Icons.handshake_outlined,
        'page': const KeyPartnersPage(),
        'isComplete': provider.isKeyPartnersComplete,
        'fieldName': 'keyPartners',
      },
      {
        'title': 'Key Activities',
        'description':
            'What key activities does your value proposition require?',
        'icon': Icons.settings_outlined,
        'page': const KeyActivitiesPage(),
        'isComplete': provider.isKeyActivitiesComplete,
        'fieldName': 'keyActivities',
      },
      {
        'title': 'Key Resources',
        'description':
            'What key resources does your value proposition require?',
        'icon': Icons.inventory_2_outlined,
        'page': const KeyResourcesPage(),
        'isComplete': provider.isKeyResourcesComplete,
        'fieldName': 'keyResources',
      },
      {
        'title': 'Value Propositions',
        'description': 'What value do you deliver to customers?',
        'icon': Icons.diamond_outlined,
        'page': const ValuePropositionsPage(),
        'isComplete': provider.isValuePropositionsComplete,
        'fieldName': 'valuePropositions',
      },
      {
        'title': 'Customer Relationships',
        'description': 'What type of relationship do you establish?',
        'icon': Icons.favorite_outline,
        'page': const CustomerRelationshipsPage(),
        'isComplete': provider.isCustomerRelationshipsComplete,
        'fieldName': 'customerRelationships',
      },
      {
        'title': 'Customer Segments',
        'description': 'For whom are you creating value?',
        'icon': Icons.group_outlined,
        'page': const CustomerSegmentsPage(),
        'isComplete': provider.isCustomerSegmentsComplete,
        'fieldName': 'customerSegments',
      },
      {
        'title': 'Channels',
        'description': 'Through which channels do you reach customers?',
        'icon': Icons.alt_route_outlined,
        'page': const ChannelsPage(),
        'isComplete': provider.isChannelsComplete,
        'fieldName': 'channels',
      },
      {
        'title': 'Cost Structure',
        'description': 'What are the most important costs?',
        'icon': Icons.account_balance_wallet_outlined,
        'page': const CostStructurePage(),
        'isComplete': provider.isCostStructureComplete,
        'fieldName': 'costStructure',
      },
      {
        'title': 'Revenue Streams',
        'description': 'For what value are customers willing to pay?',
        'icon': Icons.trending_up_outlined,
        'page': const RevenueStreamsPage(),
        'isComplete': provider.isRevenueStreamsComplete,
        'fieldName': 'revenueStreams',
      },
    ];
  }
}

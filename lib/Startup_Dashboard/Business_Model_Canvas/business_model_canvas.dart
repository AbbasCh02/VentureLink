// lib/Startup_Dashboard/Business_Model_Canvas/business_model_canvas.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/business_model_canvas_provider.dart';
import 'package:venturelink/Startup_Dashboard/Business_Model_Canvas/channels_page.dart';
import 'package:venturelink/Startup_Dashboard/Business_Model_Canvas/cost_structure_page.dart';
import 'package:venturelink/Startup_Dashboard/Business_Model_Canvas/customer_relationships_page.dart';
import 'package:venturelink/Startup_Dashboard/Business_Model_Canvas/customer_segments_page.dart';
import 'package:venturelink/Startup_Dashboard/Business_Model_Canvas/key_activities_page.dart';
import 'package:venturelink/Startup_Dashboard/Business_Model_Canvas/key_partners_page.dart';
import 'package:venturelink/Startup_Dashboard/Business_Model_Canvas/key_resources_page.dart';
import 'package:venturelink/Startup_Dashboard/Business_Model_Canvas/revenue_streams_page.dart';
import 'package:venturelink/Startup_Dashboard/Business_Model_Canvas/value_propositions_page.dart';

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

    // Initialize the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BusinessModelCanvasProvider>().initialize();
      }
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
      appBar: _buildElegantAppBar(),
      body: Consumer<BusinessModelCanvasProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFffa500)),
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
                    // Hero Section
                    _buildHeroSection(provider),

                    const SizedBox(height: 40),

                    // Canvas Sections
                    _buildCanvasSections(context, provider),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildElegantAppBar() {
    return AppBar(
      backgroundColor: Colors.grey[900],
      elevation: 0,
      toolbarHeight: 80,
      leading: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFffa500).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFffa500).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFffa500)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFffa500).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dashboard_outlined,
              color: Color(0xFFffa500),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Model Canvas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Design your business strategy',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Consumer<BusinessModelCanvasProvider>(
          builder: (context, provider, child) {
            return Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.clear_all, color: Colors.red),
                onPressed:
                    provider.hasAnyUnsavedChanges
                        ? () => _showClearDialog(context, provider)
                        : null,
                tooltip: 'Clear all data',
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeroSection(BusinessModelCanvasProvider provider) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFffa500).withValues(alpha: 0.1),
            const Color(0xFFff8c00).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFffa500).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Model Canvas',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFffa500),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'The Business Model Canvas is a strategic management template for developing new business models and documenting existing ones. Complete each section to build a comprehensive view of your business.',
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasSections(
    BuildContext context,
    BusinessModelCanvasProvider provider,
  ) {
    final sections = [
      {
        'title': 'Key Partners',
        'description':
            'Who are your key partners & suppliers? What key resources are you acquiring from partners?',
        'icon': Icons.handshake_outlined,
        'page': const KeyPartnersPage(),
        'color': const Color(0xFFffa500),
        'isComplete': provider.isKeyPartnersComplete,
      },
      {
        'title': 'Key Activities',
        'description':
            'What key activities does your value proposition require? Your distribution channels, customer relationships, revenue stream?',
        'icon': Icons.settings_outlined,
        'page': const KeyActivitiesPage(),
        'color': const Color(0xFFffa500),
        'isComplete': provider.isKeyActivitiesComplete,
      },
      {
        'title': 'Key Resources',
        'description':
            'What key resources does your value proposition require? Your distribution channels, customer relationships, revenue streams?',
        'icon': Icons.inventory_2_outlined,
        'page': const KeyResourcesPage(),
        'color': const Color(0xFFffa500),
        'isComplete': provider.isKeyResourcesComplete,
      },
      {
        'title': 'Value Propositions',
        'description':
            'What value do you deliver to customers? Which customer problems are you solving? What bundles of products/services are you offering?',
        'icon': Icons.diamond_outlined,
        'page': const ValuePropositionsPage(),
        'color': const Color(0xFFffa500),
        'isComplete': provider.isValuePropositionsComplete,
      },
      {
        'title': 'Customer Relationships',
        'description':
            'What type of relationship does each customer segment expect you to establish? How do you get, keep & grow customers?',
        'icon': Icons.people_outline,
        'page': const CustomerRelationshipsPage(),
        'color': const Color(0xFFffa500),
        'isComplete': provider.isCustomerRelationshipsComplete,
      },
      {
        'title': 'Customer Segments',
        'description':
            'For whom are you creating value? Who are your most important customers?',
        'icon': Icons.group_outlined,
        'page': const CustomerSegmentsPage(),
        'color': const Color(0xFFffa500),
        'isComplete': provider.isCustomerSegmentsComplete,
      },
      {
        'title': 'Channels',
        'description':
            'Through which channels do your customer segments want to be reached? How your company communicates and reaches its customer segments.',
        'icon': Icons.alt_route_outlined,
        'page': const ChannelsPage(),
        'color': const Color(0xFFffa500),
        'isComplete': provider.isChannelsComplete,
      },
      {
        'title': 'Cost Structure',
        'description':
            'What are the most important costs? All costs incurred to operate your business model and create value.',
        'icon': Icons.trending_down_outlined,
        'page': const CostStructurePage(),
        'color': const Color(0xFFffa500),
        'isComplete': provider.isCostStructureComplete,
      },
      {
        'title': 'Revenue Streams',
        'description':
            'For what value are customers willing to pay? The cash your company generates from each customer segment.',
        'icon': Icons.trending_up_outlined,
        'page': const RevenueStreamsPage(),
        'color': const Color(0xFFffa500),
        'isComplete': provider.isRevenueStreamsComplete,
      },
    ];

    return Column(
      children:
          sections
              .map(
                (section) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCanvasSection(
                    context,
                    section['title'] as String,
                    section['description'] as String,
                    section['icon'] as IconData,
                    section['page'] as Widget,
                    section['color'] as Color,
                    section['isComplete'] as bool,
                    sections.indexOf(section),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildCanvasSection(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Widget page,
    Color color,
    bool isComplete,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[900]!, Colors.grey[850]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isComplete
                          ? Colors.green.withValues(alpha: 0.5)
                          : color.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isComplete ? Colors.green : color).withValues(
                      alpha: 0.1,
                    ),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => page),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: (isComplete ? Colors.green : color)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              icon,
                              color: isComplete ? Colors.green : color,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isComplete ? Colors.green : color,
                                        ),
                                      ),
                                    ),
                                    if (isComplete)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.green.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Complete',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    height: 1.4,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isComplete
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isComplete
                                        ? Colors.green.withValues(alpha: 0.3)
                                        : color.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: isComplete ? Colors.green : color,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showClearDialog(
    BuildContext context,
    BusinessModelCanvasProvider provider,
  ) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Clear All Data',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to clear all Business Model Canvas data? This action cannot be undone.',
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Clear all data synchronously
                  provider.clearAllData();
                  Navigator.pop(dialogContext);

                  // Show success message if the original context is still mounted
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All data cleared successfully'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}

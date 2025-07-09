// lib/Investor/Investor_Dashboard/investor_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/investor_profile_provider.dart';
import '../Providers/investor_company_provider.dart';
import 'investor_profile_page.dart';
import 'investor_company_page.dart';

class InvestorDashboard extends StatefulWidget {
  const InvestorDashboard({super.key});

  @override
  State<InvestorDashboard> createState() => _InvestorDashboardState();
}

class _InvestorDashboardState extends State<InvestorDashboard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize investor providers immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeInvestorProviders();
    });

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _initializeInvestorProviders() async {
    try {
      final investorProfileProvider = context.read<InvestorProfileProvider>();
      final investorCompanyProvider = context.read<InvestorCompaniesProvider>();

      // Initialize providers if not already initialized
      if (!investorProfileProvider.isInitialized) {
        await investorProfileProvider.initialize();
      }
      if (!investorCompanyProvider.isInitialized) {
        await investorCompanyProvider.initialize();
      }
    } catch (e) {
      debugPrint('Error initializing investor providers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: _buildElegantAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(),
                _buildInvestorProfileCard(),
                _buildInvestmentMetricsSection(),
                _buildPortfolioInsightsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildElegantAppBar() {
    return AppBar(
      backgroundColor: Colors.grey[900],
      elevation: 0,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF65c6f4), Color(0xFF65c6f4)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Investor Dashboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF65c6f4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Empower the next big idea—invest in the future today.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF65c6f4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.person_outline,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () async {
              // Navigate to StartupProfilePage
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InvestorProfilePage(),
                ),
              );
            },
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF65c6f4), Color(0xFF2476C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF65c6f4).withValues(alpha: 0.4),
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
              const Icon(
                Icons.card_membership_rounded,
                color: Colors.black,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Welcome to Your Investment Hub',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Discover promising startups, manage your portfolio, and track investment opportunities all in one place.',
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestorProfileCard() {
    return Consumer<InvestorProfileProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1a1a1a),
                Colors.grey[900]!,
                Colors.grey[850]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF65c6f4).withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF65c6f4).withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section with Better Layout
                _buildProfileSection(provider),
                const SizedBox(height: 24),

                // Personal Info Grid
                _buildPersonalInfoGrid(provider),

                const SizedBox(height: 24),

                // Companies Section
                _buildElegantCompaniesSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSection(InvestorProfileProvider provider) {
    return Row(
      children: [
        // Profile Picture
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF65c6f4).withValues(alpha: 0.3),
                const Color(0xFF65c6f4).withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(color: const Color(0xFF65c6f4), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child:
                provider.profileImageUrl != null &&
                        provider.profileImageUrl!.isNotEmpty
                    ? Image.network(
                      provider.profileImageUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildAvatarPlaceholder();
                      },
                    )
                    : _buildAvatarPlaceholder(),
          ),
        ),
        const SizedBox(width: 20),

        // Name and Basic Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full Name
              if (provider.fullName != null &&
                  provider.fullName!.isNotEmpty) ...[
                Text(
                  provider.fullName!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Age and Location in a compact row
              if ((provider.age != null) ||
                  (provider.origin != null && provider.origin!.isNotEmpty)) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    if (provider.age != null)
                      _buildCompactInfoChip(
                        icon: Icons.cake_outlined,
                        label: '${provider.age} years',
                        color: const Color(0xFFFF9800),
                      ),
                    if (provider.origin != null && provider.origin!.isNotEmpty)
                      _buildCompactInfoChip(
                        icon: Icons.location_on_outlined,
                        label: provider.origin!,
                        color: const Color(0xFF4CAF50),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoGrid(InvestorProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bio Section
        _buildElegantInfoCard(
          icon: Icons.person_outline,
          title: 'Professional Bio',
          content: provider.bio ?? 'Add your professional background...',
          isSet: provider.bio != null && provider.bio!.isNotEmpty,
          color: const Color(0xFF65c6f4),
          maxLines: 3,
        ),
        const SizedBox(height: 12),

        // Two column layout for LinkedIn and Portfolio
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildElegantInfoCard(
                  icon: Icons.link_outlined,
                  title: 'LinkedIn',
                  content:
                      provider.linkedinUrl != null &&
                              provider.linkedinUrl!.isNotEmpty
                          ? 'Connected'
                          : 'Not connected',
                  isSet:
                      provider.linkedinUrl != null &&
                      provider.linkedinUrl!.isNotEmpty,
                  color: const Color(0xFF0077B5),
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildElegantInfoCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Portfolio Size',
                  content: provider.portfolioSize?.toString() ?? 'Not set',
                  isSet: provider.portfolioSize != null,
                  color: const Color(0xFFFF9800),
                  isCompact: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildElegantInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required bool isSet,
    required Color color,
    bool isCompact = false,
    int maxLines = 1,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isSet
                  ? color.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          if (isSet)
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: isCompact ? 16 : 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 8 : 10),
          Text(
            content,
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              color: isSet ? Colors.grey[300] : Colors.grey[500],
              fontWeight: isSet ? FontWeight.w500 : FontWeight.normal,
              height: 1.3,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildElegantCompaniesSection() {
    return Consumer<InvestorCompaniesProvider>(
      builder: (context, companiesProvider, child) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1a1a1a),
                Colors.grey[900]!.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.business_outlined,
                      color: Color(0xFF9C27B0),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Companies & Positions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9C27B0),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                companiesProvider.hasCompanies
                    ? '${companiesProvider.companiesCount} companies added'
                    : 'No companies added yet',
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InvestorCompanyPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.visibility_outlined, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'View Companies',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            const Color(0xFF65c6f4).withValues(alpha: 0.3),
            const Color(0xFF65c6f4).withValues(alpha: 0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Icon(
        Icons.person_outline,
        size: 36,
        color: Color(0xFF65c6f4),
      ),
    );
  }

  Widget _buildInvestmentMetricsSection() {
    return Consumer2<InvestorProfileProvider, InvestorCompaniesProvider>(
      builder: (context, profileProvider, companiesProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 16),
              child: Text(
                'Investment Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[200],
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Single Row - 3 cards
            Row(
              children: [
                Expanded(
                  child: _buildCentralizedMetricCard(
                    title: 'Industries',
                    value: profileProvider.selectedIndustries.length.toString(),
                    icon: Icons.category,
                    color: const Color(0xFF65c6f4),
                    subtitle: 'Focus Areas',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCentralizedMetricCard(
                    title: 'Regions',
                    value:
                        profileProvider.selectedGeographicFocus.length
                            .toString(),
                    icon: Icons.public,
                    color: const Color(0xFF4CAF50),
                    subtitle: 'Geographic Reach',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCentralizedMetricCard(
                    title: 'Stages',
                    value:
                        profileProvider.selectedPreferredStages.length
                            .toString(),
                    icon: Icons.timeline,
                    color: const Color(0xFF65c6f4),
                    subtitle: 'Investment Stages',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // Updated metric card with full subtitle text display
  Widget _buildCentralizedMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      height: 210,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.grey[850]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Center everything vertically
        crossAxisAlignment:
            CrossAxisAlignment.center, // Center everything horizontally
        children: [
          // Icon at the top, centered
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),

          // Title, centered
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 8),

          // Value, centered and prominent
          Text(
            value,
            style: TextStyle(
              fontSize: 28, // Slightly larger for better prominence
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),

          // Subtitle if provided, centered with full text display
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11, // Slightly smaller to fit longer text
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // Allow 2 lines for longer text
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPortfolioInsightsCard() {
    return Consumer<InvestorProfileProvider>(
      builder: (context, provider, child) {
        // Debug: Print current data
        debugPrint('🔍 Portfolio Insights Card Data:');
        debugPrint(
          '   - Industries: ${provider.selectedIndustries.length} items: ${provider.selectedIndustries}',
        );
        debugPrint(
          '   - Geographic Focus: ${provider.selectedGeographicFocus.length} items: ${provider.selectedGeographicFocus}',
        );
        debugPrint('   - Profile Complete: ${provider.isProfileComplete}');
        debugPrint('   - Portfolio Size: ${provider.portfolioSize}');

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1a1a1a), Colors.grey[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.insights,
                      color: Color(0xFF4CAF50),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Portfolio Insights',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                  // Add refresh button for debugging
                  IconButton(
                    onPressed: () async {
                      debugPrint('🔄 Manually refreshing provider data...');
                      try {
                        await provider.initialize();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Data refreshed successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Refresh failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.refresh,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Show data if available, otherwise show empty state
              if (provider.selectedIndustries.isNotEmpty ||
                  provider.selectedGeographicFocus.isNotEmpty ||
                  provider.selectedPreferredStages.isNotEmpty ||
                  provider.portfolioSize != null) ...[
                // Industries - Show ALL items as comma-separated text
                if (provider.selectedIndustries.isNotEmpty) ...[
                  _buildInsightRow(
                    icon: Icons.trending_up,
                    title:
                        'Focus Industries (${provider.selectedIndustries.length})',
                    subtitle: provider.selectedIndustries.join(
                      ', ',
                    ), // Show ALL items
                  ),
                  const SizedBox(height: 12),
                ],

                // Geographic Focus - Show ALL items as comma-separated text
                if (provider.selectedGeographicFocus.isNotEmpty) ...[
                  _buildInsightRow(
                    icon: Icons.public,
                    title:
                        'Geographic Focus (${provider.selectedGeographicFocus.length})',
                    subtitle: provider.selectedGeographicFocus.join(
                      ', ',
                    ), // Show ALL items
                  ),
                  const SizedBox(height: 12),
                ],

                // Preferred Stages - Show ALL items as comma-separated text
                if (provider.selectedPreferredStages.isNotEmpty) ...[
                  _buildInsightRow(
                    icon: Icons.timeline,
                    title:
                        'Investment Stages (${provider.selectedPreferredStages.length})',
                    subtitle: provider.selectedPreferredStages.join(
                      ', ',
                    ), // Show ALL items
                  ),
                  const SizedBox(height: 12),
                ],
              ] else ...[
                // Empty state
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[800]?.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          Colors.grey[700]?.withValues(alpha: 0.5) ??
                          Colors.grey,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.insights_outlined,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Investment Data Yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete your investment preferences to see insights here',
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InvestorProfilePage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Setup Preferences',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4CAF50), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

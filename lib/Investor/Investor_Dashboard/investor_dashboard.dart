/**
 * investor_dashboard.dart
 * 
 * Implements the main dashboard interface for investors with an overview of their
 * profile, portfolio insights, and investment metrics.
 * 
 * Features:
 * - Animated UI with entrance effects
 * - Profile overview with personal and professional information
 * - Portfolio insights with investment preferences
 * - Investment metrics with data visualization
 * - Integration with InvestorProfileProvider and InvestorCompaniesProvider
 * - Navigation to profile and company management pages
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/investor_profile_provider.dart';
import '../Providers/investor_company_provider.dart';
import 'investor_profile_page.dart';
import 'company_list_page.dart';
import 'package:url_launcher/url_launcher.dart';

/**
 * InvestorDashboard - Main stateful widget for the investor dashboard page.
 * Presents a comprehensive overview of the investor's profile and portfolio.
 */
class InvestorDashboard extends StatefulWidget {
  const InvestorDashboard({super.key});

  @override
  State<InvestorDashboard> createState() => _InvestorDashboardState();
}

/**
 * State class for InvestorDashboard that manages animations and data loading.
 */
class _InvestorDashboardState extends State<InvestorDashboard>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  /**
   * Initializes state, sets up animations and loads provider data.
   */
  @override
  void initState() {
    super.initState();

    // Initialize investor providers immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeInvestorProviders();
    });

    // Initialize fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Create slide animation with elastic bounce effect
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  /**
   * Cleans up animation controllers when widget is removed.
   */
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /**
   * Initializes the investor profile and company providers.
   * Ensures data is loaded for the dashboard display.
   */
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

  /**
   * Builds the main widget structure with sections.
   */
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
                // Welcome Banner Section
                _buildWelcomeSection(),

                // Investor Profile Card Section
                _buildInvestorProfileCard(),

                // Investment Metrics Section
                _buildInvestmentMetricsSection(),

                // Portfolio Insights Card Section
                _buildPortfolioInsightsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /**
   * Builds the elegant app bar with title and profile button.
   * 
   * @return A styled AppBar widget
   */
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
                    colors: [Color(0xFF65c6f4), Color(0xFF2476C9)],
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
            gradient: const LinearGradient(
              colors: [Color(0xFF65c6f4), Color(0xFF2476C9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
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

  /**
   * Builds the welcome section with introduction and key features.
   * 
   * @return A styled welcome banner widget
   */
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

  /**
   * Builds the investor profile card with personal and professional information.
   * 
   * @return A styled profile card widget
   */
  Widget _buildInvestorProfileCard() {
    return Consumer<InvestorProfileProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            padding: const EdgeInsets.all(16),
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

  /**
   * Builds the profile section with avatar and basic information.
   * 
   * @param provider The InvestorProfileProvider for state access
   * @return A styled profile header widget
   */
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
                        label: '${provider.age} yrs',
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

  /**
   * Creates a compact info chip with icon and label.
   * 
   * @param icon The icon to display
   * @param label The text label
   * @param color The accent color for the chip
   * @return A styled info chip widget
   */
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

  /**
   * Builds the personal information grid with bio and other details.
   * 
   * @param provider The InvestorProfileProvider for state access
   * @return A grid of personal information cards
   */
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
                flex: 2, // LinkedIn takes 2 parts
                child: GestureDetector(
                  onTap: () {
                    if (provider.linkedinUrl != null &&
                        provider.linkedinUrl!.isNotEmpty) {
                      _launchLinkedIn(provider.linkedinUrl!);
                    }
                  },
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
                    color: const Color(0xFF4CAF50),
                    isCompact: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2, // Portfolio takes 3 parts (wider)
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

  /**
   * Launches LinkedIn profile URL in external browser.
   * 
   * @param url The LinkedIn profile URL to open
   */
  Future<void> _launchLinkedIn(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open LinkedIn profile')),
        );
      }
    }
  }

  /**
   * Creates a styled information card with title and content.
   * 
   * @param icon The card icon
   * @param title The card title
   * @param content The card content text
   * @param isSet Whether the content has been set
   * @param color The accent color for the card
   * @param isCompact Whether to use compact layout
   * @param maxLines Maximum number of content text lines
   * @return A styled information card widget
   */
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
              const SizedBox(width: 8),
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
              fontSize: isCompact ? 12 : 13,
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

  /**
   * Builds the companies section with count and navigation button.
   * 
   * @return A styled companies section widget with action button
   */
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
              color: const Color(0xFF65c6f4).withValues(alpha: 0.4),
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
                      color: const Color(0xFF65c6f4).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.business_outlined,
                      color: Color(0xFF65c6f4),
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
                        color: Color(0xFF65c6f4),
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
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF65c6f4), Color(0xFF2476C9)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CompaniesListPage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.list_alt, size: 18, color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              'View Companies',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /**
   * Creates a placeholder avatar for when profile image is not available.
   * 
   * @return A styled avatar placeholder widget
   */
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

  /**
   * Builds the investment metrics section with key indicators.
   * 
   * @return A section with investment metric cards
   */
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

  /**
   * Creates a centralized metric card with title, value and subtitle.
   * 
   * @param title The metric title
   * @param value The metric value
   * @param icon The metric icon
   * @param color The accent color for the card
   * @param subtitle Optional subtitle for additional context
   * @return A styled metric card widget
   */
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
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

  /**
   * Builds the portfolio insights card with investment preferences.
   * 
   * @return A section with detailed portfolio insights or empty state
   */
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

  /**
   * Creates a row with icon, title and subtitle for portfolio insights.
   * 
   * @param icon The row icon
   * @param title The row title
   * @param subtitle The row subtitle or content
   * @return A styled insight row widget
   */
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

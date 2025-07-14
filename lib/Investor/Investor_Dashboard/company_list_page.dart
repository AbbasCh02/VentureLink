/**
 * companies_list_page.dart
 * 
 * Implements a visually rich interface for investors to browse and search their
 * portfolio of companies and professional positions.
 * 
 * Features:
 * - Animated UI components with staggered entrance effects
 * - Real-time search filtering of companies
 * - Multiple state handling (loading, empty, error, content)
 * - Interactive company cards with website linking
 * - Visual distinction between active and past positions
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Providers/investor_company_provider.dart';

/**
 * CompaniesListPage - Main stateful widget for displaying a list of
 * companies in an investor's portfolio.
 */
class CompaniesListPage extends StatefulWidget {
  const CompaniesListPage({super.key});

  @override
  State<CompaniesListPage> createState() => _CompaniesListPageState();
}

/**
 * State class for CompaniesListPage that manages animations,
 * search functionality, and data loading.
 */
class _CompaniesListPageState extends State<CompaniesListPage>
    with TickerProviderStateMixin {
  // Search state
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Loading state
  bool _isInitializing = true;

  /**
   * Initializes state including animation controllers and triggers data loading.
   */
  @override
  void initState() {
    super.initState();
    // Setup fade animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Initialize provider after initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  /**
   * Loads company data from the provider.
   * Handles initial loading and refresh operations.
   */
  Future<void> _initializeProvider() async {
    try {
      final provider = Provider.of<InvestorCompaniesProvider>(
        context,
        listen: false,
      );

      // Only initialize if not already done
      if (!provider.isInitialized) {
        await provider.initialize();
      }

      // Update UI state when complete
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        _animationController.forward(); // Start entrance animation
      }
    } catch (e) {
      debugPrint('Error initializing provider: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  /**
   * Cleans up resources when widget is removed.
   */
  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /**
   * Builds the main widget structure with appropriate state handling.
   */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Consumer<InvestorCompaniesProvider>(
        builder: (context, provider, child) {
          // Show loading state during initial setup
          if (_isInitializing ||
              (provider.isLoading && !provider.isInitialized)) {
            return _buildLoadingState();
          }

          // Show error state for non-initialization errors
          if (provider.error != null &&
              provider.isInitialized &&
              !provider.isLoading) {
            return _buildErrorState(provider.error!, provider);
          }

          // Show main content when data is ready
          return _buildMainContent(provider);
        },
      ),
    );
  }

  /**
   * Builds the main content with filtered company list.
   * 
   * @param provider The data provider containing company information
   * @return Widget containing the main content structure
   */
  Widget _buildMainContent(InvestorCompaniesProvider provider) {
    // Filter companies based on search query
    final filteredCompanies =
        provider.companies.where((company) {
          if (_searchQuery.isEmpty) return true;
          return company.companyName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              company.title.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          _buildSliverAppBar(provider),
          SliverToBoxAdapter(
            child: _buildSearchSection(filteredCompanies.length),
          ),
          filteredCompanies.isEmpty
              ? SliverToBoxAdapter(
                child: _buildEmptyState(provider.companies.isEmpty),
              )
              : SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final company = filteredCompanies[index];
                    final isCurrent = provider.currentCompanies.any(
                      (current) => current.id == company.id,
                    );
                    return _buildCompanyCard(company, isCurrent, index);
                  }, childCount: filteredCompanies.length),
                ),
              ),
        ],
      ),
    );
  }

  /**
   * Builds the expandable app bar with title and statistics.
   * 
   * @param provider The data provider containing company counts
   * @return A SliverAppBar widget with custom styling
   */
  Widget _buildSliverAppBar(InvestorCompaniesProvider provider) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0a0a0a),
      elevation: 0,
      // Styled back button
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1a1a1a), const Color(0xFF2a2a2a)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF65c6f4).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF65c6f4).withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // Expandable content area with gradient background
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF65c6f4).withValues(alpha: 0.15),
                const Color(0xFF2196F3).withValues(alpha: 0.08),
                const Color(0xFF1a1a1a).withValues(alpha: 0.3),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(80, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Page title
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Companies & Positions',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Statistic badges
                  Row(
                    children: [
                      // Total companies badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF65c6f4), Color(0xFF2196F3)],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF65c6f4,
                              ).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.pie_chart_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${provider.companiesCount} Companies',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Active companies badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFF4CAF50,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.trending_up_rounded,
                              color: Color(0xFF4CAF50),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${provider.currentCompanies.length} Active',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4CAF50),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
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
  }

  /**
   * Builds the search input field with result count indicator.
   * 
   * @param resultCount Number of matching search results
   * @return A widget containing the search interface
   */
  Widget _buildSearchSection(int resultCount) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Search input field
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1e1e1e), const Color(0xFF2a2a2a)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    _searchQuery.isEmpty
                        ? const Color(0xFF65c6f4).withValues(alpha: 0.2)
                        : const Color(0xFF65c6f4).withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF65c6f4).withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search companies, positions...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.search_rounded,
                    color: const Color(0xFF65c6f4),
                    size: 24,
                  ),
                ),
                // Clear button for search field
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: Colors.grey[500],
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Results count indicator (only shown when searching)
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF65c6f4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$resultCount result${resultCount != 1 ? 's' : ''} found',
                  style: const TextStyle(
                    color: Color(0xFF65c6f4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /**
   * Builds an individual company card with animation and styling.
   * 
   * @param company The company data to display
   * @param isCurrent Whether this is a current/active position
   * @param index Position in the list (for staggered animation)
   * @return An animated company card widget
   */
  Widget _buildCompanyCard(InvestorCompany company, bool isCurrent, int index) {
    return TweenAnimationBuilder<double>(
      // Staggered animation timing based on position in list
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 50), // Slide-up effect
          child: Opacity(
            opacity: value.clamp(0.0, 1.0), // Fade-in effect
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              // Card styling with conditional formatting for active positions
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      isCurrent
                          ? [
                            const Color(0xFF65c6f4).withValues(alpha: 0.15),
                            const Color(0xFF2196F3).withValues(alpha: 0.1),
                            const Color(0xFF1a1a1a),
                          ]
                          : [
                            const Color(0xFF1a1a1a),
                            const Color(0xFF242424),
                            const Color(0xFF1e1e1e),
                          ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color:
                      isCurrent
                          ? const Color(0xFF65c6f4).withValues(alpha: 0.8)
                          : const Color(0xFF65c6f4).withValues(alpha: 0.2),
                  width: isCurrent ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isCurrent
                            ? const Color(0xFF65c6f4).withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.3),
                    blurRadius: isCurrent ? 25 : 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with avatar and title
                    Row(
                      children: [
                        // Company avatar with first letter
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF65c6f4),
                                const Color(0xFF2196F3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF65c6f4,
                                ).withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              company.companyName.isNotEmpty
                                  ? company.companyName[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Company details (name, title, active badge)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      company.companyName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Active badge (only for current positions)
                                  if (isCurrent)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF65c6f4),
                                            Color(0xFF2196F3),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF65c6f4,
                                            ).withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                company.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isCurrent
                                          ? const Color(0xFF65c6f4)
                                          : Colors.grey[400],
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Website section (only shown if available)
                    if (company.website.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF65c6f4,
                          ).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(
                              0xFF65c6f4,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Website icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF65c6f4,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.language_rounded,
                                color: Color(0xFF65c6f4),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Website link
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Website',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF65c6f4),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  GestureDetector(
                                    onTap:
                                        () => _launchWebsite(company.website),
                                    child: Text(
                                      company.website,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color(0xFF65c6f4),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // External link button
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF65c6f4,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: GestureDetector(
                                onTap: () => _launchWebsite(company.website),
                                child: const Icon(
                                  Icons.open_in_new_rounded,
                                  color: Color(0xFF65c6f4),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Date added information
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: Colors.grey[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Added ${_formatDate(company.dateAdded)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /**
   * Builds an empty state widget for when no companies are found.
   * Adapts messaging based on whether no companies exist or none match the search.
   * 
   * @param isCompletelyEmpty Whether there are no companies at all
   * @return A widget displaying the appropriate empty state
   */
  Widget _buildEmptyState(bool isCompletelyEmpty) {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1a1a1a), const Color(0xFF242424)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFF65c6f4).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon container
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF65c6f4).withValues(alpha: 0.2),
                  const Color(0xFF2196F3).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              isCompletelyEmpty
                  ? Icons
                      .business_center_rounded // Empty portfolio
                  : Icons.search_off_rounded, // No search results
              size: 50,
              color: const Color(0xFF65c6f4),
            ),
          ),
          const SizedBox(height: 24),

          // Empty state title
          Text(
            isCompletelyEmpty
                ? 'No companies in your portfolio'
                : 'No companies match your search',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Empty state description
          Text(
            isCompletelyEmpty
                ? 'Start building your professional portfolio by adding your company positions and investments'
                : 'Try adjusting your search terms or browse all companies',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[400],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // Add company button (only shown when portfolio is completely empty)
          if (isCompletelyEmpty) ...[
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF65c6f4), Color(0xFF2196F3)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF65c6f4).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'Add Your First Company',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /**
   * Builds a loading state widget with progress indicator.
   * 
   * @return A widget displaying loading animation and message
   */
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF65c6f4).withValues(alpha: 0.3),
                  const Color(0xFF2196F3).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF65c6f4)),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading your portfolio...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we fetch your companies',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  /**
  * Builds an error state widget with message and retry button.
  * 
  * @param error The error message to display
  * @param provider The data provider for retry functionality
  * @return A widget displaying the error state
  */
  Widget _buildErrorState(String error, InvestorCompaniesProvider provider) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red[900]!.withValues(alpha: 0.2),
              Colors.red[800]!.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red[600]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 60),
            const SizedBox(height: 20),
            Text(
              'Unable to load companies',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                setState(() {
                  _isInitializing = true;
                });
                await _initializeProvider();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  /**
  * Formats a date into a human-readable relative time string.
  * 
  * @param date The date to format
  * @return A string like "today", "3 days ago", "2 months ago", etc.
  */
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /**
  * Launches a website URL with validation and error handling.
  * 
  * @param url The website URL to launch
  */
  Future<void> _launchWebsite(String url) async {
    try {
      // Clean and validate URL
      String cleanUrl = url.trim();
      if (cleanUrl.isEmpty) {
        _showErrorSnackBar('Website URL is empty');
        return;
      }

      // Add protocol if missing
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      // Validate URL format
      final uri = Uri.tryParse(cleanUrl);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        _showErrorSnackBar('Invalid website URL format');
        return;
      }

      // Launch URL in external browser
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching website: $e');
      _showErrorSnackBar('Failed to open website: ${e.toString()}');
    }
  }

  /**
  * Shows an error message in a snackbar.
  * 
  * @param message The error message to display
  */
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

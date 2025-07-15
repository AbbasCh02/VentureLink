import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:venturelink/Startup/Startup_Dashboard/startup_profile_page.dart';
import '../Providers/startup_profile_overview_provider.dart';
import '../Providers/startup_profile_provider.dart';
import '../Providers/business_model_canvas_provider.dart';
import '../Providers/team_members_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/**
 * Implements a comprehensive startup dashboard for complete entrepreneurial journey management.
 * Provides centralized view of all startup components including profile, funding, team, and business model.
 * 
 * Features:
 * - Centralized dashboard overview with animated transitions
 * - Real-time profile overview with completion tracking
 * - Interactive company profile management with photo support
 * - Team members display with LinkedIn integration
 * - Pitch deck files visualization and management
 * - Business Model Canvas progress tracking
 * - Key metrics display for funding and growth stages
 * - Professional gradient styling with orange theme (#FFa500)
 * - Responsive layout with smooth animations
 * - Error handling and user feedback mechanisms
 * - Navigation integration with all startup modules
 * - Dynamic data loading from multiple provider sources
 * - Status indicators for profile completion and data availability
 */

/**
 * StartupDashboard - Main dashboard widget for startup management ecosystem.
 * Integrates all startup components into a unified management interface.
 */
class StartupDashboard extends StatefulWidget {
  const StartupDashboard({super.key});

  @override
  State<StartupDashboard> createState() => _StartupDashboardState();
}

/**
 * _StartupDashboardState - State management for the comprehensive startup dashboard.
 * Manages animations, provider integrations, and component interactions across the startup ecosystem.
 */
class _StartupDashboardState extends State<StartupDashboard>
    with TickerProviderStateMixin {
  /**
   * Animation controllers for smooth dashboard transitions and visual feedback.
   */
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  /**
   * Initializes the dashboard state with animation controllers and configurations.
   * Sets up fade and slide animations for enhanced user experience.
   */
  @override
  void initState() {
    super.initState();
    // Initialize fade animation controller for opacity transitions
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    // Initialize slide animation controller for position transitions
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Configure fade animation from transparent to opaque
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Configure slide animation from bottom to center with elastic effect
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    // Start animations immediately on dashboard load
    _fadeController.forward();
    _slideController.forward();
  }

  /**
   * Disposes animation controllers to prevent memory leaks.
   */
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /**
   * Builds the elegant app bar with branding and navigation.
   * Features gradient styling, rocket icon, and profile navigation button.
   * 
   * @return PreferredSizeWidget containing the styled app bar with navigation
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
                    colors: [
                      Color(0xFFffa500),
                      Color(0xFFff8c00),
                    ], // Gradient variation for visual appeal
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFffa500).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  color: Colors.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Startup Dashboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFffa500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Your entrepreneurial journey starts here',
            style: TextStyle(
              fontSize: 13,
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
              colors: [
                Color(0xFFffa500),
                Color(0xFFff8c00),
              ], // Matching gradient for consistency
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFffa500).withValues(alpha: 0.3),
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
              // Navigate to StartupProfilePage for detailed management
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StartupProfilePage(),
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
   * Builds the default profile icon for users without uploaded photos.
   * Features gradient background with person icon and status indicators.
   * 
   * @return Widget containing the styled default profile icon
   */
  Widget _buildDefaultProfileIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[800]!, Colors.grey[900]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Stack(
        children: [
          // Background pattern with subtle orange overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFffa500).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Main person icon with status text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person,
                  color: const Color(0xFFffa500).withValues(alpha: 0.7),
                  size: 40,
                ),
                const SizedBox(height: 4),
                Text(
                  'No Photo',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /**
   * Builds the comprehensive profile overview card with company information.
   * Integrates data from both profile overview and startup profile providers.
   * Displays company details, profile photo, and team member preview.
   * 
   * @return Widget containing the complete profile overview section
   */
  Widget _buildProfileOverviewCard() {
    return Consumer<StartupProfileOverviewProvider>(
      builder: (context, profileProvider, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[900]!, Colors.grey[850]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFffa500).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFffa500).withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with company branding
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFffa500).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.business_center,
                      color: Color(0xFFffa500),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Company Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFffa500),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Profile picture section with status indicators
              Center(
                child: Consumer<StartupProfileProvider>(
                  builder: (context, startupProvider, child) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFffa500).withValues(alpha: 0.2),
                                const Color(0xFFff8c00).withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: const Color(
                                0xFFffa500,
                              ).withValues(alpha: 0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFffa500,
                                ).withValues(alpha: 0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(48),
                            child: _buildDashboardProfileImage(startupProvider),
                          ),
                        ),

                        // Profile completion status indicator
                        if (startupProvider.hasProfileImage)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Profile information grid with comprehensive company data
              Column(
                children: [
                  // First row: Company name and region
                  Row(
                    children: [
                      Expanded(
                        child: _buildProfileInfoItem(
                          'Company',
                          profileProvider.companyName?.isNotEmpty == true
                              ? profileProvider.companyName!
                              : 'Not Set',
                          Icons.business,
                          const Color(0xFFffa500),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildProfileInfoItem(
                          'Region',
                          profileProvider.region?.isNotEmpty == true
                              ? profileProvider.region!
                              : 'Not Set',
                          Icons.location_on,
                          const Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Idea description section (full width with expanded text support)
                  Consumer<StartupProfileProvider>(
                    builder: (context, startupProvider, child) {
                      return _buildProfileInfoItem(
                        'Idea Description',
                        startupProvider.ideaDescription?.isNotEmpty == true
                            ? startupProvider.ideaDescription!
                            : 'Not Set',
                        Icons.lightbulb,
                        Colors.redAccent,
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  // Industry section (full width)
                  _buildProfileInfoItem(
                    'Industry',
                    profileProvider.industry?.isNotEmpty == true
                        ? profileProvider.industry!
                        : 'Not Set',
                    Icons.category,
                    const Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 12),
                  // Company tagline section (full width)
                  _buildProfileInfoItem(
                    'Tagline',
                    profileProvider.tagline?.isNotEmpty == true
                        ? profileProvider.tagline!
                        : 'Not Set',
                    Icons.format_quote,
                    const Color(0xFF9C27B0),
                  ),
                  const SizedBox(height: 12),
                  _buildTeamMembersCard(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /**
   * Builds the team members card with LinkedIn integration and role display.
   * Shows team member avatars, names, roles, and LinkedIn connectivity status.
   * 
   * @return Widget containing the team members preview section
   */
  Widget _buildTeamMembersCard() {
    return Consumer<TeamMembersProvider>(
      builder: (context, teamProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[800]!.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with team icon and count
              Row(
                children: [
                  Icon(Icons.group, color: Color(0xFF4CAF50), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Team Members',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (teamProvider.hasTeamMembers) ...[
                // Team members horizontal scroll with roles and LinkedIn integration
                SizedBox(
                  height: 90, // Increased height to accommodate role text
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: teamProvider.teamMembers.length,
                    itemBuilder: (context, index) {
                      final member = teamProvider.teamMembers[index];
                      return GestureDetector(
                        onTap:
                            member.linkedin.isNotEmpty
                                ? () => _launchLinkedIn(member.linkedin)
                                : null,
                        child: MouseRegion(
                          cursor:
                              member.linkedin.isNotEmpty
                                  ? SystemMouseCursors.click
                                  : SystemMouseCursors.basic,
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color:
                                        member.linkedin.isNotEmpty
                                            ? const Color(
                                              0xFF4CAF50,
                                            ).withValues(alpha: 0.2)
                                            : Colors.grey.withValues(
                                              alpha: 0.2,
                                            ),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color:
                                          member.linkedin.isNotEmpty
                                              ? const Color(0xFF4CAF50)
                                              : Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.grey[700],
                                          child: Icon(
                                            // Default profile icon for team members
                                            Icons.person,
                                            color: Colors.grey[400],
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      // LinkedIn connectivity indicator
                                      if (member.linkedin.isNotEmpty)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.blue,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.link,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Member name with LinkedIn status styling
                                Text(
                                  member.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        member.linkedin.isNotEmpty
                                            ? const Color(0xFF4CAF50)
                                            : Colors.grey[400],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(
                                  height: 2,
                                ), // Space between name and role
                                // Position/Role display
                                Text(
                                  member.role,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                // Empty state for team members
                Text(
                  'No team members added yet',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /**
   * Builds the pitch deck files card with upload status and file management.
   * Displays uploaded files, submission status, and file count indicators.
   * 
   * @return Widget containing the pitch deck files management section
   */
  Widget _buildPitchDeckFilesCard() {
    return Consumer<StartupProfileProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 32),
          padding: const EdgeInsets.all(16), // Optimized padding
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[900]!, Colors.grey[850]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  provider.hasPitchDeckFiles
                      ? const Color(0xFFffa500).withValues(alpha: 0.5)
                      : Colors.grey[700]!.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    provider.hasPitchDeckFiles
                        ? const Color(0xFFffa500).withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Optimize for content size
            children: [
              // Header with upload status and file count
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            provider.hasPitchDeckFiles
                                ? [
                                  const Color(0xFFffa500),
                                  const Color(0xFFff8c00),
                                ]
                                : [Colors.grey[600]!, Colors.grey[700]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.upload_file,
                      color:
                          provider.hasPitchDeckFiles
                              ? Colors.black
                              : Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pitch Deck Files',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                provider.hasPitchDeckFiles
                                    ? const Color(0xFFffa500)
                                    : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildPitchDeckStatus(provider),
                      ],
                    ),
                  ),

                  // File count badge with dynamic styling
                  if (provider.hasPitchDeckFiles)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFffa500).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFffa500).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        '${provider.totalPitchDeckFilesCount} files',
                        style: const TextStyle(
                          color: Color(0xFFffa500),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16), // Optimized spacing
              // Files display section or empty state
              if (provider.hasPitchDeckFiles) ...[
                // Files preview with constrained height for optimization
                SizedBox(
                  height: 200, // Optimized height for file previews
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(
                      bottom: 4, // Reduced padding
                    ),
                    itemCount: provider.pitchDeckThumbnails.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: provider.pitchDeckThumbnails[index],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12), // Optimized spacing
                // Submission status with dynamic feedback
                if (provider.isPitchDeckSubmitted) ...[
                  Container(
                    padding: const EdgeInsets.all(10), // Optimized padding
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[400],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pitch Deck Submitted',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (provider.pitchDeckSubmissionDate != null)
                                Text(
                                  'Submitted: ${_formatDate(provider.pitchDeckSubmissionDate!)}',
                                  style: TextStyle(
                                    color: Colors.green[400],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Upload guidance for pending submissions
                  Container(
                    padding: const EdgeInsets.all(10), // Optimized padding
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[400],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ready to upload? Go to Pitch Deck section to add more files.',
                            style: TextStyle(
                              color: Colors.blue[400],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                // Empty state with upload guidance
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20), // Optimized padding
                  decoration: BoxDecoration(
                    color: Colors.grey[800]!.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[600]!.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Optimize for content
                    children: [
                      Icon(
                        Icons.upload_file,
                        size: 40, // Optimized icon size
                        color: Colors.grey[500],
                      ),
                      const SizedBox(height: 8), // Optimized spacing
                      Text(
                        'No pitch deck files uploaded yet',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6), // Optimized spacing
                      Text(
                        'Upload your pitch deck to showcase your startup',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        textAlign: TextAlign.center,
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
   * Builds individual profile information items with dynamic styling.
   * Supports both single-line and multi-line content based on information type.
   * 
   * @param title The display title for the information field
   * @param value The value content to display
   * @param icon The leading icon for visual identification
   * @param color The theme color for the field styling
   * @return Widget containing the styled profile information item
   */
  Widget _buildProfileInfoItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: value == 'Not Set' ? Colors.grey[500] : Colors.white,
              height:
                  title == 'Idea Description'
                      ? 1.4
                      : 1.0, // Better line height for idea description
            ),
            overflow:
                title == 'Idea Description'
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
            maxLines:
                title == 'Idea Description'
                    ? null
                    : 1, // Allow multiple lines for idea description
          ),
        ],
      ),
    );
  }

  /**
   * Builds the dashboard profile image with priority handling for different image sources.
   * Handles local files, network URLs, and fallback to default icon with loading states.
   * 
   * @param provider The StartupProfileProvider instance for image data access
   * @return Widget containing the profile image or default placeholder
   */
  Widget _buildDashboardProfileImage(StartupProfileProvider provider) {
    // Priority: Local file > Network URL > Placeholder
    if (provider.profileImage != null) {
      // Show local file (newly picked image)
      return Image.file(
        provider.profileImage!,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultProfileIcon();
        },
      );
    } else if (provider.profileImageUrl != null &&
        provider.profileImageUrl!.isNotEmpty) {
      // Show network image (loaded from database)
      return Image.network(
        provider.profileImageUrl!,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
              color: const Color(0xFFffa500),
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultProfileIcon();
        },
      );
    } else {
      // Show placeholder when no image is available
      return _buildDefaultProfileIcon();
    }
  }

  /**
   * Builds the pitch deck status indicator with dynamic styling based on upload state.
   * Shows different status messages and colors for various submission states.
   * 
   * @param provider The StartupProfileProvider instance for pitch deck status
   * @return Widget containing the status indicator with appropriate styling
   */
  Widget _buildPitchDeckStatus(StartupProfileProvider provider) {
    if (!provider.hasPitchDeckFiles) {
      return Row(
        children: [
          Icon(Icons.pending, color: Colors.grey[400], size: 12),
          const SizedBox(width: 4),
          Text(
            'No files uploaded',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else if (provider.isPitchDeckSubmitted) {
      return Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[400], size: 12),
          const SizedBox(width: 4),
          Text(
            'Submitted',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Icon(Icons.upload, color: Colors.orange[400], size: 12),
          const SizedBox(width: 4),
          Text(
            'Ready to submit',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }

  /**
   * Formats date for display in submission status.
   * 
   * @param date The DateTime to format
   * @return String formatted date in DD/MM/YYYY format
   */
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /**
   * Builds metric cards for key startup performance indicators.
   * Features gradient styling, icons, and optional subtitle information.
   * 
   * @param title The metric title
   * @param value The metric value to display
   * @param icon The icon representing the metric
   * @param color The theme color for the metric card
   * @param subtitle Optional subtitle for additional context
   * @return Widget containing the styled metric card
   */
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Flexible(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[900]!, Colors.grey[850]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.3),
                          color.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /**
   * Builds the welcome section with gradient styling and motivational messaging.
   * Provides introduction and overview of dashboard functionality.
   * 
   * @return Widget containing the welcome section with branding
   */
  Widget _buildWelcomeSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
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
            color: const Color(0xFFffa500).withValues(alpha: 0.4),
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
              const Icon(Icons.start, color: Colors.black, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Welcome to Your Dashboard',
                  style: TextStyle(
                    fontSize: 18,
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
            'Track your startup\'s progress, manage funding, and connect with investors all in one place.',
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }

  /**
   * Builds the Business Model Canvas card with completion tracking and section previews.
   * Shows progress, completed sections, and provides navigation to canvas management.
   * 
   * @return Widget containing the Business Model Canvas overview section
   */
  Widget _buildBusinessModelCanvasCard() {
    return Consumer<BusinessModelCanvasProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Container(
            margin: const EdgeInsets.only(bottom: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[900]!, Colors.grey[850]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  SizedBox(height: 16),
                  Text(
                    'Loading Business Model Canvas...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[900]!, Colors.grey[850]!],
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
              // Header with completion status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.dashboard_customize,
                      color: Color(0xFF4CAF50),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Business Model Canvas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                  // Completion status badge with dynamic styling
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          provider.completionPercentage == 1.0
                              ? Colors.green.withValues(alpha: 0.2)
                              : const Color(0xFF4CAF50).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            provider.completionPercentage == 1.0
                                ? Colors.green.withValues(alpha: 0.5)
                                : const Color(
                                  0xFF4CAF50,
                                ).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          provider.completionPercentage == 1.0
                              ? Icons.check_circle
                              : Icons.analytics,
                          color:
                              provider.completionPercentage == 1.0
                                  ? Colors.green[400]
                                  : const Color(0xFF4CAF50),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          provider.completionPercentage == 1.0
                              ? 'Complete'
                              : '${provider.completionPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color:
                                provider.completionPercentage == 1.0
                                    ? Colors.green[400]
                                    : const Color(0xFF4CAF50),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress section with completed sections count
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.task_alt,
                          color: Color(0xFF4CAF50),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${provider.completedSectionsCount} of 9 sections completed',
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Key sections preview (if any are completed)
              if (provider.completedSectionsCount > 0) ...[
                Text(
                  'Completed Sections:',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  height: 60,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (provider.isKeyPartnersComplete)
                          _buildCompletedSectionChip(
                            'Key Partners',
                            Icons.handshake_outlined,
                          ),
                        if (provider.isKeyActivitiesComplete)
                          _buildCompletedSectionChip(
                            'Key Activities',
                            Icons.settings_outlined,
                          ),
                        if (provider.isKeyResourcesComplete)
                          _buildCompletedSectionChip(
                            'Key Resources',
                            Icons.inventory_2_outlined,
                          ),
                        if (provider.isValuePropositionsComplete)
                          _buildCompletedSectionChip(
                            'Value Propositions',
                            Icons.diamond_outlined,
                          ),
                        if (provider.isCustomerRelationshipsComplete)
                          _buildCompletedSectionChip(
                            'Customer Relations',
                            Icons.favorite_outline,
                          ),
                        if (provider.isCustomerSegmentsComplete)
                          _buildCompletedSectionChip(
                            'Customer Segments',
                            Icons.group_outlined,
                          ),
                        if (provider.isChannelsComplete)
                          _buildCompletedSectionChip(
                            'Channels',
                            Icons.alt_route_outlined,
                          ),
                        if (provider.isCostStructureComplete)
                          _buildCompletedSectionChip(
                            'Cost Structure',
                            Icons.trending_down_outlined,
                          ),
                        if (provider.isRevenueStreamsComplete)
                          _buildCompletedSectionChip(
                            'Revenue Streams',
                            Icons.trending_up_outlined,
                          ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[800]!.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[600]!.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 40,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Build Your Business Model',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create a strategic plan for your startup with the Business Model Canvas',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        textAlign: TextAlign.center,
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
   * Builds completed section chips for Business Model Canvas progress display.
   * Shows individual section completion with icons and confirmation indicators.
   * 
   * @param title The section title to display
   * @param icon The icon representing the section
   * @return Widget containing the styled completion chip
   */
  Widget _buildCompletedSectionChip(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.green[400], size: 16),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: Colors.green[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.check_circle, color: Colors.green[400], size: 14),
        ],
      ),
    );
  }

  /**
   * Launches LinkedIn URL with proper validation and error handling.
   * Handles URL formatting, validation, and provides user feedback on errors.
   * 
   * @param url The LinkedIn URL to launch
   */
  Future<void> _launchLinkedIn(String url) async {
    try {
      // Clean and validate URL
      String cleanUrl = url.trim();
      if (cleanUrl.isEmpty) {
        _showErrorSnackBar('LinkedIn URL is empty');
        return;
      }

      // Add protocol if missing
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      // Validate URL format
      final uri = Uri.tryParse(cleanUrl);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        _showErrorSnackBar('Invalid LinkedIn URL format');
        return;
      }

      // Launch URL in external application
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching LinkedIn: $e');
      _showErrorSnackBar('Failed to open LinkedIn: ${e.toString()}');
    }
  }

  /**
   * Shows error messages to user with styled SnackBar notifications.
   * Provides consistent error feedback with appropriate styling and duration.
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

  /**
   * Builds the main dashboard widget with all sections and animations.
   * Integrates all startup components into a cohesive dashboard experience.
   * 
   * @return Widget containing the complete startup dashboard interface
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
                _buildWelcomeSection(),
                _buildProfileOverviewCard(),

                // Pitch Deck Files Card integration
                _buildPitchDeckFilesCard(),

                _buildBusinessModelCanvasCard(),

                // Key Metrics section with funding data integration
                const Text(
                  'Key Metrics',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Funding metrics from StartupProfileProvider
                Consumer<StartupProfileProvider>(
                  builder: (context, startupProvider, child) {
                    return Row(
                      children: [
                        _buildMetricCard(
                          title: 'Funding Goal',
                          value:
                              startupProvider.fundingGoalAmount != null
                                  ? '\${(startupProvider.fundingGoalAmount! / 1000).toStringAsFixed(0)}K'
                                  : 'N/A',
                          icon: Icons.monetization_on_outlined,
                          color: const Color(0xFFffa500),
                          subtitle: 'Target Amount',
                        ),
                        const SizedBox(width: 12),
                        _buildMetricCard(
                          title: 'Funding Phase',
                          value:
                              startupProvider
                                          .selectedFundingPhase
                                          ?.isNotEmpty ==
                                      true
                                  ? startupProvider.selectedFundingPhase!
                                  : 'Not Set',
                          icon: Icons.trending_up,
                          color: const Color(0xFF4CAF50),
                          subtitle: 'Current Stage',
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

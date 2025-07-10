import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:venturelink/Startup/Startup_Dashboard/startup_profile_page.dart';
import '../Providers/startup_profile_overview_provider.dart';
import '../Providers/startup_profile_provider.dart';
import '../Providers/business_model_canvas_provider.dart';
import '../Providers/team_members_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class StartupDashboard extends StatefulWidget {
  const StartupDashboard({super.key});

  @override
  State<StartupDashboard> createState() => _StartupDashboardState();
}

class _StartupDashboardState extends State<StartupDashboard>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
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
                    colors: [Color(0xFFffa500), Color(0xFFffa500)],
                  ),
                  borderRadius: BorderRadius.circular(8),
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
            color: const Color(0xFFffa500),
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
          // Background pattern
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
          // Main icon
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
              // Header
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

              // Profile Picture Section
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

                        // Status indicator
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

              // Profile Information Grid with null checks
              Column(
                children: [
                  // First row: Company and Region
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
                  // NEW: Idea Description (full width)
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
                  // Second row: Industry (full width)
                  _buildProfileInfoItem(
                    'Industry',
                    profileProvider.industry?.isNotEmpty == true
                        ? profileProvider.industry!
                        : 'Not Set',
                    Icons.category,
                    const Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 12),
                  // Third row: Tagline (full width)
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
              // Header
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
                // Team members preview (horizontal scroll)
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
                                            // CHANGED: Use default profile icon
                                            Icons.person,
                                            color: Colors.grey[400],
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      // LinkedIn indicator
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
                                // Name
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
                                ), // ADDED: Space between name and role
                                // Position/Role - ADDED
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
                // No team members message
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

  Widget _buildPitchDeckFilesCard() {
    return Consumer<StartupProfileProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 32),
          padding: const EdgeInsets.all(16), // REDUCED from 24 to 16
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
            mainAxisSize: MainAxisSize.min, // ADDED this line
            children: [
              // Header with status
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

                  // File count badge
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

              const SizedBox(height: 16), // REDUCED from 20 to 16
              // Files display or empty state
              if (provider.hasPitchDeckFiles) ...[
                // Files preview with constrained height
                SizedBox(
                  height: 140, // REDUCED from 160 to 140
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(
                      bottom: 4, // REDUCED from 8 to 4
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

                const SizedBox(height: 12), // REDUCED from 20 to 12
                // Submission status
                if (provider.isPitchDeckSubmitted) ...[
                  Container(
                    padding: const EdgeInsets.all(10), // REDUCED from 12 to 10
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
                  // Upload more files option
                  Container(
                    padding: const EdgeInsets.all(10), // REDUCED from 12 to 10
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
                // Empty state
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20), // REDUCED from 24 to 20
                  decoration: BoxDecoration(
                    color: Colors.grey[800]!.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[600]!.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // ADDED this line
                    children: [
                      Icon(
                        Icons.upload_file,
                        size: 40, // REDUCED from 48 to 40
                        color: Colors.grey[500],
                      ),
                      const SizedBox(height: 8), // REDUCED from 12 to 8
                      Text(
                        'No pitch deck files uploaded yet',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6), // REDUCED from 8 to 6
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

  Widget _buildDashboardProfileImage(StartupProfileProvider provider) {
    // Priority: Local file > Network URL > Placeholder
    if (provider.profileImage != null) {
      // Show local file (newly picked)
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
      // Show placeholder
      return _buildDefaultProfileIcon();
    }
  }

  // Helper method for pitch deck status
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

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
              const Icon(Icons.rocket_launch, color: Colors.black, size: 28),
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

  // Business Model Canvas Card Widget
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
              // Header
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
                  // Completion status badge
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

              // Progress section
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

  // Helper method for completed section chips
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

      // Check if URL can be launched
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching LinkedIn: $e');
      _showErrorSnackBar('Failed to open LinkedIn: ${e.toString()}');
    }
  }

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

                // NEW: Pitch Deck Files Card - Added here
                _buildPitchDeckFilesCard(),

                _buildBusinessModelCanvasCard(),

                // Metrics Cards - Using StartupProfileProvider for funding data
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

                // First row of metrics
                Consumer<StartupProfileProvider>(
                  builder: (context, startupProvider, child) {
                    return Row(
                      children: [
                        _buildMetricCard(
                          title: 'Funding Goal',
                          value:
                              startupProvider.fundingGoalAmount != null
                                  ? '\$${(startupProvider.fundingGoalAmount! / 1000).toStringAsFixed(0)}K'
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

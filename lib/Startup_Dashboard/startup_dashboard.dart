import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:venturelink/Startup_Dashboard/startup_profile_page.dart';
import '../Providers/startup_profile_overview_provider.dart';
import '../Providers/startup_profile_provider.dart';
import '../Providers/business_model_canvas_provider.dart';
import '../Providers/team_members_provider.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bmcProvider = context.read<BusinessModelCanvasProvider>();
      // Force initialization of BMC provider if not already initialized
      bmcProvider.initialize();
    });
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
        Container(
          margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFffa500),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Chat feature coming soon!'),
                  backgroundColor: const Color(0xFFffa500),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFffa500).withValues(alpha: 0.3),
            const Color(0xFFff8c00).withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(48),
      ),
      child: const Icon(Icons.business, color: Color(0xFFffa500), size: 40),
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
                            child:
                                startupProvider.profileImage != null
                                    ? Image.file(
                                      startupProvider.profileImage!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return _buildDefaultProfileIcon();
                                      },
                                    )
                                    : _buildDefaultProfileIcon(),
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
              const SizedBox(height: 8),

              if (teamProvider.hasTeamMembers) ...[
                // Team members preview (horizontal scroll)
                SizedBox(
                  height: 100,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          teamProvider.teamMembers.asMap().entries.map((entry) {
                            var member = entry.value;
                            return Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 8),
                              child: _buildTeamMemberPreview(member),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ] else ...[
                // No team members state - simplified
                Text(
                  'No team members',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    height: 1.0,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Helper widget for individual team member preview
  Widget _buildTeamMemberPreview(TeamMember member) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  const Color(0xFF45a049).withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: ClipOval(
              child: Image.network(
                member.avatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    color: Color(0xFF4CAF50),
                    size: 20,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Name
          Text(
            member.name,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Role
          Text(
            member.role,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4CAF50),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // New Pitch Deck Files Card
  Widget _buildPitchDeckFilesCard() {
    return Consumer<StartupProfileProvider>(
      builder: (context, provider, child) {
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
              color: const Color(0xFFA556B3).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA556B3).withValues(alpha: 0.2),
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
                      color: const Color(0xFFA556B3).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      color: Color(0xFFA556B3),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Pitch Deck Files',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA556B3),
                      ),
                    ),
                  ),
                  // Status indicator
                  if (provider.isPitchDeckSubmitted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[400],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              if (provider.pitchDeckFiles.isNotEmpty) ...[
                // Files count and info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA556B3).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFA556B3).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.folder,
                            color: Color(0xFFA556B3),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${provider.pitchDeckFiles.length} files uploaded',
                            style: const TextStyle(
                              color: Color(0xFFA556B3),
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

                // Files preview
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          provider.pitchDeckFiles.asMap().entries.map((entry) {
                            var file = entry.value;
                            String fileName = file.path.split('/').last;
                            String extension =
                                file.path.split('.').last.toLowerCase();

                            return Container(
                              width: 80,
                              height: 100,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFFA556B3,
                                  ).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    extension == 'pdf'
                                        ? Icons.picture_as_pdf
                                        : Icons.videocam,
                                    color:
                                        extension == 'pdf'
                                            ? Colors.red
                                            : const Color(0xFFffa500),
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      fileName.length > 10
                                          ? '${fileName.substring(0, 7)}...'
                                          : fileName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),

                // Submission info if submitted
                if (provider.isPitchDeckSubmitted &&
                    provider.pitchDeckSubmissionDate != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.green[400],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Submitted on ${provider.pitchDeckSubmissionDate!.day}/${provider.pitchDeckSubmissionDate!.month}/${provider.pitchDeckSubmissionDate!.year}',
                          style: TextStyle(
                            color: Colors.green[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                // No files uploaded state
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
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
                        Icons.upload_file,
                        size: 48,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No pitch deck files uploaded yet',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
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

  Widget _buildQuickActionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.grey[850]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[600],
                  size: 16,
                ),
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
                              : '${(provider.completionPercentage * 100).toInt()}%',
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

              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Progress',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: provider.completionPercentage,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          provider.completionPercentage == 1.0
                              ? Colors.green
                              : const Color(0xFF4CAF50),
                        ),
                      ),
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
            padding: const EdgeInsets.all(24.0),
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

                // Second row of metrics
                Row(
                  children: [
                    _buildMetricCard(
                      title: 'Investors',
                      value: '0',
                      icon: Icons.group_outlined,
                      color: const Color(0xFF2196F3),
                      subtitle: 'Connected',
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Quick Actions Section
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),

                _buildQuickActionCard(
                  title: 'Find Investors',
                  description: 'Browse and connect with potential investors',
                  icon: Icons.search,
                  accentColor: const Color(0xFF2196F3),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Investor search coming soon!'),
                        backgroundColor: const Color(0xFF2196F3),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

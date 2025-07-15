// lib/Startup/Startup_Dashboard/team_members_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/team_members_provider.dart';

/**
 * Implements a comprehensive team management interface for startup team building and coordination.
 * Provides complete functionality for adding, managing, and organizing team members with role-based categorization.
 * 
 * Features:
 * - Complete team member management with real-time CRUD operations
 * - Interactive form validation with LinkedIn profile integration
 * - Dynamic team statistics and leadership tracking
 * - Grid-based team member visualization with avatars and role indicators
 * - Professional team member cards with leadership badges and social links
 * - Comprehensive error handling with user-friendly feedback notifications
 * - Auto-save functionality with unsaved changes tracking
 * - Responsive design with animated transitions and orange theme (#FFa500)
 * - Bulk operations for clearing and refreshing team data
 * - Advanced confirmation dialogs for destructive operations
 * - Team composition analytics with member count and leadership metrics
 * - Professional styling with gradient backgrounds and shadow effects
 * - Integration with TeamMembersProvider for centralized state management
 */

/**
 * TeamMembersPage - Main team management widget for comprehensive startup team coordination.
 * Integrates all team management functionality into a unified interface with real-time updates.
 */
class TeamMembersPage extends StatefulWidget {
  const TeamMembersPage({super.key});

  @override
  State<TeamMembersPage> createState() => _TeamMembersPageState();
}

/**
 * _TeamMembersPageState - State management for the comprehensive team members interface.
 * Manages form validation, animations, team operations, and provider integration for team coordination.
 */
class _TeamMembersPageState extends State<TeamMembersPage>
    with TickerProviderStateMixin {
  /**
   * Global form key for coordinating validation across all team member input fields.
   */
  final _formKey = GlobalKey<FormState>();

  /**
   * Animation controllers for smooth page transitions and visual feedback.
   */
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  /**
   * Initializes the team members page state with animation controllers and configurations.
   * Sets up fade and slide animations for enhanced user experience.
   */
  @override
  void initState() {
    super.initState();
    // Initialize fade animation controller for opacity transitions
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    // Initialize slide animation controller for position transitions
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Configure fade animation from transparent to opaque
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Configure slide animation from bottom to center with elastic effect
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    // Start animations immediately on page load
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
   * Builds the main team members page interface with provider integration.
   * Uses Consumer pattern to listen to TeamMembersProvider changes and update UI accordingly.
   * 
   * @return Widget containing the complete team management interface
   */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: _buildAppBar(),
      body: Consumer<TeamMembersProvider>(
        builder: (context, provider, child) {
          // Show loading state while provider is initializing
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFffa500)),
                  SizedBox(height: 16),
                  Text(
                    'Loading team members...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          // Show error state with retry and navigation options
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading team members',
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
                          provider.initialize();
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

          // Main content with animated transitions
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
                    _buildAddMemberSection(provider),
                    const SizedBox(height: 32),
                    _buildTeamMembersSection(provider),
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

  /**
   * Builds the application bar with navigation and saving indicator.
   * Shows a loading spinner when save operations are in progress.
   * 
   * @return PreferredSizeWidget containing the app bar with orange theme
   */
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.grey[900],
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFFffa500)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Team Members',
        style: TextStyle(
          color: Color(0xFFffa500),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Consumer<TeamMembersProvider>(
          builder: (context, provider, child) {
            // Show saving indicator when save operation is active
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

  /**
   * Builds the header section with gradient background and team branding.
   * Displays dynamic messaging based on team composition and member count.
   * 
   * @param provider The TeamMembersProvider instance for state access
   * @return Widget containing the styled header with team information
   */
  Widget _buildHeader(TeamMembersProvider provider) {
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
              const Icon(Icons.groups, color: Colors.black, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Team Members',
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
          Text(
            provider.hasTeamMembers
                ? 'Manage your ${provider.teamMembersCount} team members and build your dream team.'
                : 'Build your dream team by adding talented individuals who share your vision.',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /**
   * Builds the progress tracking section with team statistics and composition analytics.
   * Displays total member count, leadership count, and unsaved changes indicators.
   * 
   * @param provider The TeamMembersProvider instance for progress calculation
   * @return Widget containing team statistics and progress visualization
   */
  Widget _buildProgressSection(TeamMembersProvider provider) {
    final teamCount = provider.teamMembersCount;
    final leadershipCount = provider.leadershipTeam.length;

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
                'Team Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[200],
                ),
              ),
              Text(
                '$teamCount Members',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFffa500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Team statistics cards
          Row(
            children: [
              Expanded(
                child: _buildTeamStatCard(
                  'Total Members',
                  teamCount.toString(),
                  Icons.people_outline,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTeamStatCard(
                  'Leadership',
                  leadershipCount.toString(),
                  Icons.star_outline,
                  Colors.amber,
                ),
              ),
            ],
          ),
          // Unsaved changes indicator
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

  /**
   * Builds individual team statistic cards with icons and color coding.
   * Displays specific metrics like member count and leadership roles.
   * 
   * @param title The statistic title to display
   * @param value The numeric value for the statistic
   * @param icon The icon representing the statistic
   * @param color The theme color for the statistic card
   * @return Widget containing the styled team statistic card
   */
  Widget _buildTeamStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /**
   * Builds the add member section with comprehensive form fields and validation.
   * Includes name, role, and LinkedIn profile inputs with real-time validation feedback.
   * 
   * @param provider The TeamMembersProvider instance for form management
   * @return Widget containing the complete add member form interface
   */
  Widget _buildAddMemberSection(TeamMembersProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFffa500).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_add,
                  color: Color(0xFFffa500),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Add Team Member',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[200],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Name and role input fields in responsive row layout
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: provider.nameController,
                        label: 'Full Name *',
                        hint: 'Enter full name',
                        icon: Icons.person_outline,
                        validator: provider.validateName,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        controller: provider.roleController,
                        label: 'Role/Position *',
                        hint: 'e.g., CEO, CTO, Designer',
                        icon: Icons.work_outline,
                        validator: provider.validateRole,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // LinkedIn profile input field (optional)
                _buildInputField(
                  controller: provider.linkedinController,
                  label: 'LinkedIn Profile (Optional)',
                  hint: 'https://linkedin.com/in/username',
                  icon: Icons.link,
                  validator: provider.validateLinkedin,
                ),
                const SizedBox(height: 24),
                // Add member button with dynamic state
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        provider.isFormValid
                            ? () => _addTeamMember(provider)
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          provider.isFormValid
                              ? const Color(0xFFffa500)
                              : Colors.grey[700],
                      foregroundColor:
                          provider.isFormValid
                              ? Colors.black
                              : Colors.grey[500],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          provider.isFormValid
                              ? Icons.add
                              : Icons.person_add_disabled,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          provider.isFormValid
                              ? 'Add Team Member'
                              : 'Fill Required Fields',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  /**
   * Builds reusable input fields with consistent styling and validation support.
   * Provides professional input styling with orange theme integration.
   * 
   * @param controller The TextEditingController for the input field
   * @param label The label text for the field
   * @param hint The placeholder text for user guidance
   * @param icon The leading icon for visual identification
   * @param validator The validation function for input validation
   * @return Widget containing the styled input field
   */
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFFffa500),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          cursorColor: const Color(0xFFffa500),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800]!.withValues(alpha: 0.5),
            prefixIcon: Icon(icon, color: const Color(0xFFffa500), size: 20),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFffa500), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: validator,
          onChanged:
              (_) => setState(() {}), // Trigger rebuild for validation updates
        ),
      ],
    );
  }

  /**
   * Builds the team members display section with grid layout and empty state handling.
   * Shows either a grid of team member cards or an empty state message.
   * 
   * @param provider The TeamMembersProvider instance for team data access
   * @return Widget containing the team members visualization section
   */
  Widget _buildTeamMembersSection(TeamMembersProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Members',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[200],
          ),
        ),
        const SizedBox(height: 16),
        if (!provider.hasTeamMembers)
          _buildEmptyState()
        else
          _buildTeamMembersGrid(provider),
      ],
    );
  }

  /**
   * Builds the empty state display when no team members are present.
   * Provides user guidance for adding their first team member.
   * 
   * @return Widget containing the styled empty state message
   */
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Icon(Icons.group_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'No team members yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first team member using the form above',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /**
   * Builds the responsive grid layout for displaying team member cards.
   * Uses GridView with fixed cross-axis count for optimal card display.
   * 
   * @param provider The TeamMembersProvider instance for team data
   * @return Widget containing the team members grid layout
   */
  Widget _buildTeamMembersGrid(TeamMembersProvider provider) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: provider.teamMembers.length,
      itemBuilder: (context, index) {
        final member = provider.teamMembers[index];
        return _buildTeamMemberCard(member, provider);
      },
    );
  }

  /**
   * Builds individual team member cards with avatars, roles, and action buttons.
   * Includes leadership badges, LinkedIn indicators, and removal functionality.
   * 
   * @param member The TeamMember instance to display
   * @param provider The TeamMembersProvider instance for operations
   * @return Widget containing the styled team member card
   */
  Widget _buildTeamMemberCard(TeamMember member, TeamMembersProvider provider) {
    final isLeadership = provider.leadershipTeam.any(
      (leader) => leader.id == member.id,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLeadership ? const Color(0xFFffa500) : Colors.grey[800]!,
          width: isLeadership ? 2 : 1,
        ),
        boxShadow:
            isLeadership
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
              // Member avatar with initial or profile image
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFffa500).withValues(alpha: 0.2),
                backgroundImage:
                    member.avatar.isNotEmpty
                        ? NetworkImage(member.avatar)
                        : null,
                child:
                    member.avatar.isEmpty
                        ? Text(
                          member.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFffa500),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                        : null,
              ),
              // Action buttons row (leadership badge and remove button)
              Row(
                children: [
                  if (isLeadership)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFffa500).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Color(0xFFffa500),
                        size: 12,
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showRemoveDialog(member, provider),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Member name with leadership styling
          Text(
            member.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isLeadership ? const Color(0xFFffa500) : Colors.grey[200],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Member role/position
          Text(
            member.role,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          // LinkedIn indicator badge
          if (member.linkedin.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, color: Colors.blue, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'LinkedIn',
                    style: TextStyle(
                      color: Colors.blue[300],
                      fontSize: 10,
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
   * Builds the action buttons section for save, clear, and refresh operations.
   * Dynamically shows appropriate buttons based on team data availability.
   * 
   * @param provider The TeamMembersProvider instance for action handling
   * @return Widget containing the action buttons with loading states
   */
  Widget _buildActionButtons(TeamMembersProvider provider) {
    return Column(
      children: [
        // Save team button - shown when team members exist
        if (provider.hasTeamMembers)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  provider.isSaving
                      ? null
                      : () async {
                        final success = await provider.saveTeamMembers();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Team data saved successfully!'
                                    : 'Failed to save team: ${provider.error}',
                              ),
                              backgroundColor:
                                  success ? Colors.green : Colors.red,
                            ),
                          );
                          Navigator.of(context).pop();
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
                      : Text(
                        'Save Team (${provider.teamMembersCount} members)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Clear All button - only shown when team members exist
            if (provider.hasTeamMembers) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final confirm = await _showClearAllDialog();
                    if (confirm == true) {
                      await provider.clearAllTeamMembers();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All team members cleared'),
                            backgroundColor: Colors.green,
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
            ],
            // Refresh button - always available for data synchronization
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await provider.initialize();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Team data refreshed'),
                        backgroundColor: Colors.blueAccent,
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

  /**
   * Handles adding a new team member with comprehensive validation and user feedback.
   * Validates both form fields and provider state before adding the team member.
   * Provides success notifications and error handling with form clearing on success.
   * 
   * @param provider The TeamMembersProvider instance for team operations
   */
  void _addTeamMember(TeamMembersProvider provider) async {
    if (_formKey.currentState!.validate() && provider.isFormValid) {
      final success = await provider.addTeamMember();
      if (mounted) {
        if (success) {
          provider.clearForm();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team member added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add team member: ${provider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /**
   * Shows confirmation dialog for removing individual team members.
   * Provides clear confirmation with member name and handles removal operation.
   * 
   * @param member The TeamMember instance to be removed
   * @param provider The TeamMembersProvider instance for removal operations
   */
  void _showRemoveDialog(TeamMember member, TeamMembersProvider provider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Remove Team Member',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to remove ${member.name} from the team?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final success = await provider.removeTeamMember(member.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? '${member.name} removed from team'
                              : 'Failed to remove team member',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  /**
   * Shows confirmation dialog for clearing all team members.
   * Provides clear warning about data loss and action consequences.
   * 
   * @return Future bool? user's confirmation choice (true = confirm, false = cancel)
   */
  Future<bool?> _showClearAllDialog() {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Clear All Team Members',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to remove all team members? This action cannot be undone.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Clear All'),
              ),
            ],
          ),
    );
  }
}

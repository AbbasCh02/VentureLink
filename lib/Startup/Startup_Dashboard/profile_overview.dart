import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/startup_profile_overview_provider.dart';

/**
 * Implements a comprehensive company profile overview management widget for startup profile completion.
 * Provides interactive components for capturing essential company information and tracking completion progress.
 * 
 * Features:
 * - Real-time profile completion tracking with visual progress indicators
 * - Comprehensive company information form with validation
 * - Seamless integration with StartupProfileOverviewProvider for state management
 * - Auto-save functionality with unsaved changes detection
 * - Form validation for all required company fields
 * - Responsive UI with loading states and error handling
 * - Professional styling with consistent orange theme (#FFa500)
 * - Animated transitions and smooth user experience
 * - Profile completion percentage calculation
 * - Clear/refresh functionality for data management
 * - Success and error feedback with SnackBar notifications
 */

/**
 * ProfileOverview - Main widget component for startup company profile management.
 * Handles company name, industry, tagline, and region information with completion tracking.
 */
class ProfileOverview extends StatefulWidget {
  const ProfileOverview({super.key});

  @override
  State<ProfileOverview> createState() => _ProfileOverviewState();
}

/**
 * _ProfileOverviewState - State management for the ProfileOverview widget component.
 * Manages form interactions, animations, validation, and provider integration for company profile data.
 */
class _ProfileOverviewState extends State<ProfileOverview>
    with TickerProviderStateMixin {
  /**
   * Form key for validation management across all profile input fields.
   */
  final _formKey = GlobalKey<FormState>();

  /**
   * Animation controllers for smooth UI transitions and visual feedback.
   */
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  /**
   * Initializes the widget state and sets up animation controllers.
   * Configures fade and slide animations for enhanced user experience.
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

    // Start animations immediately on widget load
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
   * Builds the main ProfileOverview widget interface.
   * Uses Consumer pattern to listen to StartupProfileOverviewProvider changes and update UI accordingly.
   * 
   * @return Widget containing the complete company profile overview interface
   */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a), // Dark background
      appBar: _buildAppBar(),
      body: Consumer<StartupProfileOverviewProvider>(
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
                    'Loading profile overview...',
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
                    'Error loading profile',
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
                    _buildProfileFormSection(provider),
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
        'Profile Overview',
        style: TextStyle(
          color: Color(0xFFffa500),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Consumer<StartupProfileOverviewProvider>(
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
   * Builds the header section with gradient background and company branding.
   * Displays dynamic messaging based on profile completion status.
   * 
   * @param provider The StartupProfileOverviewProvider instance for state access
   * @return Widget containing the styled header with icon and description
   */
  Widget _buildHeader(StartupProfileOverviewProvider provider) {
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
                  'Company Profile Overview',
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
            provider.isProfileComplete
                ? 'Update your company profile and startup identity.'
                : 'Complete your company profile to strengthen your startup\'s identity and credibility.',
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
   * Builds the progress tracking section with completion percentage and field count.
   * Displays visual progress bar and unsaved changes indicator.
   * 
   * @param provider The StartupProfileOverviewProvider instance for progress calculation
   * @return Widget containing progress visualization and completion status
   */
  Widget _buildProgressSection(StartupProfileOverviewProvider provider) {
    final completionPercentage = _calculateCompletionPercentage(provider);
    final completedFields = _getCompletedFieldsCount(provider);

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
                'Profile Completion',
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
          // Progress bar visualization
          LinearProgressIndicator(
            value: completionPercentage,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFffa500)),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Text(
            '$completedFields of 4 fields completed',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
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
   * Builds the main profile form section with all company information input fields.
   * Includes company name, industry, tagline, and region with validation and unsaved changes tracking.
   * 
   * @param provider The StartupProfileOverviewProvider instance for form management
   * @return Widget containing the complete form with styled input fields
   */
  Widget _buildProfileFormSection(StartupProfileOverviewProvider provider) {
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
                  Icons.edit,
                  color: Color(0xFFffa500),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Company Information',
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
                // Company Name field - required field with validation
                _buildInputField(
                  controller: provider.companyNameController,
                  label: 'Company Name *',
                  hint: 'Enter your company name',
                  icon: Icons.business,
                  validator: provider.validateCompanyName,
                  hasUnsavedChanges: provider.hasUnsavedChanges('companyName'),
                ),
                const SizedBox(height: 16),
                // Industry field - required field with business category validation
                _buildInputField(
                  controller: provider.industryController,
                  label: 'Industry *',
                  hint: 'e.g., Technology, Healthcare, Finance',
                  icon: Icons.category,
                  validator: provider.validateIndustry,
                  hasUnsavedChanges: provider.hasUnsavedChanges('industry'),
                ),
                const SizedBox(height: 16),
                // Tagline field - required marketing message with character limits
                _buildInputField(
                  controller: provider.taglineController,
                  label: 'Company Tagline *',
                  hint: 'A compelling one-liner about your startup',
                  icon: Icons.format_quote,
                  validator: provider.validateTagline,
                  hasUnsavedChanges: provider.hasUnsavedChanges('tagline'),
                ),
                const SizedBox(height: 16),
                // Region field - required market/geographic focus validation
                _buildInputField(
                  controller: provider.regionController,
                  label: 'Region/Market *',
                  hint: 'e.g., North America, Europe, Asia',
                  icon: Icons.location_on,
                  validator: provider.validateRegion,
                  hasUnsavedChanges: provider.hasUnsavedChanges('region'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /**
   * Builds a reusable input field with consistent styling and validation.
   * Provides visual feedback for unsaved changes and form validation states.
   * 
   * @param controller The TextEditingController for the input field
   * @param label The display label for the field
   * @param hint The placeholder text for user guidance
   * @param icon The leading icon for visual identification
   * @param validator The validation function for input validation
   * @param hasUnsavedChanges Boolean indicating if field has unsaved modifications
   * @return Widget containing the styled text input field
   */
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    bool hasUnsavedChanges = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFffa500),
              ),
            ),
            // Unsaved changes badge
            if (hasUnsavedChanges) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Unsaved',
                  style: TextStyle(
                    color: Colors.orange[400],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          cursorColor: const Color(0xFFffa500),
          controller: controller,
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
              borderSide: BorderSide(
                color: hasUnsavedChanges ? Colors.orange : Colors.grey[700]!,
                width: hasUnsavedChanges ? 2 : 1,
              ),
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
   * Builds the action buttons section for save, clear, and refresh operations.
   * Dynamically shows appropriate buttons based on profile completion and unsaved changes status.
   * 
   * @param provider The StartupProfileOverviewProvider instance for action handling
   * @return Widget containing the action buttons with loading states
   */
  Widget _buildActionButtons(StartupProfileOverviewProvider provider) {
    return Column(
      children: [
        // Save/Complete button - shown when changes exist or profile incomplete
        if (provider.hasAnyUnsavedChanges || !provider.isProfileComplete)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  provider.isSaving ? null : () => _saveProfile(provider),
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
                        provider.hasAnyUnsavedChanges
                            ? 'Save Changes'
                            : 'Complete Profile',
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
            // Clear All button - only shown when profile is complete
            if (provider.isProfileComplete) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final confirm = await _showClearDialog();
                    if (confirm == true) {
                      await provider.clearProfileData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile data cleared'),
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
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            // Refresh button - always available for data synchronization
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await provider.refreshFromDatabase();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile data refreshed'),
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
   * Calculates the completion percentage based on filled required fields.
   * Evaluates company name, tagline, industry, and region fields.
   * 
   * @param provider The StartupProfileOverviewProvider instance for data access
   * @return Double value representing completion percentage (0.0 to 1.0)
   */
  double _calculateCompletionPercentage(
    StartupProfileOverviewProvider provider,
  ) {
    int completedFields = 0;
    const int totalFields = 4;

    if (provider.companyName?.isNotEmpty == true) completedFields++;
    if (provider.tagline?.isNotEmpty == true) completedFields++;
    if (provider.industry?.isNotEmpty == true) completedFields++;
    if (provider.region?.isNotEmpty == true) completedFields++;

    return completedFields / totalFields;
  }

  /**
   * Gets the count of completed required fields for progress display.
   * 
   * @param provider The StartupProfileOverviewProvider instance for data access
   * @return Integer count of completed fields
   */
  int _getCompletedFieldsCount(StartupProfileOverviewProvider provider) {
    int count = 0;
    if (provider.companyName?.isNotEmpty == true) count++;
    if (provider.tagline?.isNotEmpty == true) count++;
    if (provider.industry?.isNotEmpty == true) count++;
    if (provider.region?.isNotEmpty == true) count++;
    return count;
  }

  /**
   * Handles the profile save operation with validation and user feedback.
   * Validates form, saves data through provider, and provides success/error notifications.
   * 
   * @param provider The StartupProfileOverviewProvider instance for save operations
   */
  void _saveProfile(StartupProfileOverviewProvider provider) async {
    if (_formKey.currentState!.validate()) {
      final success = await provider.saveAllFields();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Return profile data to previous screen on successful save
          final profileData = provider.getProfileData();
          Navigator.pop(context, profileData);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save profile: ${provider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /**
   * Shows a confirmation dialog for clearing all profile data.
   * Provides clear warning about data loss and action consequences.
   * 
   * @return Future<bool?> user's confirmation choice (true = confirm, false = cancel)
   */
  Future<bool?> _showClearDialog() {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Clear Profile Data',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to clear all profile information? This action cannot be undone.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}

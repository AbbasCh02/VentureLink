import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/business_model_canvas_provider.dart';

/**
 * Implements the Key Activities section of the Business Model Canvas interface.
 * Provides a dedicated editing experience for defining critical business operations and actions.
 * 
 * Features:
 * - Full-screen text editing with multi-line support for activity planning
 * - Real-time synchronization with BusinessModelCanvasProvider
 * - Comprehensive hint system showcasing different activity types and categories
 * - Visual indicators for unsaved changes and save operations
 * - Error handling with dismissible error banners
 * - Focus management for optimal text editing experience
 * - Responsive UI with loading states and user feedback
 * - Context-sensitive guidance for operational planning
 * - Auto-save prevention during provider state updates
 * - Strategic activity planning and operational data persistence
 */

/**
 * KeyActivitiesPage - Dedicated interface for editing BMC Key Activities section.
 * Handles the "What must you do to deliver your value proposition?" operational question.
 */
class KeyActivitiesPage extends StatefulWidget {
  const KeyActivitiesPage({super.key});

  @override
  State<KeyActivitiesPage> createState() => _KeyActivitiesPageState();
}

/**
 * _KeyActivitiesPageState - State management for the Key Activities editing interface.
 * Manages text input, focus states, provider synchronization, and operational activity data persistence.
 */
class _KeyActivitiesPageState extends State<KeyActivitiesPage> {
  // Text input controller for the key activities content
  final TextEditingController _controller = TextEditingController();

  // Field identifier for provider communication
  final String _fieldName = 'keyActivities';

  // Focus management for the text field
  final FocusNode _focusNode = FocusNode();

  // Focus state tracking for UI updates
  bool _isFocused = false;

  /**
   * Initializes the widget state and sets up necessary listeners.
   * Loads existing key activities data and establishes text/focus change handlers.
   */
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BusinessModelCanvasProvider>();
      _controller.text = provider.keyActivities;
      _controller.addListener(_onTextChanged);

      // Listen to focus changes
      _focusNode.addListener(() {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      });
    });
  }

  /**
   * Handles text changes from user input.
   * Updates the provider with new key activities data and triggers UI updates.
   */
  void _onTextChanged() {
    final provider = context.read<BusinessModelCanvasProvider>();
    // Update the provider value without saving to persistence yet
    provider.updateKeyActivities(_controller.text);
    // Trigger rebuild to update hint text display
    setState(() {});
  }

  /**
   * Cleans up resources when the widget is disposed.
   * Removes listeners and disposes controllers to prevent memory leaks.
   */
  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /**
   * Saves the current key activities data to the database.
   * Provides user feedback through snackbars for success/failure states.
   */
  Future<void> _saveData() async {
    final provider = context.read<BusinessModelCanvasProvider>();
    final success = await provider.saveField(_fieldName);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Key Activities saved successfully!'),
          backgroundColor: Color(0xFFffa500),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${provider.error ?? 'Unknown error'}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /**
   * Builds the main Key Activities page interface.
   * Uses Consumer pattern to listen to provider changes and update UI accordingly.
   */
  @override
  Widget build(BuildContext context) {
    return Consumer<BusinessModelCanvasProvider>(
      builder: (context, provider, child) {
        final hasUnsavedChanges = provider.hasUnsavedChanges(_fieldName);
        final showHints = _controller.text.isEmpty && !_isFocused;

        return Scaffold(
          backgroundColor: const Color(0xFF0d0d0d),
          appBar: _buildAppBar(),
          body: Column(
            children: [
              _buildErrorBanner(provider),
              _buildHeader(),
              _buildTextInputArea(provider, hasUnsavedChanges, showHints),
              _buildActionBar(provider, hasUnsavedChanges),
            ],
          ),
        );
      },
    );
  }

  /**
   * Builds the application bar with title and branding.
   * 
   * @return PreferredSizeWidget for the app bar
   */
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Key Activities',
              style: TextStyle(
                color: Color(0xFFffa500),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1a1a1a),
      elevation: 2,
    );
  }

  /**
   * Builds the error banner that appears when there are provider errors.
   * Shows dismissible error messages with clear visual indicators.
   * 
   * @param provider The BusinessModelCanvasProvider instance
   * @return Widget containing the error banner or empty container
   */
  Widget _buildErrorBanner(BusinessModelCanvasProvider provider) {
    if (provider.error == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            onPressed: () {
              provider.clearError();
            },
            icon: const Icon(Icons.close, color: Colors.red),
          ),
        ],
      ),
    );
  }

  /**
   * Builds the header section with title and description.
   * Provides context and guidance for the Key Activities section.
   * 
   * @return Widget containing the header with title and description
   */
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2a2a2a),
        border: Border(bottom: BorderSide(color: Color(0xFFffa500), width: 2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Activities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFffa500),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Define and describe the most important actions your company must take to operate successfully. What must you do to deliver your value proposition, reach your customers, maintain customer relationships, and generate revenue?',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /**
   * Builds the main text input area for key activities content.
   * Features adaptive hints, focus management, and visual state indicators.
   * 
   * @param provider The BusinessModelCanvasProvider instance
   * @param hasUnsavedChanges Whether there are unsaved changes
   * @param showHints Whether to display activity category examples
   * @return Widget containing the text input area
   */
  Widget _buildTextInputArea(
    BusinessModelCanvasProvider provider,
    bool hasUnsavedChanges,
    bool showHints,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                hasUnsavedChanges
                    ? Colors.orange.withValues(alpha: 0.5)
                    : const Color(0xFFffa500).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: TextField(
          cursorColor: const Color(0xFFffa500),
          controller: _controller,
          focusNode: _focusNode,
          enabled: !provider.isSaving,
          decoration: InputDecoration(
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            contentPadding: const EdgeInsets.all(20),
            // Show label when focused or has content
            labelText:
                (_isFocused || _controller.text.isNotEmpty)
                    ? 'Enter Key Activities Information'
                    : null,
            labelStyle: TextStyle(
              color: provider.isSaving ? Colors.grey[600] : Colors.grey,
            ),
            floatingLabelStyle: const TextStyle(color: Color(0xFFffa500)),
            // Show hints when empty and not focused
            hintText:
                showHints
                    ? 'Examples:\n• Production (manufacturing, development)\n• Problem solving (consultancy, R&D)\n• Platform/Network (software platforms, networks)\n• Supply chain management\n• Marketing and sales\n• Customer service and support\n• Quality assurance\n• Distribution and logistics\n• Data analysis and research\n• Partnership management\n• Financial management\n• Human resource management'
                    : null,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          maxLines: null,
          minLines: 12,
          style: TextStyle(
            color: provider.isSaving ? Colors.grey[600] : Colors.white,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  /**
   * Builds the bottom action bar with save functionality.
   * Displays save button with appropriate states and loading indicators.
   * 
   * @param provider The BusinessModelCanvasProvider instance
   * @param hasUnsavedChanges Whether there are unsaved changes
   * @return Widget containing the action bar
   */
  Widget _buildActionBar(
    BusinessModelCanvasProvider provider,
    bool hasUnsavedChanges,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.black),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: hasUnsavedChanges && !provider.isSaving ? _saveData : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                hasUnsavedChanges && !provider.isSaving
                    ? const Color(0xFFffa500)
                    : Colors.grey[600],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child:
              provider.isSaving
                  ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Saving...'),
                    ],
                  )
                  : Text(
                    hasUnsavedChanges ? 'Save Changes' : 'No Changes to Save',
                    style: TextStyle(
                      color:
                          hasUnsavedChanges && !provider.isSaving
                              ? Colors.black
                              : Colors.grey[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
        ),
      ),
    );
  }
}

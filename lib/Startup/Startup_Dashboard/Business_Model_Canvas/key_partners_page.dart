import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/business_model_canvas_provider.dart';

/**
 * Implements the Key Partners section of the Business Model Canvas interface.
 * Provides a dedicated editing experience for defining strategic partnerships and alliances.
 * 
 * Features:
 * - Full-screen text editing with multi-line support for partnership planning
 * - Real-time synchronization with BusinessModelCanvasProvider
 * - Comprehensive hint system showcasing different partnership types and strategies
 * - Visual indicators for unsaved changes and save operations
 * - Error handling with dismissible error banners
 * - Focus management for optimal text editing experience
 * - Responsive UI with loading states and user feedback
 * - Context-sensitive guidance for strategic partnership development
 * - Auto-save prevention during provider state updates
 * - Partnership ecosystem planning and strategic alliance data persistence
 */

/**
 * KeyPartnersPage - Dedicated interface for editing BMC Key Partners section.
 * Handles the "Who are your key allies?" strategic partnership question.
 */
class KeyPartnersPage extends StatefulWidget {
  const KeyPartnersPage({super.key});

  @override
  State<KeyPartnersPage> createState() => _KeyPartnersPageState();
}

/**
 * _KeyPartnersPageState - State management for the Key Partners editing interface.
 * Manages text input, focus states, provider synchronization, and partnership data persistence.
 */
class _KeyPartnersPageState extends State<KeyPartnersPage> {
  // Text input controller for the key partners content
  final TextEditingController _controller = TextEditingController();

  // Field identifier for provider communication
  final String _fieldName = 'keyPartners';

  // Focus management for the text field
  final FocusNode _focusNode = FocusNode();

  // Focus state tracking for UI updates
  bool _isFocused = false;

  /**
   * Initializes the widget state and sets up necessary listeners.
   * Loads existing key partners data and establishes text/focus change handlers.
   */
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BusinessModelCanvasProvider>();
      _controller.text = provider.keyPartners;
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
   * Updates the provider with new key partners data and triggers UI updates.
   */
  void _onTextChanged() {
    final provider = context.read<BusinessModelCanvasProvider>();
    // Update the provider value without saving to persistence yet
    provider.updateKeyPartners(_controller.text);
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
   * Saves the current key partners data to the database.
   * Provides user feedback through snackbars for success/failure states.
   */
  Future<void> _saveData() async {
    final provider = context.read<BusinessModelCanvasProvider>();
    final success = await provider.saveField(_fieldName);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Key Partners saved successfully!'),
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
   * Builds the main Key Partners page interface.
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
              'Key Partners',
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
   * Provides context and guidance for the Key Partners section.
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
            'Key Partners',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFffa500),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Define and describe the external organizations, individuals, or entities that help your business succeed. Who are your key allies? Which partners are essential to delivering your value proposition, optimizing operations, reducing risk, or acquiring resources?',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /**
   * Builds the main text input area for key partners content.
   * Features adaptive hints, focus management, and visual state indicators.
   * 
   * @param provider The BusinessModelCanvasProvider instance
   * @param hasUnsavedChanges Whether there are unsaved changes
   * @param showHints Whether to display partnership strategy examples
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
                    ? 'Enter Key Partners Information'
                    : null,
            labelStyle: TextStyle(
              color: provider.isSaving ? Colors.grey[600] : Colors.grey,
            ),
            floatingLabelStyle: const TextStyle(color: Color(0xFFffa500)),
            // Show hints when empty and not focused
            hintText:
                showHints
                    ? 'Examples:\n• Strategic alliances (non-competitors)\n• Joint ventures\n• Buyer-supplier relationships\n• Technology partners\n• Distribution partners\n• Marketing partners\n• Financial partners (investors, banks)\n• Outsourcing partners\n• Regulatory and compliance partners\n• Research and development partners\n• Logistics and fulfillment partners\n• Integration partners (APIs, platforms)'
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

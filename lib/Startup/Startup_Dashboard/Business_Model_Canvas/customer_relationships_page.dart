import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/business_model_canvas_provider.dart';

class CustomerRelationshipsPage extends StatefulWidget {
  const CustomerRelationshipsPage({super.key});

  @override
  State<CustomerRelationshipsPage> createState() =>
      _CustomerRelationshipsPageState();
}

class _CustomerRelationshipsPageState extends State<CustomerRelationshipsPage> {
  final TextEditingController _controller = TextEditingController();
  final String _fieldName = 'customerRelationships';
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BusinessModelCanvasProvider>();
      _controller.text = provider.customerRelationships;
      _controller.addListener(_onTextChanged);

      // Listen to focus changes
      _focusNode.addListener(() {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      });
    });
  }

  void _onTextChanged() {
    final provider = context.read<BusinessModelCanvasProvider>();
    // Update the provider value without saving to persistence yet
    provider.updateCustomerRelationships(_controller.text);
    // Trigger rebuild to update hint text display
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    final provider = context.read<BusinessModelCanvasProvider>();
    final success = await provider.saveField(_fieldName);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer Relationships saved successfully!'),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<BusinessModelCanvasProvider>(
      builder: (context, provider, child) {
        final hasUnsavedChanges = provider.hasUnsavedChanges(_fieldName);
        final showHints = _controller.text.isEmpty && !_isFocused;

        return Scaffold(
          backgroundColor: const Color(0xFF0d0d0d),
          appBar: AppBar(
            title: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Customer Relationships',
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
          ),
          body: Column(
            children: [
              // Error banner
              if (provider.error != null)
                Container(
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
                ),

              // Header with description
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF2a2a2a),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFffa500), width: 2),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Relationships',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFffa500),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'What types of relationships do you establish and maintain with each customer segment? Focus on customer acquisition, retention, and sales boosting.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Text input area
              Expanded(
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
                              ? 'Enter Customer Relationships Information'
                              : null,
                      labelStyle: TextStyle(
                        color:
                            provider.isSaving ? Colors.grey[600] : Colors.grey,
                      ),
                      floatingLabelStyle: const TextStyle(
                        color: Color(0xFFffa500),
                      ),
                      // Show hints when empty and not focused
                      hintText:
                          showHints
                              ? 'Examples:\n• Personal assistance (dedicated support)\n• Self-service (online portals, FAQs)\n• Automated services (chatbots, AI support)\n• Communities (user forums, social groups)\n• Co-creation (involving customers in development)\n• Subscription-based relationships\n• Loyalty programs\n• Customer success management'
                              : null,
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    maxLines: null,
                    minLines: 12,
                    style: TextStyle(
                      color:
                          provider.isSaving ? Colors.grey[600] : Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              // Bottom action bar - Only save button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.black),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        hasUnsavedChanges && !provider.isSaving
                            ? _saveData
                            : null,
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
                              hasUnsavedChanges
                                  ? 'Save Changes'
                                  : 'No Changes to Save',
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
              ),
            ],
          ),
        );
      },
    );
  }
}

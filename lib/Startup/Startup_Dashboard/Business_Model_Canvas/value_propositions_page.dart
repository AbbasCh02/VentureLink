import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/business_model_canvas_provider.dart';

class ValuePropositionsPage extends StatefulWidget {
  const ValuePropositionsPage({super.key});

  @override
  State<ValuePropositionsPage> createState() => _ValuePropositionsPageState();
}

class _ValuePropositionsPageState extends State<ValuePropositionsPage> {
  final TextEditingController _controller = TextEditingController();
  final String _fieldName = 'valuePropositions';
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BusinessModelCanvasProvider>();
      _controller.text = provider.valuePropositions;
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
    provider.updateValuePropositions(_controller.text);
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
          content: Text('Value Propositions saved successfully!'),
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
                    'Value Propositions',
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
                      'Value Propositions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFffa500),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Define and describe the unique value your product or service delivers to your customers. What problem are you solving, and what needs are you satisfying? Why should customers choose you over others?',
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
                    cursorColor: const Color(0xFFffa500),
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
                              ? 'Enter Value Propositions Information'
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
                              ? 'Examples:\n• Newness (completely new offering)\n• Performance (improved functionality)\n• Customization (tailored solutions)\n• Getting the job done (helping customers complete tasks)\n• Design (superior aesthetics/user experience)\n• Brand/status (prestige and recognition)\n• Price (cost advantage or value for money)\n• Cost reduction (helping customers save money)\n• Risk reduction (decreased uncertainty)\n• Accessibility (making things available to new segments)\n• Convenience/usability (ease of use)\n• Speed (faster delivery or results)\n• Quality (superior materials or craftsmanship)'
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

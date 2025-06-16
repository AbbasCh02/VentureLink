// lib/Startup_Dashboard/Business_Model_Canvas/value_propositions_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/business_model_canvas_provider.dart';

class KeyPartnersPage extends StatefulWidget {
  const KeyPartnersPage({super.key});

  @override
  State<KeyPartnersPage> createState() => _KeyPartnersPageState();
}

class _KeyPartnersPageState extends State<KeyPartnersPage> {
  final TextEditingController _controller = TextEditingController();
  final String _fieldName = 'keyPartners';
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<BusinessModelCanvasProvider>();
        _controller.text = provider.valuePropositions;
        _controller.addListener(_onTextChanged);

        // Listen to focus changes
        _focusNode.addListener(() {
          if (mounted) {
            setState(() {
              _isFocused = _focusNode.hasFocus;
            });
          }
        });
      }
    });
  }

  void _onTextChanged() {
    if (mounted) {
      final provider = context.read<BusinessModelCanvasProvider>();
      // Update the provider value without saving to persistence yet
      provider.updateValuePropositions(_controller.text);
      // Trigger rebuild to update hint text display
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        title: const Text(
          'Key Partners',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFffa500)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<BusinessModelCanvasProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFffa500).withValues(alpha: 0.1),
                        const Color(0xFFff8c00).withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFffa500).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Key Partners',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFffa500),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Define and describe the external organizations, individuals, or entities that help your business succeed. Who are your key allies? Which partners are essential to delivering your value proposition, optimizing operations, reducing risk, or acquiring resources?',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Text Field Section
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            _isFocused
                                ? const Color(0xFFffa500)
                                : Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            provider.valuePropositions.isEmpty
                                ? 'Examples:\n• Strategic alliances (non-competitors)\n• Joint ventures\n• Buyer-supplier relationships\n• Technology partners\n• Distribution partners\n• Marketing partners\n• Financial partners (investors, banks)\n• Outsourcing partners\n• Regulatory and compliance partners\n• Research and development partners\n• Logistics and fulfillment partners\n• Integration partners (APIs, platforms)'
                                : null,
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          height: 1.5,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        provider.hasUnsavedChanges(_fieldName)
                            ? _saveData
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFffa500),
                      disabledBackgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      provider.hasUnsavedChanges(_fieldName)
                          ? 'Save Changes'
                          : 'No Changes to Save',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

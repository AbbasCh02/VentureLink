// lib/Investor/Investor_Dashboard/investor_bio.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/investor_profile_provider.dart';

class InvestorBio extends StatefulWidget {
  const InvestorBio({super.key});

  @override
  State<InvestorBio> createState() => _InvestorBioState();
}

class _InvestorBioState extends State<InvestorBio>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: _buildAppBar(),
      body: Consumer<InvestorProfileProvider>(
        builder: (context, provider, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _buildHeader(provider),
                      const SizedBox(height: 32),

                      // Professional Bio Section
                      _buildBioSection(provider),
                      const SizedBox(height: 24),

                      // Company Information Section
                      _buildCompanyInfoSection(provider),
                      const SizedBox(height: 24),

                      // Portfolio Information Section
                      _buildPortfolioSection(provider),
                      const SizedBox(height: 24),

                      // Contact Information Section
                      _buildContactSection(provider),
                      const SizedBox(height: 32),

                      // Save Button
                      _buildSaveButton(provider),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.grey[900],
      elevation: 0,
      title: const Text(
        'Professional Bio',
        style: TextStyle(
          color: Color(0xFF65c6f4),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF65c6f4).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF65c6f4)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildHeader(InvestorProfileProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF65c6f4), Color(0xFF5bb3e8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
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
              const Icon(Icons.account_circle, color: Colors.black, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Professional Bio',
                  style: TextStyle(
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
                ? 'Your professional profile is complete. Update any information as needed.'
                : 'Complete your professional bio to showcase your expertise and attract quality startups.',
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

  Widget _buildBioSection(InvestorProfileProvider provider) {
    return _buildSectionCard(
      title: 'Professional Bio',
      child: _buildStyledTextFormField(
        controller: provider.bioController,
        labelText:
            'Tell us about your investment philosophy, experience, and what you bring to startups...',
        maxLines: 6,
        validator: provider.validateBio,
      ),
    );
  }

  Widget _buildCompanyInfoSection(InvestorProfileProvider provider) {
    return _buildSectionCard(
      title: 'Company Information',
      child: Column(
        children: [
          _buildStyledTextFormField(
            controller: provider.companyNameController,
            labelText: 'Company/Firm Name',
            validator: provider.validateCompanyName,
          ),
          const SizedBox(height: 16),
          _buildStyledTextFormField(
            controller: provider.titleController,
            labelText: 'Your Title/Position',
            validator: provider.validateTitle,
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSection(InvestorProfileProvider provider) {
    return _buildSectionCard(
      title: 'Portfolio Information',
      child: _buildPortfolioSizeSelector(provider),
    );
  }

  Widget _buildContactSection(InvestorProfileProvider provider) {
    return _buildSectionCard(
      title: 'Contact Information',
      child: Column(
        children: [
          _buildStyledTextFormField(
            controller: provider.linkedinUrlController,
            labelText: 'LinkedIn Profile',
            keyboardType: TextInputType.url,
            validator: provider.validateUrl,
          ),
          const SizedBox(height: 16),
          _buildStyledTextFormField(
            controller: provider.websiteUrlController,
            labelText: 'Company Website',
            keyboardType: TextInputType.url,
            validator: provider.validateUrl,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.grey[850]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF65c6f4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF65c6f4),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStyledTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String? Function(String?) validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        cursorColor: const Color(0xFF65c6f4),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.grey[800]!.withAlpha(204), // same as 0.8
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF65c6f4), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPortfolioSizeSelector(InvestorProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portfolio Size',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: provider.portfolioSize?.toString() ?? '',
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Number of Portfolio Companies',
            hintText: 'e.g., 25',
            prefixIcon: const Icon(
              Icons.business_center,
              color: Color(0xFF65c6f4),
            ),
            labelStyle: TextStyle(color: Colors.grey[400]),
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF65c6f4), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the number of companies in your portfolio';
            }
            final number = int.tryParse(value);
            if (number == null) {
              return 'Please enter a valid number';
            }
            if (number < 0) {
              return 'Portfolio size cannot be negative';
            }
            if (number > 1000) {
              return 'Portfolio size seems too large. Please verify.';
            }
            return null;
          },
          onChanged: (value) {
            final number = int.tryParse(value);
            if (number != null) {
              provider.updatePortfolioSize(number);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton(InvestorProfileProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveBio,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF65c6f4),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_outlined, size: 20),
            SizedBox(width: 8),
            Text(
              'Save Professional Bio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBio() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final provider = context.read<InvestorProfileProvider>();
      await provider.saveProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Professional bio saved successfully!'),
              ],
            ),
            backgroundColor: Color(0xFF65c6f4),
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to save bio: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

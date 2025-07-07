// lib/Investor/Investor_Dashboard/investor_companies_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/investor_company_provider.dart';

class InvestorCompaniesPage extends StatefulWidget {
  const InvestorCompaniesPage({super.key});

  @override
  State<InvestorCompaniesPage> createState() => _InvestorCompaniesPageState();
}

class _InvestorCompaniesPageState extends State<InvestorCompaniesPage>
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

    // Initialize provider after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final provider = context.read<InvestorCompaniesProvider>();
        provider.initialize();
      } catch (e) {
        debugPrint('Error initializing provider: $e');
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InvestorCompaniesProvider(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0a0a0a),
        appBar: _buildAppBar(),
        body: Consumer<InvestorCompaniesProvider>(
          builder: (context, provider, child) {
            // Initialize provider if not already done
            if (!provider.isInitialized) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.initialize();
              });
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF65c6f4)),
                ),
              );
            }

            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF65c6f4)),
                ),
              );
            }

            if (provider.error != null) {
              return _buildErrorWidget(provider);
            }

            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _buildHeader(provider),
                      const SizedBox(height: 32),

                      // Progress Section
                      _buildProgressSection(provider),
                      const SizedBox(height: 24),

                      // Add Company Section
                      _buildAddCompanySection(provider),
                      const SizedBox(height: 32),

                      // Companies Grid or Empty State
                      provider.hasCompanies
                          ? _buildCompaniesGrid(provider)
                          : _buildEmptyState(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.grey[900],
      elevation: 0,
      title: const Text(
        'Company Information',
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
      actions: [
        Consumer<InvestorCompaniesProvider>(
          builder: (context, provider, child) {
            if (provider.isSaving) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF65c6f4),
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

  Widget _buildHeader(InvestorCompaniesProvider provider) {
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
              const Icon(Icons.business, color: Colors.black, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Company Information',
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
            provider.hasCompanies
                ? 'Manage your ${provider.companiesCount} companies and showcase your professional experience.'
                : 'Add companies you are associated with to build your professional profile.',
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

  Widget _buildProgressSection(InvestorCompaniesProvider provider) {
    final companiesCount = provider.companiesCount;
    final currentCompaniesCount = provider.currentCompanies.length;

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
                'Company Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[200],
                ),
              ),
              Text(
                '$companiesCount Companies',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF65c6f4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCompanyStatCard(
                  'Total Companies',
                  companiesCount.toString(),
                  Icons.business_outlined,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCompanyStatCard(
                  'Current Roles',
                  currentCompaniesCount.toString(),
                  Icons.star_outline,
                  Colors.amber,
                ),
              ),
            ],
          ),
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

  Widget _buildCompanyStatCard(
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

  Widget _buildAddCompanySection(InvestorCompaniesProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Company',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 20),
            _buildStyledTextFormField(
              controller: provider.companyNameController,
              labelText: 'Company/Firm Name',
              validator: provider.validateCompanyName,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            _buildStyledTextFormField(
              controller: provider.titleController,
              labelText: 'Your Title/Position',
              validator: provider.validateTitle,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            _buildStyledTextFormField(
              controller: provider.websiteController,
              labelText: 'Company Website (Optional)',
              validator: provider.validateWebsite,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    provider.isFormValid && !provider.isSaving
                        ? () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              await provider.addCompany();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Company added successfully!',
                                    ),
                                    backgroundColor: Color(0xFF65c6f4),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to add company: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF65c6f4),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    provider.isSaving
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                        : const Text(
                          'Add Company',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF65c6f4), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey[850],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Icon(Icons.business_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'No companies added yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first company using the form above',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCompaniesGrid(InvestorCompaniesProvider provider) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: provider.companies.length,
      itemBuilder: (context, index) {
        final company = provider.companies[index];
        return _buildCompanyCard(company, provider);
      },
    );
  }

  Widget _buildCompanyCard(
    InvestorCompany company,
    InvestorCompaniesProvider provider,
  ) {
    final isCurrent = provider.currentCompanies.any(
      (current) => current.id == company.id,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? const Color(0xFF65c6f4) : Colors.grey[800]!,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow:
            isCurrent
                ? [
                  BoxShadow(
                    color: const Color(0xFF65c6f4).withValues(alpha: 0.2),
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
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF65c6f4).withValues(alpha: 0.2),
                child: Text(
                  company.companyName.isNotEmpty
                      ? company.companyName[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                    color: Color(0xFF65c6f4),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                color: Colors.grey[800],
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.grey[300], size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: TextStyle(color: Colors.grey[300]),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                onSelected: (value) async {
                  if (value == 'delete') {
                    _showDeleteConfirmation(company, provider);
                  } else if (value == 'edit') {
                    _showEditDialog(company, provider);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            company.companyName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[200],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            company.title,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (company.website.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.link, color: const Color(0xFF65c6f4), size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    company.website,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const Spacer(),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF65c6f4).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF65c6f4).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Current',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF65c6f4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(InvestorCompaniesProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Error loading companies',
            style: TextStyle(fontSize: 18, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            provider.error ?? 'Unknown error occurred',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              provider.initialize();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF65c6f4),
              foregroundColor: Colors.black,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    InvestorCompany company,
    InvestorCompaniesProvider provider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Delete Company',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete ${company.companyName}? This action cannot be undone.',
              style: TextStyle(color: Colors.grey[300]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await provider.deleteCompany(company.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Company deleted successfully'),
                          backgroundColor: Color(0xFF65c6f4),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete company: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showEditDialog(
    InvestorCompany company,
    InvestorCompaniesProvider provider,
  ) {
    final companyNameController = TextEditingController(
      text: company.companyName,
    );
    final titleController = TextEditingController(text: company.title);
    final websiteController = TextEditingController(text: company.website);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Edit Company',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStyledTextFormField(
                      controller: companyNameController,
                      labelText: 'Company Name',
                      validator: provider.validateCompanyName,
                    ),
                    const SizedBox(height: 16),
                    _buildStyledTextFormField(
                      controller: titleController,
                      labelText: 'Title',
                      validator: provider.validateTitle,
                    ),
                    const SizedBox(height: 16),
                    _buildStyledTextFormField(
                      controller: websiteController,
                      labelText: 'Website (Optional)',
                      validator: provider.validateWebsite,
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context);
                    try {
                      final updatedCompany = company.copyWith(
                        companyName: companyNameController.text.trim(),
                        title: titleController.text.trim(),
                        website: websiteController.text.trim(),
                      );
                      await provider.updateCompany(updatedCompany);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Company updated successfully'),
                            backgroundColor: Color(0xFF65c6f4),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update company: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF65c6f4),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
}

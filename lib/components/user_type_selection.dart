// lib/components/user_type_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/unified_authentication_provider.dart';

class UserTypeSelector extends StatelessWidget {
  final bool isRequired;
  final String? errorText;
  final Function(UserType)? onUserTypeSelected;

  const UserTypeSelector({
    super.key,
    this.isRequired = true,
    this.errorText,
    this.onUserTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedAuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                const Text(
                  'I am a',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isRequired)
                  const Text(
                    ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // User type cards
            Row(
              children: [
                // Startup option
                Expanded(
                  child: _UserTypeCard(
                    userType: UserType.startup,
                    title: 'Startup',
                    subtitle: 'Looking for investment',
                    icon: Icons.rocket_launch,
                    iconColor: const Color(0xFFffa500),
                    isSelected:
                        authProvider.selectedUserType == UserType.startup,
                    onTap: () {
                      authProvider.setUserType(UserType.startup);
                      onUserTypeSelected?.call(UserType.startup);
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Investor option
                Expanded(
                  child: _UserTypeCard(
                    userType: UserType.investor,
                    title: 'Investor',
                    subtitle: 'Looking to invest',
                    icon: Icons.account_balance,
                    iconColor: const Color(0xFF65c6f4),
                    isSelected:
                        authProvider.selectedUserType == UserType.investor,
                    onTap: () {
                      authProvider.setUserType(UserType.investor);
                      onUserTypeSelected?.call(UserType.investor);
                    },
                  ),
                ),
              ],
            ),

            // Error text
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  final UserType userType;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.userType,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? iconColor.withOpacity(0.1) : const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? iconColor : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: iconColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    isSelected ? iconColor.withOpacity(0.2) : Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? iconColor : Colors.grey[400],
                size: 24,
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[300],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? Colors.grey[300] : Colors.grey[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),

            // Selection indicator
            if (isSelected) ...[
              const SizedBox(height: 8),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

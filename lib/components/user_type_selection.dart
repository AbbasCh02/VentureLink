/**
 * user_type_selector.dart
 * 
 * Provides a reusable component for user type selection between startup and investor.
 * Features animated transitions, visual feedback, and integration with the authentication provider.
 * 
 * Used in signup flows and profile settings where users need to select their role in the platform.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/unified_authentication_provider.dart';

/**
 * UserTypeSelector - A stateless widget that provides a styled interface
 * for selecting between startup and investor user types.
 * 
 * Features:
 * - Visually appealing selection cards with animations
 * - Color-coded user types (orange for startup, blue for investor)
 * - Required field indication
 * - Error message display
 * - Callback on selection
 */
class UserTypeSelector extends StatelessWidget {
  // Whether this field is required (shows asterisk if true)
  final bool isRequired;

  // Error message to display (if validation fails)
  final String? errorText;

  // Callback that fires when a user type is selected
  final Function(UserType)? onUserTypeSelected;

  /**
   * Constructor for UserTypeSelector
   * 
   * @param key Widget key
   * @param isRequired Whether selection is required (default: true)
   * @param errorText Error message to display if validation fails
   * @param onUserTypeSelected Callback that triggers when a user type is selected
   */
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
            // Title with optional required indicator
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
                // Show red asterisk if required
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

            // User type selection cards in a row
            Row(
              children: [
                // Startup option
                Expanded(
                  child: _UserTypeCard(
                    userType: UserType.startup,
                    title: 'Startup',
                    subtitle: 'Looking for investment',
                    icon: Icons.rocket_launch,
                    iconColor: const Color(0xFFffa500), // Orange for startups
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
                    iconColor: const Color(0xFF65c6f4), // Blue for investors
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

            // Error message (shown conditionally)
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

/**
 * _UserTypeCard - A private helper widget that renders an individual
 * user type selection card with animations and visual feedback.
 * 
 * Each card displays an icon, title, subtitle, and selection indicator.
 * When selected, the card changes appearance with color accents and a checkmark.
 */
class _UserTypeCard extends StatelessWidget {
  // User type represented by this card
  final UserType userType;

  // Card title (e.g., "Startup" or "Investor")
  final String title;

  // Card subtitle describing the role
  final String subtitle;

  // Icon to display in the card
  final IconData icon;

  // Theme color for this card (orange for startup, blue for investor)
  final Color iconColor;

  // Whether this card is currently selected
  final bool isSelected;

  // Callback when this card is tapped
  final VoidCallback onTap;

  /**
   * Constructor for _UserTypeCard
   * 
   * @param userType The UserType represented by this card
   * @param title The main title text
   * @param subtitle The descriptive subtitle text
   * @param icon The icon to display
   * @param iconColor The theme color for this card
   * @param isSelected Whether this card is currently selected
   * @param onTap Callback to execute when tapped
   */
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
        // Animate changes when selection state changes
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Background color changes based on selection
          color:
              isSelected
                  ? iconColor.withValues(
                    alpha: 0.1,
                  ) // Subtle theme color when selected
                  : const Color(0xFF1a1a1a), // Dark gray when not selected
          borderRadius: BorderRadius.circular(12),
          // Border changes color and thickness based on selection
          border: Border.all(
            color: isSelected ? iconColor : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
          // Add glow effect when selected
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container with themed background
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? iconColor.withValues(
                          alpha: 0.2,
                        ) // Themed background when selected
                        : Colors.grey[850], // Dark gray when not selected
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? iconColor : Colors.grey[400],
                size: 24,
              ),
            ),
            const SizedBox(height: 12),

            // Title text
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[300],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle text
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? Colors.grey[300] : Colors.grey[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),

            // Selection indicator (checkmark) - only shown when selected
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

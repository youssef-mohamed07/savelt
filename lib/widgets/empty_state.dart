import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../core/theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? lottieAsset;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.lottieAsset,
    this.icon,
    this.actionText,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation or Icon
            if (lottieAsset != null)
              SizedBox(
                width: 200,
                height: 200,
                child: Lottie.asset(
                  lottieAsset!,
                  repeat: false,
                ),
              )
            else if (icon != null)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[800]?.withValues(alpha: 0.8) ?? Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon!,
                  size: 60,
                  color: iconColor ?? AppColors.primary,
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Action Button
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionText!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Predefined empty states
class EmptyStates {
  static Widget noTransactions({VoidCallback? onAddTransaction}) {
    return const EmptyState(
      title: 'No Transactions Yet',
      subtitle: 'Start tracking your expenses by adding your first transaction.',
      icon: Icons.receipt_long_outlined,
      iconColor: AppColors.primary,
    );
  }

  static Widget noCategories({VoidCallback? onAddCategory}) {
    return EmptyState(
      title: 'No Categories',
      subtitle: 'Create categories to organize your expenses better.',
      icon: Icons.category_outlined,
      iconColor: AppColors.secondary,
      actionText: 'Add Category',
      onAction: onAddCategory,
    );
  }

  static Widget noItems({VoidCallback? onAddItem}) {
    return EmptyState(
      title: 'No Items Found',
      subtitle: 'No items match your current filters or search criteria.',
      icon: Icons.inventory_2_outlined,
      iconColor: AppColors.primary,
      actionText: 'Add Item',
      onAction: onAddItem,
    );
  }

  static Widget noReminders({VoidCallback? onAddReminder}) {
    return EmptyState(
      title: 'No Reminders Set',
      subtitle: 'Set reminders to never miss important payments or expenses.',
      icon: Icons.notifications_outlined,
      iconColor: Colors.orange,
      actionText: 'Add Reminder',
      onAction: onAddReminder,
    );
  }

  static Widget noOffers() {
    return const EmptyState(
      title: 'No Offers Available',
      subtitle: 'Check back later for exclusive deals and offers.',
      icon: Icons.local_offer_outlined,
      iconColor: Colors.green,
    );
  }

  static Widget noSearchResults({String? query}) {
    return EmptyState(
      title: 'No Results Found',
      subtitle: query != null 
        ? 'No results found for "$query". Try different keywords.'
        : 'No results found. Try adjusting your search criteria.',
      icon: Icons.search_off_outlined,
      iconColor: Colors.grey,
    );
  }

  static Widget offline({VoidCallback? onRetry}) {
    return EmptyState(
      title: 'You\'re Offline',
      subtitle: 'Please check your internet connection and try again.',
      icon: Icons.wifi_off_outlined,
      iconColor: Colors.red,
      actionText: 'Retry',
      onAction: onRetry,
    );
  }

  static Widget error({
    String? message,
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      title: 'Something Went Wrong',
      subtitle: message ?? 'An unexpected error occurred. Please try again.',
      icon: Icons.error_outline,
      iconColor: Colors.red,
      actionText: 'Try Again',
      onAction: onRetry,
    );
  }
}
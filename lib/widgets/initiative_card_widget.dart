import 'package:flutter/material.dart';
import '../models/models.dart';

/// Widget that displays an initiative card with platform variant information
class InitiativeCardWidget extends StatelessWidget {
  const InitiativeCardWidget({
    super.key,
    required this.variant,
    this.isDragFeedback = false,
  });

  final PlatformVariant variant;
  final bool isDragFeedback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: isDragFeedback ? 8 : 2,
      margin: const EdgeInsets.all(4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: _getPlatformColor(variant.platformType),
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Platform type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPlatformColor(variant.platformType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                variant.platformType.displayName.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _getPlatformColor(variant.platformType),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Initiative title
            Text(
              variant.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            // Estimated effort
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${variant.estimatedWeeks}w',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            // Assignment status
            if (variant.isAssigned) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPlatformColor(PlatformType platformType) {
    switch (platformType) {
      case PlatformType.backend:
        return Colors.blue;
      case PlatformType.frontend:
        return Colors.green;
      case PlatformType.mobile:
        return Colors.orange;
      case PlatformType.qa:
        return Colors.red;
    }
  }
}
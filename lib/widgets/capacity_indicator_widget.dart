import 'package:flutter/material.dart';
import '../models/models.dart';

/// Widget that displays capacity information for a week
class CapacityIndicatorWidget extends StatelessWidget {
  const CapacityIndicatorWidget({
    super.key,
    required this.capacityPeriod,
    this.isCompact = false,
  });

  final CapacityPeriod capacityPeriod;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final utilization = capacityPeriod.utilizationPercentage;
    final isOverAllocated = capacityPeriod.calculatedIsOverAllocated;
    
    if (isCompact) {
      return _buildCompactIndicator(theme, utilization, isOverAllocated);
    } else {
      return _buildDetailedIndicator(theme, utilization, isOverAllocated);
    }
  }

  Widget _buildCompactIndicator(ThemeData theme, double utilization, bool isOverAllocated) {
    final color = _getUtilizationColor(utilization, isOverAllocated);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getUtilizationIcon(utilization, isOverAllocated),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${utilization.toStringAsFixed(0)}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedIndicator(ThemeData theme, double utilization, bool isOverAllocated) {
    final color = _getUtilizationColor(utilization, isOverAllocated);
    
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                _getUtilizationIcon(utilization, isOverAllocated),
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                'Capacity',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${utilization.toStringAsFixed(0)}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Progress bar
          LinearProgressIndicator(
            value: (utilization / 100).clamp(0.0, 1.0),
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
          
          const SizedBox(height: 8),
          
          // Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available: ${capacityPeriod.totalCapacityAvailable.toStringAsFixed(1)}h',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Used: ${capacityPeriod.calculatedUtilizedCapacity.toStringAsFixed(1)}h',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          
          // Warning message for over-allocation
          if (isOverAllocated) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 14,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Over-allocated by ${(capacityPeriod.calculatedUtilizedCapacity - capacityPeriod.totalCapacityAvailable).toStringAsFixed(1)}h',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getUtilizationColor(double utilization, bool isOverAllocated) {
    if (isOverAllocated) {
      return Colors.red;
    } else if (utilization >= 90) {
      return Colors.orange;
    } else if (utilization >= 70) {
      return Colors.yellow.shade700;
    } else {
      return Colors.green;
    }
  }

  IconData _getUtilizationIcon(double utilization, bool isOverAllocated) {
    if (isOverAllocated) {
      return Icons.error;
    } else if (utilization >= 90) {
      return Icons.warning;
    } else if (utilization >= 70) {
      return Icons.schedule;
    } else {
      return Icons.check_circle;
    }
  }
}
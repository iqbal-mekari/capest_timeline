import 'package:flutter/material.dart';
import '../models/models.dart';
import 'initiative_card_widget.dart';
import 'capacity_indicator_widget.dart';

/// Widget that displays a single week column in the kanban board
class WeekColumnWidget extends StatefulWidget {
  const WeekColumnWidget({
    super.key,
    required this.week,
    required this.variants,
    required this.capacityPeriod,
    required this.onVariantDropped,
  });

  final DateTime week;
  final List<PlatformVariant> variants;
  final CapacityPeriod? capacityPeriod;
  final Future<bool> Function(PlatformVariant variant, DateTime targetWeek) onVariantDropped;

  @override
  State<WeekColumnWidget> createState() => _WeekColumnWidgetState();
}

class _WeekColumnWidgetState extends State<WeekColumnWidget> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 300,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        color: _isDragOver 
          ? theme.colorScheme.primaryContainer.withOpacity(0.1)
          : null,
      ),
      child: Column(
        children: [
          // Week header space (handled by parent)
          const SizedBox(height: 60),
          
          // Capacity indicator
          if (widget.capacityPeriod != null)
            CapacityIndicatorWidget(
              capacityPeriod: widget.capacityPeriod!,
              isCompact: true,
            ),
          
          // Drop target area
          Expanded(
            child: DragTarget<PlatformVariant>(
              onWillAccept: (variant) {
                // Only accept if variant is not already assigned to this week
                return variant != null && 
                       !_isVariantInThisWeek(variant) &&
                       !variant.isAssigned;
              },
              onAccept: (variant) async {
                setState(() {
                  _isDragOver = false;
                });
                
                try {
                  final success = await widget.onVariantDropped(variant, widget.week);
                  
                  if (!success && mounted) {
                    _showDropErrorSnackBar();
                  }
                } catch (e) {
                  if (mounted) {
                    _showDropErrorSnackBar();
                  }
                }
              },
              onMove: (details) {
                if (!_isDragOver) {
                  setState(() {
                    _isDragOver = true;
                  });
                }
              },
              onLeave: (data) {
                setState(() {
                  _isDragOver = false;
                });
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      // Show drop hint when dragging over
                      if (_isDragOver && candidateData.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Drop here to schedule',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Existing variants in this week
                      ...widget.variants.map((variant) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InitiativeCardWidget(variant: variant),
                      )).toList(),
                      
                      // Empty state when no variants
                      if (widget.variants.isEmpty && !_isDragOver)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.dividerColor,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.drag_indicator,
                                    size: 32,
                                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Drop initiatives here',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isVariantInThisWeek(PlatformVariant variant) {
    // Check if variant is already scheduled for this week
    final weekStart = widget.week;
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    return variant.currentWeek.isAfter(weekStart.subtract(const Duration(days: 1))) &&
           variant.currentWeek.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  void _showDropErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Could not schedule initiative. Check capacity constraints.'),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
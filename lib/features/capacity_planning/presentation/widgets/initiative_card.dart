import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/initiative.dart';
import '../../../../core/enums/role.dart';
import '../../../../shared/themes/app_theme.dart';

/// A card widget that displays initiative information with interactive capabilities.
/// 
/// This widget provides:
/// - Comprehensive initiative information display
/// - Progress tracking and status visualization
/// - Team requirements and allocation status
/// - Timeline and deadline indicators
/// - Interactive actions (edit, assign team, view details)
/// - Accessibility support
class InitiativeCard extends StatefulWidget {
  const InitiativeCard({
    super.key,
    required this.initiative,
    this.onTap,
    this.onEdit,
    this.onAssignTeam,
    this.onViewDetails,
    this.showProgress = true,
    this.showTeamRequirements = true,
    this.showActions = true,
    this.isSelected = false,
    this.isCompact = false,
    this.completionPercentage = 0.0,
    this.teamAllocationStatus,
  });

  /// The initiative to display
  final Initiative initiative;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Callback when edit action is triggered
  final VoidCallback? onEdit;

  /// Callback when assign team action is triggered
  final VoidCallback? onAssignTeam;

  /// Callback when view details action is triggered
  final VoidCallback? onViewDetails;

  /// Whether to show progress information
  final bool showProgress;

  /// Whether to show team requirements
  final bool showTeamRequirements;

  /// Whether to show action buttons
  final bool showActions;

  /// Whether this card is currently selected
  final bool isSelected;

  /// Whether to use compact layout
  final bool isCompact;

  /// Current completion percentage (0.0 to 1.0)
  final double completionPercentage;

  /// Team allocation status information
  final Map<Role, int>? teamAllocationStatus;

  @override
  State<InitiativeCard> createState() => _InitiativeCardState();
}

class _InitiativeCardState extends State<InitiativeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  Color _getStatusColor() {
    if (widget.completionPercentage >= 1.0) {
      return AppTheme.allocatedColor; // Completed
    } else if (widget.completionPercentage > 0.0) {
      return Colors.orange; // In progress
    } else {
      return AppTheme.availableColor; // Not started
    }
  }

  String _getStatusText() {
    if (widget.completionPercentage >= 1.0) {
      return 'Completed';
    } else if (widget.completionPercentage > 0.0) {
      return 'In Progress';
    } else {
      return 'Planned';
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Priority indicator
        Container(
          width: widget.isCompact ? 3 : 4,
          height: widget.isCompact ? 40 : 50,
          decoration: BoxDecoration(
            color: _getPriorityColor(),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Title and description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initiative.name,
                style: widget.isCompact
                    ? AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)
                    : AppTheme.headingSmall.copyWith(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!widget.isCompact && widget.initiative.description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  widget.initiative.description,
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        
        // Status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor(),
              width: 1,
            ),
          ),
          child: Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor() {
    if (widget.initiative.priority >= 8) {
      return AppTheme.overallocatedColor; // High priority
    } else if (widget.initiative.priority >= 5) {
      return Colors.orange; // Medium priority
    } else {
      return AppTheme.availableColor; // Low priority
    }
  }

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${widget.initiative.totalEffort} person-weeks',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // Progress bar
        LinearProgressIndicator(
          value: widget.completionPercentage,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
          minHeight: 6,
        ),
        
        const SizedBox(height: 2),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completed: ${(widget.completionPercentage * 100).round()}%',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              'Priority: ${widget.initiative.priority}/10',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamRequirements() {
    if (!widget.showTeamRequirements || widget.initiative.requiredRoles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Roles',
          style: AppTheme.bodySmall.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: widget.initiative.requiredRoles.entries.map((entry) {
            final role = entry.key;
            final effort = entry.value;
            final allocated = widget.teamAllocationStatus?[role] ?? 0;
            final isFullyStaffed = allocated >= effort.ceil();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.getRoleColor(role.name).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFullyStaffed 
                      ? AppTheme.getRoleColor(role.name)
                      : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    role.displayName,
                    style: TextStyle(
                      color: AppTheme.getRoleColor(role.name),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${effort}w',
                    style: TextStyle(
                      color: AppTheme.getRoleColor(role.name),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActions() {
    if (!widget.showActions) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.onEdit != null)
          IconButton(
            onPressed: widget.onEdit,
            icon: const Icon(Icons.edit, size: 18),
            tooltip: 'Edit ${widget.initiative.name}',
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        
        if (widget.onAssignTeam != null)
          IconButton(
            onPressed: widget.onAssignTeam,
            icon: const Icon(Icons.group_add, size: 18),
            tooltip: 'Assign Team Members',
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        
        if (widget.onViewDetails != null)
          IconButton(
            onPressed: widget.onViewDetails,
            icon: const Icon(Icons.info_outline, size: 18),
            tooltip: 'View Details',
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
      ],
    );
  }

  String _getAccessibilityLabel() {
    final status = _getStatusText();
    final priority = widget.initiative.priority;
    final progress = (widget.completionPercentage * 100).round();
    final requirements = widget.initiative.requiredRoles.entries
        .map((e) => '${e.value} weeks ${e.key.displayName}')
        .join(', ');
    
    return 'Initiative ${widget.initiative.name}, ${widget.initiative.description}. '
           'Priority: $priority out of 10. Status: $status. Progress: $progress percent. '
           'Required roles: $requirements. '
           'Total effort: ${widget.initiative.totalEffort} person-weeks. '
           'Business value: ${widget.initiative.businessValue} out of 10. '
           'Tap to select, double tap to edit.';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _getAccessibilityLabel(),
      button: true,
      selected: widget.isSelected,
      child: MouseRegion(
        onEnter: (_) => _handleHover(true),
        onExit: (_) => _handleHover(false),
        child: AnimatedBuilder(
          animation: _elevationAnimation,
          builder: (context, child) {
            return Card(
              elevation: widget.isSelected ? 8.0 : _elevationAnimation.value,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: widget.isSelected
                    ? BorderSide(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        width: 2,
                      )
                    : BorderSide.none,
              ),
              child: InkWell(
                onTap: _handleTap,
                onDoubleTap: widget.onEdit,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      
                      if (widget.showProgress && !widget.isCompact) ...[
                        const SizedBox(height: 12),
                        _buildProgress(),
                      ],
                      
                      if (widget.showTeamRequirements && !widget.isCompact) ...[
                        const SizedBox(height: 12),
                        _buildTeamRequirements(),
                      ],
                      
                      if (widget.showActions && !widget.isCompact) ...[
                        const SizedBox(height: 8),
                        _buildActions(),
                      ],
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
}
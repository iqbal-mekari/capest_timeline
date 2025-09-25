import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/team_member.dart';
import '../../../../core/enums/role.dart';
import '../../../../shared/themes/app_theme.dart';

/// A card widget that displays team member information with interactive capabilities.
/// 
/// This widget provides:
/// - Comprehensive team member information display
/// - Capacity utilization visualization  
/// - Role and skill level indicators
/// - Availability status and periods
/// - Interactive actions (edit, assign, view details)
/// - Accessibility support
class TeamMemberCard extends StatefulWidget {
  const TeamMemberCard({
    super.key,
    required this.teamMember,
    this.onTap,
    this.onEdit,
    this.onAssign,
    this.onViewDetails,
    this.showCapacityUtilization = true,
    this.showAvailability = true,
    this.showActions = true,
    this.isSelected = false,
    this.isCompact = false,
    this.currentUtilization = 0.0,
    this.maxUtilization = 1.0,
  });

  /// The team member to display
  final TeamMember teamMember;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Callback when edit action is triggered
  final VoidCallback? onEdit;

  /// Callback when assign action is triggered
  final VoidCallback? onAssign;

  /// Callback when view details action is triggered
  final VoidCallback? onViewDetails;

  /// Whether to show capacity utilization bar
  final bool showCapacityUtilization;

  /// Whether to show availability information
  final bool showAvailability;

  /// Whether to show action buttons
  final bool showActions;

  /// Whether this card is currently selected
  final bool isSelected;

  /// Whether to use compact layout
  final bool isCompact;

  /// Current capacity utilization (0.0 to 1.0+)
  final double currentUtilization;

  /// Maximum recommended utilization (typically 1.0)
  final double maxUtilization;

  @override
  State<TeamMemberCard> createState() => _TeamMemberCardState();
}

class _TeamMemberCardState extends State<TeamMemberCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

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
    setState(() {
      _isHovered = isHovered;
    });

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
    if (!widget.teamMember.isActive) {
      return Colors.grey;
    }
    
    if (widget.currentUtilization > widget.maxUtilization * 1.1) {
      return AppTheme.overallocatedColor;
    } else if (widget.currentUtilization > widget.maxUtilization * 0.9) {
      return Colors.orange; // Warning color
    } else {
      return AppTheme.availableColor;
    }
  }

  String _getStatusText() {
    if (!widget.teamMember.isActive) {
      return 'Inactive';
    }
    
    if (widget.currentUtilization > widget.maxUtilization * 1.1) {
      return 'Overallocated';
    } else if (widget.currentUtilization > widget.maxUtilization * 0.9) {
      return 'Near Capacity';
    } else {
      return 'Available';
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: widget.isCompact ? 16 : 20,
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          child: Text(
            widget.teamMember.name.isNotEmpty 
                ? widget.teamMember.name[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.isCompact ? 14 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Name and email
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.teamMember.name,
                style: widget.isCompact
                    ? AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)
                    : AppTheme.headingSmall.copyWith(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!widget.isCompact) ...[
                const SizedBox(height: 2),
                Text(
                  widget.teamMember.email,
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
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

  Widget _buildRolesAndSkills() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Roles
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: widget.teamMember.roles.map((role) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.getRoleColor(role.name).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.getRoleColor(role.name),
                  width: 1,
                ),
              ),
              child: Text(
                role.displayName,
                style: TextStyle(
                  color: AppTheme.getRoleColor(role.name),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
        
        if (!widget.isCompact) ...[
          const SizedBox(height: 8),
          
          // Skill level
          Row(
            children: [
              Text(
                'Skill Level:',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              ...List.generate(10, (index) {
                final isActive = index < widget.teamMember.skillLevel;
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? AppTheme.lightTheme.colorScheme.primary
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text(
                '${widget.teamMember.skillLevel}/10',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCapacityUtilization() {
    if (!widget.showCapacityUtilization) return const SizedBox.shrink();

    final utilizationPercent = (widget.currentUtilization * 100).round();
    final maxPercent = (widget.maxUtilization * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Capacity Utilization',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '$utilizationPercent% of ${maxPercent}%',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        LinearProgressIndicator(
          value: widget.currentUtilization / widget.maxUtilization,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildAvailability() {
    if (!widget.showAvailability || widget.teamMember.unavailablePeriods.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentPeriods = widget.teamMember.unavailablePeriods
        .where((period) => 
            period.startDate.isBefore(DateTime.now().add(const Duration(days: 30))) &&
            period.endDate.isAfter(DateTime.now()))
        .toList();

    if (currentPeriods.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Unavailability',
          style: AppTheme.bodySmall.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        ...currentPeriods.take(2).map((period) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${period.startDate.month}/${period.startDate.day} - ${period.endDate.month}/${period.endDate.day}: ${period.reason}',
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.orange.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
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
            tooltip: 'Edit ${widget.teamMember.name}',
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        
        if (widget.onAssign != null)
          IconButton(
            onPressed: widget.onAssign,
            icon: const Icon(Icons.assignment, size: 18),
            tooltip: 'Assign to Initiative',
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
    final roles = widget.teamMember.roles.map((r) => r.displayName).join(', ');
    final utilization = (widget.currentUtilization * 100).round();
    
    return 'Team member ${widget.teamMember.name}, ${widget.teamMember.email}. '
           'Roles: $roles. Skill level: ${widget.teamMember.skillLevel} out of 10. '
           'Status: $status. Capacity utilization: $utilization percent. '
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
                      
                      const SizedBox(height: 12),
                      _buildRolesAndSkills(),
                      
                      if (widget.showCapacityUtilization && !widget.isCompact) ...[
                        const SizedBox(height: 12),
                        _buildCapacityUtilization(),
                      ],
                      
                      if (widget.showAvailability && !widget.isCompact) ...[
                        const SizedBox(height: 8),
                        _buildAvailability(),
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
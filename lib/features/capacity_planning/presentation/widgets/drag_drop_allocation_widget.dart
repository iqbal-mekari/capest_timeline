import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/capacity_allocation.dart';
import '../../domain/entities/initiative.dart';
import '../../../team_management/domain/entities/team_member.dart';
import '../../../../core/enums/role.dart';
import '../../../../shared/themes/app_theme.dart';

/// A draggable widget representing a capacity allocation that can be moved
/// between different time slots and team members in the timeline view.
/// 
/// This widget implements accessibility features, visual feedback during drag
/// operations, and proper state management integration for real-time updates.
class DragDropAllocationWidget extends StatefulWidget {
  const DragDropAllocationWidget({
    super.key,
    required this.allocation,
    required this.initiative,
    required this.teamMember,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.onDragUpdate,
    this.isSelected = false,
    this.isDragTarget = false,
    this.conflictState = AllocationConflictState.none,
    this.width = 120.0,
    this.height = 32.0,
  });

  /// The capacity allocation this widget represents
  final CapacityAllocation allocation;

  /// The initiative associated with this allocation
  final Initiative initiative;

  /// The team member assigned to this allocation
  final TeamMember teamMember;

  /// Callback when drag operation starts
  final VoidCallback onDragStarted;

  /// Callback when drag operation completes
  final void Function(DragEndDetails details) onDragEnd;

  /// Callback during drag operation for real-time feedback
  final void Function(DragUpdateDetails details) onDragUpdate;

  /// Whether this allocation is currently selected
  final bool isSelected;

  /// Whether this allocation is a valid drag target
  final bool isDragTarget;

  /// Current conflict state for visual feedback
  final AllocationConflictState conflictState;

  /// Width of the allocation widget
  final double width;

  /// Height of the allocation widget
  final double height;

  @override
  State<DragDropAllocationWidget> createState() => _DragDropAllocationWidgetState();
}

class _DragDropAllocationWidgetState extends State<DragDropAllocationWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  bool _isDragging = false;
  Offset? _dragOffset;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DragDropAllocationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update animations based on state changes
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _scaleController.forward();
      } else {
        _scaleController.reverse();
      }
    }
  }

  void _handleDragStart() {
    setState(() {
      _isDragging = true;
    });
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    // Trigger scale animation
    _scaleController.forward();
    
    widget.onDragStarted();
  }

  void _handleDragEnd(Velocity velocity, Offset offset, bool wasAccepted) {
    setState(() {
      _isDragging = false;
      _dragOffset = null;
    });
    
    // Reset animations
    _scaleController.reverse();
    
    // Convert to DragEndDetails for the callback
    final details = DragEndDetails(
      velocity: velocity,
      primaryVelocity: velocity.pixelsPerSecond.dx,
    );
    widget.onDragEnd(details);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = details.localPosition;
    });
    
    widget.onDragUpdate(details);
  }

  Color _getAllocationColor() {
    // Return color based on role, with conflict state modifications
    final baseColor = AppTheme.getRoleColor(widget.allocation.role.name);
    
    switch (widget.conflictState) {
      case AllocationConflictState.conflict:
        return AppTheme.conflictColor;
      case AllocationConflictState.overallocated:
        return AppTheme.overallocatedColor;
      case AllocationConflictState.warning:
        return baseColor.withOpacity(0.7);
      case AllocationConflictState.none:
        return baseColor;
    }
  }

  String _getAccessibilityLabel() {
    final duration = widget.allocation.durationInWeeks.toStringAsFixed(1);
    final role = widget.allocation.role.displayName;
    final member = widget.teamMember.name;
    final initiative = widget.initiative.name;
    
    return 'Allocation: $duration weeks, $role, $member on $initiative. '
           'Double tap to select, drag to move.';
  }

  Widget _buildAllocationContent() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: _getAllocationColor(),
        borderRadius: BorderRadius.circular(6),
        border: widget.isSelected
            ? Border.all(color: Colors.white, width: 2)
            : null,
        boxShadow: _isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : widget.isSelected
                ? [
                    BoxShadow(
                      color: _getAllocationColor().withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            // Background pattern for visual interest
            if (widget.isDragTarget)
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(_glowAnimation.value * 0.3),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  );
                },
              ),
            
            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Initiative name (truncated)
                  Text(
                    widget.initiative.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Allocation details
                  Text(
                    '${widget.allocation.allocatedWeeks.toStringAsFixed(1)}w',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            
            // Conflict indicator
            if (widget.conflictState != AllocationConflictState.none)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getConflictIndicatorColor(),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getConflictIndicatorColor() {
    switch (widget.conflictState) {
      case AllocationConflictState.conflict:
        return Colors.red;
      case AllocationConflictState.overallocated:
        return Colors.orange;
      case AllocationConflictState.warning:
        return Colors.yellow;
      case AllocationConflictState.none:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _getAccessibilityLabel(),
      button: true,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Draggable<AllocationDragData>(
              data: AllocationDragData(
                allocation: widget.allocation,
                initiative: widget.initiative,
                teamMember: widget.teamMember,
                originalPosition: _dragOffset ?? Offset.zero,
              ),
              feedback: Material(
                color: Colors.transparent,
                child: Transform.scale(
                  scale: 1.1,
                  child: Opacity(
                    opacity: 0.8,
                    child: _buildAllocationContent(),
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildAllocationContent(),
              ),
              onDragStarted: _handleDragStart,
              onDragEnd: (details) {
                _handleDragEnd(details.velocity, details.offset, true);
              },
              onDragUpdate: _handleDragUpdate,
              child: GestureDetector(
                onDoubleTap: () {
                  // Handle selection toggle
                  HapticFeedback.selectionClick();
                },
                child: _buildAllocationContent(),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Data structure passed during drag operations
class AllocationDragData {
  const AllocationDragData({
    required this.allocation,
    required this.initiative,
    required this.teamMember,
    required this.originalPosition,
  });

  final CapacityAllocation allocation;
  final Initiative initiative;
  final TeamMember teamMember;
  final Offset originalPosition;
}

/// States representing allocation conflicts for visual feedback
enum AllocationConflictState {
  /// No conflicts detected
  none,
  
  /// Allocation conflicts with another allocation
  conflict,
  
  /// Team member is over-allocated
  overallocated,
  
  /// Potential issue that needs attention
  warning,
}
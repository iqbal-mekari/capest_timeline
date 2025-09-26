import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/capacity_allocation.dart';
import '../../domain/entities/initiative.dart';
import '../../domain/entities/quarter_plan.dart';
import '../../../team_management/domain/entities/team_member.dart';
import '../providers/capacity_planning_provider.dart';
import 'drag_drop_allocation_widget.dart';
import '../../../../shared/themes/app_theme.dart';
import '../../../../core/enums/role.dart';

/// A timeline widget that displays capacity allocations with drag-drop functionality.
/// 
/// This widget provides:
/// - Visual timeline representation of allocations
/// - Drag and drop support for moving allocations
/// - Real-time validation and conflict detection
/// - Responsive layout for different screen sizes
/// - Accessibility support for keyboard navigation
class TimelineWidget extends StatefulWidget {
  const TimelineWidget({
    super.key,
    required this.quarterPlan,
    this.showWeekNumbers = true,
    this.showTeamMemberNames = true,
    this.cellWidth = 120.0,
    this.cellHeight = 40.0,
    this.headerHeight = 50.0,
  });

  /// The quarter plan to display in the timeline
  final QuarterPlan quarterPlan;

  /// Whether to show week numbers in the header
  final bool showWeekNumbers;

  /// Whether to show team member names in the left column
  final bool showTeamMemberNames;

  /// Width of each timeline cell
  final double cellWidth;

  /// Height of each timeline cell
  final double cellHeight;

  /// Height of the timeline header
  final double headerHeight;

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  
  String? _dragTargetTeamMemberId;
  int? _dragTargetWeek;
  AllocationDragData? _currentDragData;

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  /// Calculates the number of weeks in the quarter
  int get _totalWeeks {
    final (startDate, endDate) = widget.quarterPlan.quarterDateRange;
    return endDate.difference(startDate).inDays ~/ 7;
  }

  /// Gets the week number for a given date
  int _getWeekNumber(DateTime date) {
    final (startDate, _) = widget.quarterPlan.quarterDateRange;
    return date.difference(startDate).inDays ~/ 7;
  }

  /// Gets the date for a given week number
  DateTime _getDateForWeek(int week) {
    final (startDate, _) = widget.quarterPlan.quarterDateRange;
    return startDate.add(Duration(days: week * 7));
  }

  /// Checks if a drag operation is valid for the given position
  bool _isValidDropTarget(String teamMemberId, int week, AllocationDragData dragData) {
    final provider = context.read<CapacityPlanningProvider>();
    
    // Check if team member can fulfill the required role
    final teamMember = widget.quarterPlan.teamMembers
        .firstWhere((member) => member.id == teamMemberId);
    
    if (!teamMember.canFulfillRole(dragData.allocation.role)) {
      return false;
    }

    // Check for capacity conflicts
    final weekDate = _getDateForWeek(week);
    final endDate = weekDate.add(Duration(days: (dragData.allocation.durationInWeeks * 7).round()));
    
    return provider.validateAllocationMove(
      dragData.allocation,
      teamMemberId,
      weekDate,
      endDate,
    );
  }

  void _handleDragStart(AllocationDragData dragData) {
    setState(() {
      _currentDragData = dragData;
    });
    
    final provider = context.read<CapacityPlanningProvider>();
    provider.startDragOperation(dragData);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragTargetTeamMemberId != null && _dragTargetWeek != null && _currentDragData != null) {
      final provider = context.read<CapacityPlanningProvider>();
      final newStartDate = _getDateForWeek(_dragTargetWeek!);
      
      provider.moveAllocation(
        _currentDragData!.allocation,
        _dragTargetTeamMemberId!,
        newStartDate,
      );
    }

    setState(() {
      _currentDragData = null;
      _dragTargetTeamMemberId = null;
      _dragTargetWeek = null;
    });
    
    final provider = context.read<CapacityPlanningProvider>();
    provider.endDragOperation();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    // Real-time feedback during drag operations
    final provider = context.read<CapacityPlanningProvider>();
    provider.updateDragFeedback(details.globalPosition);
  }

  Widget _buildTimelineHeader() {
    return Container(
      height: widget.headerHeight,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Team member column header
          if (widget.showTeamMemberNames)
            Container(
              width: 150,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: const Text(
                'Team Members',
                style: AppTheme.labelMedium,
              ),
            ),
          
          // Week headers
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_totalWeeks, (index) {
                  final weekDate = _getDateForWeek(index);
                  return Container(
                    width: widget.cellWidth,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.showWeekNumbers)
                          Text(
                            'W${index + 1}',
                            style: AppTheme.labelSmall,
                          ),
                        Text(
                          '${weekDate.month}/${weekDate.day}',
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberRow(TeamMember teamMember) {
    final allocations = widget.quarterPlan.getAllocationsForMember(teamMember.id);
    
    return Container(
      height: widget.cellHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Team member info
          if (widget.showTeamMemberNames)
            Container(
              width: 150,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    teamMember.name,
                    style: AppTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    teamMember.roles.map((r) => r.displayName).join(', '),
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          
          // Timeline cells
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: Stack(
                children: [
                  // Background grid
                  Row(
                    children: List.generate(_totalWeeks, (week) {
                      final isDropTarget = _dragTargetTeamMemberId == teamMember.id &&
                                         _dragTargetWeek == week;
                      
                      return DragTarget<AllocationDragData>(
                        onWillAccept: (data) {
                          return data != null && _isValidDropTarget(teamMember.id, week, data);
                        },
                        onAccept: (data) {
                          setState(() {
                            _dragTargetTeamMemberId = teamMember.id;
                            _dragTargetWeek = week;
                          });
                        },
                        onMove: (details) {
                          setState(() {
                            _dragTargetTeamMemberId = teamMember.id;
                            _dragTargetWeek = week;
                          });
                        },
                        onLeave: (data) {
                          setState(() {
                            _dragTargetTeamMemberId = null;
                            _dragTargetWeek = null;
                          });
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            width: widget.cellWidth,
                            height: widget.cellHeight,
                            decoration: BoxDecoration(
                              color: isDropTarget
                                  ? AppTheme.availableColor
                                  : Colors.transparent,
                              border: Border(
                                right: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                  
                  // Allocations
                  ...allocations.map((allocation) {
                    final initiative = widget.quarterPlan.initiatives
                        .firstWhere((init) => init.id == allocation.initiativeId);
                    
                    final startWeek = _getWeekNumber(allocation.startDate);
                    final leftOffset = startWeek * widget.cellWidth;
                    final width = allocation.durationInWeeks * widget.cellWidth;
                    
                    return Positioned(
                      left: leftOffset,
                      top: 4,
                      child: DragDropAllocationWidget(
                        allocation: allocation,
                        initiative: initiative,
                        teamMember: teamMember,
                        width: width,
                        height: widget.cellHeight - 8,
                        onDragStarted: () => _handleDragStart(AllocationDragData(
                          allocation: allocation,
                          initiative: initiative,
                          teamMember: teamMember,
                          originalPosition: Offset(leftOffset, 0),
                        )),
                        onDragEnd: _handleDragEnd,
                        onDragUpdate: _handleDragUpdate,
                        conflictState: _getConflictState(allocation, teamMember),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  AllocationConflictState _getConflictState(CapacityAllocation allocation, TeamMember teamMember) {
    final provider = context.watch<CapacityPlanningProvider>();
    
    // Check for conflicts using the provider's validation logic
    if (provider.hasAllocationConflict(allocation)) {
      return AllocationConflictState.conflict;
    }
    
    if (provider.isTeamMemberOverallocated(teamMember.id)) {
      return AllocationConflictState.overallocated;
    }
    
    return AllocationConflictState.none;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CapacityPlanningProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            _buildTimelineHeader(),
            Expanded(
              child: SingleChildScrollView(
                controller: _verticalController,
                child: Column(
                  children: widget.quarterPlan.teamMembers
                      .where((member) => member.isActive)
                      .map(_buildTeamMemberRow)
                      .toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Extension methods for timeline calculations
extension TimelineCalculations on DateTime {
  /// Gets the week number within a quarter
  int weekOfQuarter(DateTime quarterStart) {
    return difference(quarterStart).inDays ~/ 7;
  }
}
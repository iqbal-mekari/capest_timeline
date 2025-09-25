import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;

import '../../domain/entities/capacity_allocation.dart';
import '../../domain/entities/quarter_plan.dart';
import '../../../team_management/domain/entities/team_member.dart';

import '../../../../shared/widgets/loading_states.dart';
import '../../../../core/enums/role.dart';

/// A virtualized timeline widget that efficiently handles large datasets.
/// 
/// This widget provides performance optimizations for handling:
/// - Large numbers of team members (100+)
/// - Many weeks/months of timeline data
/// - Complex allocation layouts
/// - Real-time updates without full rebuilds
/// 
/// Key performance features:
/// - Virtual scrolling for both vertical (team members) and horizontal (time) axes
/// - Lazy loading of timeline cells
/// - Efficient layout caching
/// - Optimized rendering pipeline
/// - Memory-conscious allocation tracking
class VirtualizedTimelineWidget extends StatefulWidget {
  const VirtualizedTimelineWidget({
    super.key,
    required this.quarterPlan,
    this.showWeekNumbers = true,
    this.showTeamMemberNames = true,
    this.cellWidth = 120.0,
    this.cellHeight = 40.0,
    this.headerHeight = 50.0,
    this.memberColumnWidth = 150.0,
    this.visibleWeekBuffer = 5,
    this.visibleMemberBuffer = 3,
    this.enableVirtualization = true,
  });

  /// The quarter plan to display in the timeline
  final QuarterPlan quarterPlan;

  /// Whether to show week numbers in the header
  final bool showWeekNumbers;

  /// Whether to show team member names in the left column
  final bool showTeamMemberNames;

  /// Width of each timeline cell
  final double cellWidth;

  /// Height of each timeline cell/row
  final double cellHeight;

  /// Height of the timeline header
  final double headerHeight;

  /// Width of the team member column
  final double memberColumnWidth;

  /// Number of extra weeks to render outside visible area (performance buffer)
  final int visibleWeekBuffer;

  /// Number of extra team members to render outside visible area (performance buffer)
  final int visibleMemberBuffer;

  /// Whether to enable virtualization (can be disabled for debugging)
  final bool enableVirtualization;

  @override
  State<VirtualizedTimelineWidget> createState() => _VirtualizedTimelineWidgetState();
}

class _VirtualizedTimelineWidgetState extends State<VirtualizedTimelineWidget> {
  late ScrollController _horizontalController;
  late ScrollController _verticalController;
  
  // Virtualization state
  int _visibleStartWeek = 0;
  int _visibleEndWeek = 0;
  int _visibleStartMember = 0;
  int _visibleEndMember = 0;
  
  // Cached calculations
  int? _totalWeeks;
  List<TeamMember>? _activeMembers;
  Map<String, List<CapacityAllocation>>? _allocationsByMember;
  
  // Performance tracking
  DateTime? _lastScrollTime;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _calculateInitialViewport();
    _precomputeData();
  }

  @override
  void didUpdateWidget(VirtualizedTimelineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Recalculate if data changed
    if (oldWidget.quarterPlan != widget.quarterPlan) {
      _precomputeData();
      _calculateVisibleRange();
    }
    
    // Update viewport if dimensions changed
    if (oldWidget.cellWidth != widget.cellWidth ||
        oldWidget.cellHeight != widget.cellHeight) {
      _calculateVisibleRange();
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _horizontalController = ScrollController();
    _verticalController = ScrollController();
    
    // Add scroll listeners for virtualization
    _horizontalController.addListener(_onHorizontalScroll);
    _verticalController.addListener(_onVerticalScroll);
  }

  void _calculateInitialViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateVisibleRange();
    });
  }

  void _precomputeData() {
    // Cache total weeks calculation
    final (startDate, endDate) = widget.quarterPlan.quarterDateRange;
    _totalWeeks = endDate.difference(startDate).inDays ~/ 7;
    
    // Cache active members
    _activeMembers = widget.quarterPlan.teamMembers
        .where((member) => member.isActive)
        .toList();
    
    // Cache allocations grouped by member for efficient lookup
    _allocationsByMember = {};
    for (final member in _activeMembers!) {
      _allocationsByMember![member.id] = widget.quarterPlan
          .getAllocationsForMember(member.id);
    }
  }

  void _onHorizontalScroll() {
    if (!widget.enableVirtualization) return;
    
    _lastScrollTime = DateTime.now();
    
    // Debounce scroll calculations for performance
    Future.delayed(const Duration(milliseconds: 16), () {
      if (_lastScrollTime != null &&
          DateTime.now().difference(_lastScrollTime!).inMilliseconds >= 16) {
        _calculateVisibleRange();
      }
    });
  }

  void _onVerticalScroll() {
    if (!widget.enableVirtualization) return;
    
    _lastScrollTime = DateTime.now();
    
    // Debounce scroll calculations for performance
    Future.delayed(const Duration(milliseconds: 16), () {
      if (_lastScrollTime != null &&
          DateTime.now().difference(_lastScrollTime!).inMilliseconds >= 16) {
        _calculateVisibleRange();
      }
    });
  }

  void _calculateVisibleRange() {
    if (!mounted) return;
    
    final context = this.context;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final viewportSize = renderBox.size;
    
    // Calculate visible week range
    final horizontalOffset = _horizontalController.hasClients 
        ? _horizontalController.offset 
        : 0.0;
    final visibleWeekStart = math.max(0, 
        (horizontalOffset / widget.cellWidth).floor() - widget.visibleWeekBuffer);
    final visibleWeeksCount = (viewportSize.width / widget.cellWidth).ceil() + 
        (widget.visibleWeekBuffer * 2);
    final visibleWeekEnd = math.min(_totalWeeks ?? 0, 
        visibleWeekStart + visibleWeeksCount);
    
    // Calculate visible member range
    final verticalOffset = _verticalController.hasClients 
        ? _verticalController.offset 
        : 0.0;
    final visibleMemberStart = math.max(0, 
        (verticalOffset / widget.cellHeight).floor() - widget.visibleMemberBuffer);
    final visibleMembersCount = (viewportSize.height / widget.cellHeight).ceil() + 
        (widget.visibleMemberBuffer * 2);
    final visibleMemberEnd = math.min(_activeMembers?.length ?? 0, 
        visibleMemberStart + visibleMembersCount);
    
    // Update state if ranges changed
    if (_visibleStartWeek != visibleWeekStart ||
        _visibleEndWeek != visibleWeekEnd ||
        _visibleStartMember != visibleMemberStart ||
        _visibleEndMember != visibleMemberEnd) {
      
      setState(() {
        _visibleStartWeek = visibleWeekStart;
        _visibleEndWeek = visibleWeekEnd;
        _visibleStartMember = visibleMemberStart;
        _visibleEndMember = visibleMemberEnd;
      });
    }
  }

  Widget _buildVirtualizedHeader() {
    final totalWidth = (_totalWeeks ?? 0) * widget.cellWidth;
    
    return Container(
      height: widget.headerHeight,
      child: Row(
        children: [
          // Fixed team member column header
          if (widget.showTeamMemberNames)
            Container(
              width: widget.memberColumnWidth,
              height: widget.headerHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  right: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: const Center(
                child: Text('Team Members', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          
          // Scrollable week headers - use separate controller for header
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: totalWidth,
                height: widget.headerHeight,
                child: Stack(
                  children: [
                    // Render only visible week headers
                    for (int week = _visibleStartWeek; week < _visibleEndWeek; week++)
                      _buildWeekHeader(week),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader(int weekIndex) {
    final weekDate = _getDateForWeek(weekIndex);
    final left = weekIndex * widget.cellWidth;
    
    return Positioned(
      left: left,
      top: 0,
      child: Container(
        width: widget.cellWidth,
        height: widget.headerHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            right: BorderSide(color: Colors.grey.shade300),
            bottom: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.showWeekNumbers)
              Text(
                'W${weekIndex + 1}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            Text(
              '${weekDate.month}/${weekDate.day}',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVirtualizedBody() {
    if (_activeMembers == null || _totalWeeks == null) {
      return const CTATimelineLoader();
    }
    
    final totalWidth = _totalWeeks! * widget.cellWidth;
    final totalHeight = _activeMembers!.length * widget.cellHeight;
    
    return Expanded(
      child: Row(
        children: [
          // Fixed team member names column
          if (widget.showTeamMemberNames)
            Container(
              width: widget.memberColumnWidth,
              child: SingleChildScrollView(
                child: Container(
                  height: totalHeight,
                  child: Stack(
                    children: [
                      // Render only visible member names
                      for (int memberIndex = _visibleStartMember; 
                           memberIndex < _visibleEndMember && memberIndex < _activeMembers!.length; 
                           memberIndex++)
                        _buildMemberNameCell(memberIndex),
                    ],
                  ),
                ),
              ),
            ),
          
          // Scrollable timeline grid
          Expanded(
            child: SingleChildScrollView(
              controller: _verticalController,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: totalWidth,
                  height: totalHeight,
                  child: Stack(
                    children: [
                      // Render background grid for visible area only
                      _buildVirtualizedGrid(),
                      
                      // Render allocations for visible members only
                      ..._buildVisibleAllocations(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberNameCell(int memberIndex) {
    final member = _activeMembers![memberIndex];
    final top = memberIndex * widget.cellHeight;
    
    return Positioned(
      left: 0,
      top: top,
      child: Container(
        width: widget.memberColumnWidth,
        height: widget.cellHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            right: BorderSide(color: Colors.grey.shade300),
            bottom: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              member.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              member.roles.map((r) => r.displayName).join(', '),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVirtualizedGrid() {
    final gridCells = <Widget>[];
    
    // Only render grid cells in visible area
    for (int memberIndex = _visibleStartMember; 
         memberIndex < _visibleEndMember && memberIndex < _activeMembers!.length; 
         memberIndex++) {
      
      for (int weekIndex = _visibleStartWeek; 
           weekIndex < _visibleEndWeek; 
           weekIndex++) {
        
        final left = weekIndex * widget.cellWidth;
        final top = memberIndex * widget.cellHeight;
        
        gridCells.add(
          Positioned(
            left: left,
            top: top,
            child: Container(
              width: widget.cellWidth,
              height: widget.cellHeight,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                ),
              ),
            ),
          ),
        );
      }
    }
    
    return Stack(children: gridCells);
  }

  List<Widget> _buildVisibleAllocations() {
    final allocationWidgets = <Widget>[];
    
    // Only process allocations for visible members
    for (int memberIndex = _visibleStartMember; 
         memberIndex < _visibleEndMember && memberIndex < _activeMembers!.length; 
         memberIndex++) {
      
      final member = _activeMembers![memberIndex];
      final allocations = _allocationsByMember![member.id] ?? [];
      
      for (final allocation in allocations) {
        final startWeek = _getWeekNumber(allocation.startDate);
        final endWeek = startWeek + allocation.durationInWeeks.round();
        
        // Only render if allocation is in visible week range (with some buffer)
        if (endWeek >= _visibleStartWeek - 2 && startWeek <= _visibleEndWeek + 2) {
          final widget = _buildAllocationWidget(allocation, member, memberIndex, startWeek);
          if (widget != null) {
            allocationWidgets.add(widget);
          }
        }
      }
    }
    
    return allocationWidgets;
  }

  Widget? _buildAllocationWidget(
    CapacityAllocation allocation, 
    TeamMember member, 
    int memberIndex, 
    int startWeek
  ) {
    final left = startWeek * widget.cellWidth;
    final top = memberIndex * widget.cellHeight + 2;
    final width = allocation.durationInWeeks * widget.cellWidth - 4;
    final height = widget.cellHeight - 4;
    
    // Find the related initiative
    final initiative = widget.quarterPlan.initiatives
        .where((init) => init.id == allocation.initiativeId)
        .firstOrNull;
    
    if (initiative == null) return null;
    
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _getRoleColor(allocation.role).withOpacity(0.8),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _getRoleColor(allocation.role),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                initiative.name,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${allocation.allocatedWeeks.toStringAsFixed(1)}w',
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(Role role) {
    switch (role) {
      case Role.backend:
        return Colors.blue;
      case Role.frontend:
        return Colors.green;
      case Role.mobile:
        return Colors.purple;
      case Role.qa:
        return Colors.orange;
      case Role.design:
        return Colors.pink;
      case Role.devops:
        return Colors.teal;
    }
  }

  DateTime _getDateForWeek(int week) {
    final (startDate, _) = widget.quarterPlan.quarterDateRange;
    return startDate.add(Duration(days: week * 7));
  }

  int _getWeekNumber(DateTime date) {
    final (startDate, _) = widget.quarterPlan.quarterDateRange;
    return date.difference(startDate).inDays ~/ 7;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableVirtualization) {
      // Simple fallback when virtualization is disabled
      return _buildSimpleTimeline();
    }

    return Column(
      children: [
        _buildVirtualizedHeader(),
        _buildVirtualizedBody(),
      ],
    );
  }

  Widget _buildSimpleTimeline() {
    if (_activeMembers == null || _totalWeeks == null) {
      return const CTATimelineLoader();
    }

    return Column(
      children: [
        // Simple header
        Container(
          height: widget.headerHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: const Center(
            child: Text('Team Members', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        
        // Simple body
        Expanded(
          child: ListView.builder(
            itemCount: _activeMembers!.length,
            itemBuilder: (context, index) {
              final member = _activeMembers![index];
              return Container(
                height: widget.cellHeight,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: widget.memberColumnWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            member.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            member.roles.map((r) => r.displayName).join(', '),
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.grey.shade50,
                        child: const Center(
                          child: Text('Simple Timeline View', style: TextStyle(fontSize: 10)),
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
    );
  }
}

/// Performance monitoring widget for timeline rendering
class TimelinePerformanceMonitor extends StatefulWidget {
  const TimelinePerformanceMonitor({
    super.key,
    required this.child,
    this.showMetrics = false,
  });

  final Widget child;
  final bool showMetrics;

  @override
  State<TimelinePerformanceMonitor> createState() => _TimelinePerformanceMonitorState();
}

class _TimelinePerformanceMonitorState extends State<TimelinePerformanceMonitor> {
  int _frameCount = 0;
  double _averageFrameTime = 0.0;
  DateTime? _lastFrameTime;

  @override
  void initState() {
    super.initState();
    
    if (widget.showMetrics) {
      WidgetsBinding.instance.addPostFrameCallback(_onFrame);
    }
  }

  void _onFrame(Duration timestamp) {
    if (!mounted) return;
    
    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!).inMicroseconds / 1000.0;
      _averageFrameTime = (_averageFrameTime * _frameCount + frameTime) / (_frameCount + 1);
      _frameCount++;
    }
    _lastFrameTime = now;
    
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showMetrics)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'FPS: ${_averageFrameTime > 0 ? (1000 / _averageFrameTime).toStringAsFixed(1) : "0"}\n'
                'Frame: ${_averageFrameTime.toStringAsFixed(1)}ms',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
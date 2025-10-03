import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kanban_provider.dart';
import '../models/models.dart';
import 'initiative_card_widget.dart';
import 'week_column_widget.dart';

/// Widget that displays the kanban board with drag-and-drop functionality
class KanbanBoardWidget extends StatefulWidget {
  const KanbanBoardWidget({super.key});

  @override
  State<KanbanBoardWidget> createState() => _KanbanBoardWidgetState();
}

class _KanbanBoardWidgetState extends State<KanbanBoardWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Kanban board with initiatives and timeline',
      child: Consumer<KanbanProvider>(
        builder: (context, kanbanProvider, child) {
          if (kanbanProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (kanbanProvider.hasError) {
            return _buildErrorWidget(kanbanProvider);
          }

          if (kanbanProvider.initiatives.isEmpty && kanbanProvider.timelineWeeks.isEmpty) {
            return _buildEmptyStateWidget();
          }

          return _buildKanbanBoardContent(kanbanProvider);
        },
      ),
    );
  }

  Widget _buildErrorWidget(KanbanProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage ?? 'An error occurred',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: provider.retry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No initiatives found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first initiative to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanBoardContent(KanbanProvider provider) {
    return Column(
      children: [
        // Timeline headers
        _buildTimelineHeaders(provider.timelineWeeks),
        
        // Main board content
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Backlog column (unscheduled initiatives)
                _buildBacklogColumn(provider),
                
                // Week columns
                ...provider.timelineWeeks.map((week) => 
                  _buildWeekColumn(provider, week)
                ).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineHeaders(List<DateTime> timelineWeeks) {
    return Container(
      height: 60,
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Backlog header
            Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              child: Text(
                'Backlog',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Week headers
            ...timelineWeeks.map((week) => Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                _formatWeekHeader(week),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBacklogColumn(KanbanProvider provider) {
    // Get unscheduled variants (variants without assignments or in backlog)
    final unscheduledVariants = provider.platformVariants
        .where((variant) => !variant.isAssigned && _isInBacklog(variant))
        .toList();

    return Container(
      width: 300,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Empty space for header alignment
          const SizedBox(height: 60),
          
          // Backlog content
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: unscheduledVariants.length,
              itemBuilder: (context, index) {
                final variant = unscheduledVariants[index];
                return _buildDraggableVariantCard(variant);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekColumn(KanbanProvider provider, DateTime week) {
    return WeekColumnWidget(
      week: week,
      variants: provider.getVariantsForWeek(week),
      capacityPeriod: provider.getCapacityForWeek(week),
      onVariantDropped: (variant, targetWeek) => 
        provider.moveVariantToWeek(variant.id, targetWeek),
    );
  }

  Widget _buildDraggableVariantCard(PlatformVariant variant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Draggable<PlatformVariant>(
        data: variant,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 280,
            child: InitiativeCardWidget(
              variant: variant,
              isDragFeedback: true,
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: InitiativeCardWidget(variant: variant),
        ),
        child: Semantics(
          label: 'Draggable initiative: ${variant.title}',
          child: InitiativeCardWidget(variant: variant),
        ),
      ),
    );
  }

  String _formatWeekHeader(DateTime week) {
    final month = _getMonthAbbreviation(week.month);
    return 'Week of $month ${week.day}';
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  bool _isInBacklog(PlatformVariant variant) {
    // Consider variant in backlog if it's not assigned and currentWeek is in the past
    // or if currentWeek is null/default
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return variant.currentWeek.isBefore(weekStart);
  }
}
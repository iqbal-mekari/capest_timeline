/// Loading and empty state components for consistent user feedback.
/// 
/// Provides loading indicators, empty state messages, and error states
/// that maintain visual consistency across the application.
library;

import 'package:flutter/material.dart';

/// Loading indicator with optional message
class CTALoadingIndicator extends StatelessWidget {
  const CTALoadingIndicator({
    super.key,
    this.message,
    this.size = 24.0,
  });

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full page loading state
class CTAPageLoading extends StatelessWidget {
  const CTAPageLoading({
    super.key,
    this.message = 'Loading...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CTALoadingIndicator(
        message: message,
        size: 32,
      ),
    );
  }
}

/// Empty state component with illustration and action
class CTAEmptyState extends StatelessWidget {
  const CTAEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.illustration,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null)
              illustration!
            else
              Icon(
                icon,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            const SizedBox(height: 24),
            
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state component with retry action
class CTAErrorState extends StatelessWidget {
  const CTAErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading for list items
class CTASkeletonLoader extends StatelessWidget {
  const CTASkeletonLoader({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 80.0,
  });

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => _SkeletonItem(height: itemHeight),
    );
  }
}

/// Individual skeleton item
class _SkeletonItem extends StatefulWidget {
  const _SkeletonItem({required this.height});

  final double height;

  @override
  State<_SkeletonItem> createState() => _SkeletonItemState();
}

class _SkeletonItemState extends State<_SkeletonItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(_animation.value),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 16,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withOpacity(_animation.value),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 200,
                              height: 12,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withOpacity(_animation.value * 0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(_animation.value * 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Timeline loading skeleton specifically for capacity planning
class CTATimelineLoader extends StatelessWidget {
  const CTATimelineLoader({
    super.key,
    this.weekCount = 13,
    this.memberCount = 5,
  });

  final int weekCount;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline header skeleton
          CTAShimmer(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Timeline rows skeleton
          for (int i = 0; i < memberCount; i++) ...[
            CTAShimmer(
              child: Row(
                children: [
                  // Member info
                  Container(
                    width: 200,
                    height: 60,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  
                  // Timeline weeks
                  Expanded(
                    child: Row(
                      children: [
                        for (int j = 0; j < weekCount; j++)
                          Expanded(
                            child: Container(
                              height: 60,
                              margin: const EdgeInsets.only(right: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Inline loading indicator for buttons and small components
class CTAInlineLoader extends StatelessWidget {
  const CTAInlineLoader({
    super.key,
    this.size = 16.0,
    this.color,
    this.message,
  });

  final double size;
  final Color? color;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: size / 8,
            color: color ?? theme.colorScheme.primary,
          ),
        ),
        if (message != null) ...[
          const SizedBox(width: 8),
          Text(
            message!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color ?? theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }
}

/// Loading overlay for dialogs and modals
class CTALoadingOverlay extends StatelessWidget {
  const CTALoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message = 'Loading...',
    this.backgroundColor,
  });

  final bool isLoading;
  final Widget child;
  final String message;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? theme.colorScheme.surface.withOpacity(0.8),
            child: CTALoadingIndicator(
              message: message,
              size: 32,
            ),
          ),
      ],
    );
  }
}

/// Card loading skeleton with customizable content
class CTACardLoader extends StatelessWidget {
  const CTACardLoader({
    super.key,
    this.width,
    this.height = 120.0,
    this.hasAvatar = true,
    this.hasTitle = true,
    this.hasSubtitle = true,
    this.hasActions = false,
  });

  final double? width;
  final double height;
  final bool hasAvatar;
  final bool hasTitle;
  final bool hasSubtitle;
  final bool hasActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(16),
        child: CTAShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (hasAvatar)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (hasAvatar) const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasTitle)
                          Container(
                            width: double.infinity,
                            height: 16,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        if (hasTitle && hasSubtitle) const SizedBox(height: 8),
                        if (hasSubtitle)
                          Container(
                            width: 150,
                            height: 12,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              if (hasActions)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 80,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple shimmer effect for loading states
class CTAShimmer extends StatefulWidget {
  const CTAShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<CTAShimmer> createState() => _CTAShimmerState();
}

class _CTAShimmerState extends State<CTAShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CTAShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.transparent,
                Colors.white54,
                Colors.transparent,
              ],
              stops: [
                0.0,
                _controller.value,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
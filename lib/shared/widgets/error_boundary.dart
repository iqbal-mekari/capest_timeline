import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Global error boundary widget that catches and displays errors gracefully
/// 
/// This widget wraps the entire application or specific sections to catch
/// unhandled exceptions and provide a user-friendly error display instead
/// of crashing the app.
/// 
/// Features:
/// - Catches Flutter framework errors and widget build errors
/// - Displays user-friendly error messages
/// - Provides retry functionality
/// - Logs errors for debugging (in debug mode)
/// - Maintains app stability by preventing crashes
/// - Customizable error UI
/// 
/// Usage:
/// ```dart
/// ErrorBoundary(
///   child: YourAppContent(),
///   onError: (error, stackTrace) {
///     // Optional custom error handling
///   },
/// )
/// ```
class ErrorBoundary extends StatefulWidget {
  /// The child widget to wrap with error boundary protection
  final Widget child;
  
  /// Optional callback when an error occurs
  final void Function(Object error, StackTrace? stackTrace)? onError;
  
  /// Custom error widget builder (optional)
  final Widget Function(Object error, StackTrace? stackTrace, VoidCallback retry)? errorBuilder;
  
  /// Whether to show detailed error information (useful in debug mode)
  final bool showDetails;
  
  /// Title for the error display
  final String errorTitle;
  
  /// Message to show when an error occurs
  final String errorMessage;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
    this.errorBuilder,
    this.showDetails = kDebugMode,
    this.errorTitle = 'Something went wrong',
    this.errorMessage = 'An unexpected error occurred. Please try again.',
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    
    // Set up global error handling for Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        _handleError(details.exception, details.stack);
      }
      
      // Still report to Flutter's error handling system
      FlutterError.presentError(details);
    };
  }

  void _handleError(Object error, StackTrace? stackTrace) {
    if (kDebugMode) {
      debugPrint('ErrorBoundary caught error: $error');
      debugPrint('StackTrace: $stackTrace');
    }
    
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
      _hasError = true;
    });
    
    // Call custom error handler if provided
    widget.onError?.call(error, stackTrace);
  }

  void _retry() {
    setState(() {
      _error = null;
      _stackTrace = null;
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace, _retry);
      }
      
      return _buildDefaultErrorWidget(context);
    }

    // Wrap child in an error-catching widget
    return _ErrorCatcher(
      onError: _handleError,
      child: widget.child,
    );
  }

  Widget _buildDefaultErrorWidget(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              
              const SizedBox(height: 24),
              
              // Error title
              Text(
                widget.errorTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Error message
              Text(
                widget.errorMessage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              
              if (widget.showDetails && _error != null) ...[
                const SizedBox(height: 24),
                
                // Error details (expandable)
                _ErrorDetailsCard(
                  error: _error!,
                  stackTrace: _stackTrace,
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Retry button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget that catches build errors in its child
class _ErrorCatcher extends StatefulWidget {
  final Widget child;
  final void Function(Object error, StackTrace? stackTrace) onError;

  const _ErrorCatcher({
    required this.child,
    required this.onError,
  });

  @override
  State<_ErrorCatcher> createState() => _ErrorCatcherState();
}

class _ErrorCatcherState extends State<_ErrorCatcher> {
  @override
  Widget build(BuildContext context) {
    // Override error widget builder during this widget's lifetime
    final oldBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onError(details.exception, details.stack);
      });
      return const SizedBox.shrink();
    };
    
    // Restore original builder when widget is disposed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ErrorWidget.builder = oldBuilder;
    });
    
    return widget.child;
  }
}

/// Expandable card showing error details for debugging
class _ErrorDetailsCard extends StatefulWidget {
  final Object error;
  final StackTrace? stackTrace;

  const _ErrorDetailsCard({
    required this.error,
    required this.stackTrace,
  });

  @override
  State<_ErrorDetailsCard> createState() => _ErrorDetailsCardState();
}

class _ErrorDetailsCardState extends State<_ErrorDetailsCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      color: colorScheme.errorContainer.withOpacity(0.1),
      child: ExpansionTile(
        title: Text(
          'Error Details',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.error,
          ),
        ),
        leading: Icon(
          Icons.bug_report,
          color: colorScheme.error,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error message
                Text(
                  'Error:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: SelectableText(
                    widget.error.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                
                if (widget.stackTrace != null) ...[
                  const SizedBox(height: 16),
                  
                  // Stack trace
                  Text(
                    'Stack Trace:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        widget.stackTrace.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Copy error button
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _copyErrorToClipboard(context),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Error'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyErrorToClipboard(BuildContext context) {
    // TODO: Implement clipboard functionality with proper package
    // final errorText = '''
    // Error: ${widget.error}
    // 
    // Stack Trace:
    // ${widget.stackTrace ?? 'No stack trace available'}
    // ''';
    // await Clipboard.setData(ClipboardData(text: errorText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error details would be copied to clipboard'),
      ),
    );
  }
}

/// Extension methods for easier error boundary usage
extension ErrorBoundaryExtension on Widget {
  /// Wrap this widget with an error boundary
  Widget withErrorBoundary({
    void Function(Object error, StackTrace? stackTrace)? onError,
    Widget Function(Object error, StackTrace? stackTrace, VoidCallback retry)? errorBuilder,
    bool showDetails = kDebugMode,
    String errorTitle = 'Something went wrong',
    String errorMessage = 'An unexpected error occurred. Please try again.',
  }) {
    return ErrorBoundary(
      onError: onError,
      errorBuilder: errorBuilder,
      showDetails: showDetails,
      errorTitle: errorTitle,
      errorMessage: errorMessage,
      child: this,
    );
  }
}
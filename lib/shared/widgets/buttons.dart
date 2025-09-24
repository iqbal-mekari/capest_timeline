/// Common button components with consistent styling for the Capacity Timeline app.
/// 
/// Provides primary, secondary, and tertiary button styles that follow
/// the application's Material Design 3 theme and branding.
library;

import 'package:flutter/material.dart';

/// Primary action button with elevated styling
class CTAPrimaryButton extends StatelessWidget {
  const CTAPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: (isEnabled && !isLoading) ? onPressed : null,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : child,
      ),
    );
  }
}

/// Secondary action button with outlined styling
class CTASecondaryButton extends StatelessWidget {
  const CTASecondaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? 48,
      child: OutlinedButton(
        onPressed: (isEnabled && !isLoading) ? onPressed : null,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : child,
      ),
    );
  }
}

/// Tertiary action button with text styling (minimal visual weight)
class CTATertiaryButton extends StatelessWidget {
  const CTATertiaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? 48,
      child: TextButton(
        onPressed: (isEnabled && !isLoading) ? onPressed : null,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : child,
      ),
    );
  }
}

/// Floating action button with consistent styling
class CTAFloatingActionButton extends StatelessWidget {
  const CTAFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.isLoading = false,
    this.isEnabled = true,
    this.heroTag,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final bool isLoading;
  final bool isEnabled;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: (isEnabled && !isLoading) ? onPressed : null,
      tooltip: tooltip,
      heroTag: heroTag,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : child,
    );
  }
}

/// Icon button with consistent styling and hover effects
class CTAIconButton extends StatelessWidget {
  const CTAIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.isEnabled = true,
    this.size = 24,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final bool isEnabled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isEnabled ? onPressed : null,
      icon: Icon(icon, size: size),
      tooltip: tooltip,
    );
  }
}

/// Button group for related actions
class CTAButtonGroup extends StatelessWidget {
  const CTAButtonGroup({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.direction = Axis.horizontal,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final List<Widget> children;
  final double spacing;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children
          .expand((child) => [
                child,
                SizedBox(
                  width: direction == Axis.horizontal ? spacing : 0,
                  height: direction == Axis.vertical ? spacing : 0,
                ),
              ])
          .take(children.length * 2 - 1)
          .toList(),
    );
  }
}
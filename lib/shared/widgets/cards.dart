/// Common card components for displaying information with consistent styling.
/// 
/// Provides different card types for various content like team members,
/// initiatives, progress indicators, and general information display.
library;

import 'package:flutter/material.dart';

/// Base card component with consistent styling
class CTACard extends StatelessWidget {
  const CTACard({
    required this.child,
    super.key,
    this.padding,
    this.margin,
    this.elevation,
    this.color,
    this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      child: Card(
        elevation: elevation ?? 2,
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Card specifically designed for displaying team member information
class CTATeamMemberCard extends StatelessWidget {
  const CTATeamMemberCard({
    required this.name,
    required this.email,
    required this.roles,
    super.key,
    this.avatarUrl,
    this.isActive = true,
    this.weeklyCapacity,
    this.onTap,
    this.onEdit,
    this.margin,
  });

  final String name;
  final String email;
  final List<String> roles;
  final String? avatarUrl;
  final bool isActive;
  final double? weeklyCapacity;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CTACard(
      margin: margin,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Inactive',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  iconSize: 20,
                  tooltip: 'Edit team member',
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Roles
          if (roles.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: roles.map((role) => CTARoleChip(role: role)).toList(),
            ),
            const SizedBox(height: 8),
          ],
          
          // Capacity
          if (weeklyCapacity != null)
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '${(weeklyCapacity! * 100).toInt()}% capacity',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Card for displaying initiative information
class CTAInitiativeCard extends StatelessWidget {
  const CTAInitiativeCard({
    required this.title,
    required this.description,
    super.key,
    this.priority,
    this.businessValue,
    this.estimatedWeeks,
    this.allocatedWeeks,
    this.status,
    this.onTap,
    this.onEdit,
    this.margin,
  });

  final String title;
  final String description;
  final int? priority;
  final int? businessValue;
  final double? estimatedWeeks;
  final double? allocatedWeeks;
  final String? status;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CTACard(
      margin: margin,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  iconSize: 20,
                  tooltip: 'Edit initiative',
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          Text(
            description,
            style: theme.textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          // Metrics row
          Row(
            children: [
              if (priority != null) ...[
                CTAMetricChip(
                  label: 'P$priority',
                  color: _getPriorityColor(priority!, theme),
                ),
                const SizedBox(width: 8),
              ],
              if (businessValue != null) ...[
                CTAMetricChip(
                  label: 'BV: $businessValue',
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
              ],
              if (estimatedWeeks != null) ...[
                CTAMetricChip(
                  label: '${estimatedWeeks!.toStringAsFixed(1)}w est.',
                  color: theme.colorScheme.tertiary,
                ),
              ],
            ],
          ),
          
          // Progress bar if allocated
          if (allocatedWeeks != null && estimatedWeeks != null) ...[
            const SizedBox(height: 8),
            CTAProgressBar(
              progress: allocatedWeeks! / estimatedWeeks!,
              label: '${allocatedWeeks!.toStringAsFixed(1)}w allocated',
            ),
          ],
        ],
      ),
    );
  }

  Color _getPriorityColor(int priority, ThemeData theme) {
    if (priority <= 3) return theme.colorScheme.error;
    if (priority <= 6) return Colors.orange;
    return theme.colorScheme.primary;
  }
}

/// Simple information card for displaying key-value data
class CTAInfoCard extends StatelessWidget {
  const CTAInfoCard({
    required this.title,
    required this.value,
    super.key,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
    this.margin,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CTACard(
      margin: margin,
      onTap: onTap,
      color: color?.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: color ?? theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color ?? theme.colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip component for displaying roles
class CTARoleChip extends StatelessWidget {
  const CTARoleChip({
    required this.role,
    super.key,
    this.onDeleted,
  });

  final String role;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Chip(
      label: Text(
        role,
        style: theme.textTheme.labelSmall,
      ),
      backgroundColor: _getRoleColor(role).withOpacity(0.1),
      labelStyle: TextStyle(
        color: _getRoleColor(role),
        fontWeight: FontWeight.w500,
      ),
      onDeleted: onDeleted,
      deleteIconColor: _getRoleColor(role),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'backend':
        return const Color(0xFF3F51B5);
      case 'frontend':
        return const Color(0xFF009688);
      case 'mobile':
        return const Color(0xFF9C27B0);
      case 'qa':
        return const Color(0xFFFF9800);
      case 'devops':
        return const Color(0xFF795548);
      case 'design':
        return const Color(0xFFE91E63);
      default:
        return const Color(0xFF1976D2);
    }
  }
}

/// Chip for displaying metrics with color coding
class CTAMetricChip extends StatelessWidget {
  const CTAMetricChip({
    required this.label,
    required this.color,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Progress bar component
class CTAProgressBar extends StatelessWidget {
  const CTAProgressBar({
    super.key,
    required this.progress,
    this.label,
    this.height = 6.0,
    this.backgroundColor,
    this.foregroundColor,
  });

  final double progress;
  final String? label;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
        ],
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: backgroundColor ?? theme.colorScheme.outline.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            foregroundColor ?? _getProgressColor(progress, theme),
          ),
          minHeight: height,
        ),
      ],
    );
  }

  Color _getProgressColor(double progress, ThemeData theme) {
    if (progress >= 1.0) return theme.colorScheme.error;
    if (progress >= 0.8) return Colors.orange;
    return theme.colorScheme.primary;
  }
}
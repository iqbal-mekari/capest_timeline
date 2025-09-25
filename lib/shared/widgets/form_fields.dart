/// Form input components with validation and consistent styling.
/// 
/// Provides text fields, dropdowns, date pickers, and other form controls
/// that follow the application's design system and validation patterns.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Text field with consistent styling and validation support
class CTATextField extends StatelessWidget {
  const CTATextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        enabled: enabled,
      ),
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
    );
  }
}

/// Dropdown field with consistent styling
class CTADropdownField<T> extends StatelessWidget {
  const CTADropdownField({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.enabled = true,
    this.validator,
  });

  final List<CTADropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final bool enabled;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item.value,
                child: item.child,
              ))
          .toList(),
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        enabled: enabled,
      ),
      validator: validator,
      isExpanded: true,
    );
  }
}

/// Dropdown item model
class CTADropdownItem<T> {
  const CTADropdownItem({
    required this.value,
    required this.child,
  });

  final T value;
  final Widget child;
}

/// Date picker field
class CTADateField extends StatelessWidget {
  const CTADateField({
    super.key,
    required this.onChanged,
    this.value,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
    this.validator,
  });

  final ValueChanged<DateTime?> onChanged;
  final DateTime? value;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final bool enabled;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? Function(DateTime?)? validator;

  @override
  Widget build(BuildContext context) {
    return CTATextField(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon ?? const Icon(Icons.calendar_today),
      enabled: enabled,
      readOnly: true,
      controller: TextEditingController(
        text: value != null 
            ? '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}'
            : '',
      ),
      onTap: enabled ? () => _selectDate(context) : null,
      validator: validator != null ? (text) => validator!(value) : null,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2030),
    );
    
    if (picked != null) {
      onChanged(picked);
    }
  }
}

/// Number input field with increment/decrement buttons
class CTANumberField extends StatelessWidget {
  const CTANumberField({
    super.key,
    required this.onChanged,
    this.value,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.enabled = true,
    this.min,
    this.max,
    this.step = 1,
    this.decimals = 0,
    this.validator,
  });

  final ValueChanged<double?> onChanged;
  final double? value;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final bool enabled;
  final double? min;
  final double? max;
  final double step;
  final int decimals;
  final String? Function(double?)? validator;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CTATextField(
            labelText: labelText,
            hintText: hintText,
            helperText: helperText,
            errorText: errorText,
            prefixIcon: prefixIcon,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            controller: TextEditingController(
              text: value != null ? value!.toStringAsFixed(decimals) : '',
            ),
            onChanged: (text) {
              final parsed = double.tryParse(text);
              onChanged(parsed);
            },
            validator: validator != null ? (text) {
              final parsed = double.tryParse(text ?? '');
              return validator!(parsed);
            } : null,
          ),
        ),
        if (enabled) ...[
          const SizedBox(width: 8),
          Column(
            children: [
              SizedBox(
                width: 32,
                height: 24,
                child: IconButton(
                  onPressed: () => _increment(),
                  icon: const Icon(Icons.keyboard_arrow_up, size: 16),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 32,
                height: 24,
                child: IconButton(
                  onPressed: () => _decrement(),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _increment() {
    double newValue = (value ?? 0) + step;
    if (max != null && newValue > max!) newValue = max!;
    onChanged(newValue);
  }

  void _decrement() {
    double newValue = (value ?? 0) - step;
    if (min != null && newValue < min!) newValue = min!;
    onChanged(newValue);
  }
}

/// Multi-select chip field
class CTAChipField extends StatelessWidget {
  const CTAChipField({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.labelText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.validator,
  });

  final List<String> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;
  final String? labelText;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final String? Function(List<String>?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FormField<List<String>>(
      initialValue: selectedValues,
      validator: validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (labelText != null) ...[
              Text(
                labelText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: options.map((option) {
                final isSelected = selectedValues.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: enabled ? (selected) {
                    List<String> newValues = List.from(selectedValues);
                    if (selected) {
                      newValues.add(option);
                    } else {
                      newValues.remove(option);
                    }
                    onChanged(newValues);
                    field.didChange(newValues);
                  } : null,
                );
              }).toList(),
            ),
            
            if (helperText != null || field.hasError) ...[
              const SizedBox(height: 8),
              Text(
                field.errorText ?? helperText ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: field.hasError 
                      ? theme.colorScheme.error 
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Form section divider with optional title
class CTAFormSection extends StatelessWidget {
  const CTAFormSection({
    super.key,
    this.title,
    required this.children,
    this.padding,
  });

  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
          ],
          ...children,
        ],
      ),
    );
  }
}
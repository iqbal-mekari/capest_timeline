import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/initiative.dart';
import '../models/platform_type.dart';
import '../models/platform_variant.dart';
import '../providers/kanban_provider.dart';

/// Widget for creating new initiatives with platform variants
class CreateInitiativeWidget extends StatefulWidget {
  const CreateInitiativeWidget({Key? key}) : super(key: key);

  @override
  State<CreateInitiativeWidget> createState() => _CreateInitiativeWidgetState();
}

class _CreateInitiativeWidgetState extends State<CreateInitiativeWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final Map<PlatformType, bool> _selectedPlatforms = {
    PlatformType.backend: false,
    PlatformType.frontend: false,
    PlatformType.mobile: false,
    PlatformType.qa: false,
  };
  
  final Map<PlatformType, TextEditingController> _weeksControllers = {};
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for weeks input
    for (final platform in PlatformType.values) {
      _weeksControllers[platform] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final controller in _weeksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an initiative title';
    }
    if (value.length > 100) {
      return 'Title must be less than 100 characters';
    }
    return null;
  }

  String? _validateWeeks(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter estimated weeks';
    }
    final weeks = int.tryParse(value);
    if (weeks == null || weeks <= 0) {
      return 'Must be a positive number';
    }
    return null;
  }

  String _getPlatformDisplayName(PlatformType platform) {
    switch (platform) {
      case PlatformType.backend:
        return 'Backend';
      case PlatformType.frontend:
        return 'Frontend';
      case PlatformType.mobile:
        return 'Mobile';
      case PlatformType.qa:
        return 'QA';
    }
  }

  String _getPlatformPrefix(PlatformType platform) {
    switch (platform) {
      case PlatformType.backend:
        return '[BE]';
      case PlatformType.frontend:
        return '[FE]';
      case PlatformType.mobile:
        return '[MOB]';
      case PlatformType.qa:
        return '[QA]';
    }
  }

  List<PlatformType> get _selectedPlatformTypes {
    return _selectedPlatforms.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  int get _totalEstimatedWeeks {
    int total = 0;
    for (final platform in _selectedPlatformTypes) {
      final weeks = int.tryParse(_weeksControllers[platform]?.text ?? '0') ?? 0;
      total += weeks;
    }
    return total;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate that at least one platform is selected
    if (_selectedPlatformTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one platform variant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final now = DateTime.now();
      final platformVariants = <PlatformVariant>[];
      
      // Create platform variants for selected platforms
      for (final platform in _selectedPlatformTypes) {
        final weeks = int.tryParse(_weeksControllers[platform]?.text ?? '0') ?? 0;
        platformVariants.add(
          PlatformVariant(
            id: 'variant-${platform.name}-${DateTime.now().millisecondsSinceEpoch}',
            initiativeId: 'temp-id', // Will be set when initiative is created
            platformType: platform,
            title: '${_getPlatformPrefix(platform)} ${_titleController.text.trim()}',
            estimatedWeeks: weeks,
            currentWeek: now,
            isAssigned: false,
          ),
        );
      }

      final initiative = Initiative(
        id: 'init-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        createdAt: now,
        platformVariants: platformVariants,
        requiredPlatforms: _selectedPlatformTypes,
      );

      final provider = Provider.of<KanbanProvider>(context, listen: false);
      final success = await provider.createInitiative(initiative);

      if (success) {
        _resetForm();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Initiative created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error creating initiative. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error creating initiative. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    
    setState(() {
      for (final platform in PlatformType.values) {
        _selectedPlatforms[platform] = false;
        _weeksControllers[platform]?.clear();
      }
    });
  }

  Widget _buildPlatformVariantSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Platform Variants',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add platform-specific work breakdown:',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        
        // Platform checkboxes
        ...PlatformType.values.map((platform) => CheckboxListTile(
          title: Text(_getPlatformDisplayName(platform)),
          value: _selectedPlatforms[platform],
          onChanged: (bool? value) {
            setState(() {
              _selectedPlatforms[platform] = value ?? false;
              if (!_selectedPlatforms[platform]!) {
                _weeksControllers[platform]?.clear();
              }
            });
          },
        )),
        
        const SizedBox(height: 16),
        
        // Weeks inputs for selected platforms
        ..._selectedPlatformTypes.map((platform) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: _weeksControllers[platform],
            decoration: InputDecoration(
              labelText: '${_getPlatformDisplayName(platform)} Estimated Weeks',
              border: const OutlineInputBorder(),
              suffixIcon: Tooltip(
                message: 'Enter the estimated number of weeks for ${_getPlatformDisplayName(platform)} work',
                child: const Icon(Icons.help_outline),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _validateWeeks,

          ),
        )),
        
        // Preview section
        if (_selectedPlatformTypes.isNotEmpty) ...[
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Preview: ${_selectedPlatformTypes.length} platform variants will be created',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._selectedPlatformTypes.map((platform) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              '${_getPlatformPrefix(platform)} ${_titleController.text.trim().isEmpty ? 'Initiative Title' : _titleController.text.trim()}',
              style: TextStyle(
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          )),
          const SizedBox(height: 8),
          if (_totalEstimatedWeeks > 0)
            Text(
              'Total estimated time: $_totalEstimatedWeeks weeks',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return Semantics(
      label: 'Create new initiative form',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title input
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Initiative Title',
                  border: OutlineInputBorder(),
                  suffixIcon: Tooltip(
                    message: 'Enter a clear, descriptive title for the initiative',
                    child: Icon(Icons.help_outline),
                  ),
                ),
                validator: _validateTitle,

                onChanged: (value) => setState(() {}), // Refresh preview
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
              ),
              const SizedBox(height: 16),
              
              // Description input
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,

              ),
              const SizedBox(height: 24),
              
              // Platform variants section
              _buildPlatformVariantSection(),
              const SizedBox(height: 32),
              
              // Submit button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Creating...'),
                          ],
                        )
                      : const Text(
                          'Create Initiative',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              
              // Error announcement for screen readers
              if (_formKey.currentState?.validate() == false)
                Semantics(
                  label: 'Form validation errors present',
                  child: SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
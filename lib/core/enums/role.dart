/// Development role specialization categories for capacity planning.
/// 
/// Defines the different types of development skills and specializations
/// that team members can possess and that initiatives can require.
enum Role {
  /// Server-side development and APIs
  backend('Backend', 'Server-side development, databases, and APIs'),

  /// User interface and client-side logic
  frontend('Frontend', 'User interface development and client-side logic'),

  /// iOS and Android application development
  mobile('Mobile', 'iOS and Android application development'),

  /// Quality assurance and testing
  qa('QA', 'Quality assurance, testing, and automation'),

  /// Infrastructure and deployment automation
  devops('DevOps', 'Infrastructure, CI/CD, and deployment automation'),

  /// User experience and visual design
  design('Design', 'User experience design and visual interface design');

  /// Creates a role with display name and description
  const Role(this.displayName, this.description);

  /// Human-readable name for UI display
  final String displayName;

  /// Detailed description of the role responsibilities
  final String description;

  /// Get role from string value (case-insensitive)
  static Role? fromString(String value) {
    final lowerValue = value.toLowerCase().trim();
    for (final role in Role.values) {
      if (role.name.toLowerCase() == lowerValue ||
          role.displayName.toLowerCase() == lowerValue) {
        return role;
      }
    }
    return null;
  }

  /// Get all role names as a list
  static List<String> get names => Role.values.map((role) => role.name).toList();

  /// Get all display names as a list
  static List<String> get displayNames => 
      Role.values.map((role) => role.displayName).toList();

  /// Check if this role is technical (excludes design)
  bool get isTechnical => this != Role.design;

  /// Check if this role involves coding
  bool get involvesCoding => 
      this == Role.backend || 
      this == Role.frontend || 
      this == Role.mobile ||
      this == Role.devops;

  /// Check if this role is client-facing
  bool get isClientFacing => 
      this == Role.frontend || 
      this == Role.mobile ||
      this == Role.design;

  /// Get recommended team size range for this role in a typical quarter
  /// Returns (min, max) team members
  (int, int) get recommendedTeamSize {
    switch (this) {
      case Role.backend:
        return (2, 6); // Core infrastructure needs
      case Role.frontend:
        return (2, 4); // UI and client logic
      case Role.mobile:
        return (1, 3); // Platform-specific development
      case Role.qa:
        return (1, 2); // Quality assurance coverage
      case Role.devops:
        return (1, 2); // Infrastructure and deployment
      case Role.design:
        return (1, 2); // UX and visual design
    }
  }

  /// Get typical capacity allocation percentage for this role in projects
  double get typicalProjectAllocation {
    switch (this) {
      case Role.backend:
        return 0.35; // 35% - Core business logic
      case Role.frontend:
        return 0.30; // 30% - User interface
      case Role.mobile:
        return 0.20; // 20% - Mobile platforms
      case Role.qa:
        return 0.10; // 10% - Testing and validation
      case Role.devops:
        return 0.03; // 3% - Infrastructure setup
      case Role.design:
        return 0.02; // 2% - UX and visual design
    }
  }
}
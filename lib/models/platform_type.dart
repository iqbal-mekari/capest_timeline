/// Enumeration of platform types for initiative variants
enum PlatformType {
  backend,
  frontend,
  mobile,
  qa;

  /// Get the display name for the platform type
  String get displayName {
    switch (this) {
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

  /// Get the platform prefix for initiative titles
  String get prefix {
    switch (this) {
      case PlatformType.backend:
        return 'BE';
      case PlatformType.frontend:
        return 'FE';
      case PlatformType.mobile:
        return 'MOBILE';
      case PlatformType.qa:
        return 'QA';
    }
  }

  /// Create PlatformType from string
  static PlatformType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'backend':
      case 'be':
        return PlatformType.backend;
      case 'frontend':
      case 'fe':
        return PlatformType.frontend;
      case 'mobile':
        return PlatformType.mobile;
      case 'qa':
        return PlatformType.qa;
      default:
        throw ArgumentError('Invalid platform type: $value');
    }
  }

  /// Convert to JSON string
  String toJson() => name;

  /// Create from JSON string
  static PlatformType fromJson(String json) => PlatformType.values.byName(json);
}
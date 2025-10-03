import 'package:flutter_test/flutter_test.dart';
import 'package:capest_timeline/models/team_member.dart';

void main() {
  group('TeamMember Model Tests', () {
    test('should create TeamMember with valid data', () {
      // Arrange
      const member = TeamMember(
        id: 'member-1',
        name: 'John Doe',
        weeklyCapacity: 40.0,
        platformSpecializations: ['backend', 'qa'],
        isActive: true,
      );

      // Assert
      expect(member.id, equals('member-1'));
      expect(member.name, equals('John Doe'));
      expect(member.platformSpecializations, contains('backend'));
      expect(member.platformSpecializations, contains('qa'));
      expect(member.weeklyCapacity, equals(40.0));
      expect(member.isActive, equals(true));
      expect(member.isAvailable, equals(true));
    });

    test('should create TeamMember with optional fields', () {
      // Arrange
      const member = TeamMember(
        id: 'member-1',
        name: 'John Doe',
        weeklyCapacity: 40.0,
        email: 'john@example.com',
        role: 'Senior Developer',
        skills: ['Dart', 'Flutter', 'JavaScript'],
        platformSpecializations: ['frontend', 'mobile'],
      );

      // Assert
      expect(member.email, equals('john@example.com'));
      expect(member.role, equals('Senior Developer'));
      expect(member.skills, contains('Dart'));
      expect(member.skills.length, equals(3));
      expect(member.platformSpecializations.length, equals(2));
    });

    test('should create part-time TeamMember', () {
      // Arrange
      const member = TeamMember(
        id: 'member-1',
        name: 'Jane Smith',
        weeklyCapacity: 20.0, // Part-time
        platformSpecializations: ['mobile'],
        isActive: true,
      );

      // Assert
      expect(member.weeklyCapacity, equals(20.0));
      expect(member.isAvailable, equals(true));
    });

    test('should validate properly when name is empty', () {
      // Arrange
      const member = TeamMember(
        id: 'member-1',
        name: '',
        weeklyCapacity: 40.0,
      );

      // Act & Assert
      expect(member.validate(), equals('Name cannot be empty'));
    });

    test('should validate properly when weekly capacity is negative', () {
      // Arrange
      const member = TeamMember(
        id: 'member-1',
        name: 'John Doe',
        weeklyCapacity: -5.0,
      );

      // Act & Assert
      expect(member.validate(), equals('Weekly capacity cannot be negative'));
    });

    test('should validate properly when weekly capacity exceeds maximum', () {
      // Arrange
      const member = TeamMember(
        id: 'member-1',
        name: 'John Doe',
        weeklyCapacity: 200.0, // More than 168 hours per week
      );

      // Act & Assert
      expect(member.validate(), equals('Weekly capacity cannot exceed 168 hours'));
    });

    test('should generate correct initials', () {
      // Arrange
      const member1 = TeamMember(
        id: 'member-1',
        name: 'John Doe',
        weeklyCapacity: 40.0,
      );
      
      const member2 = TeamMember(
        id: 'member-2',
        name: 'Mary Jane Watson',
        weeklyCapacity: 40.0,
      );
      
      const member3 = TeamMember(
        id: 'member-3',
        name: 'Bob',
        weeklyCapacity: 40.0,
      );

      // Assert
      expect(member1.initials, equals('JD'));
      expect(member2.initials, equals('MW'));
      expect(member3.initials, equals('B'));
    });

    test('should support equality comparison using Equatable', () {
      // Arrange
      const member1 = TeamMember(
        id: 'member-1',
        name: 'John Doe',
        weeklyCapacity: 40.0,
        platformSpecializations: ['backend'],
        isActive: true,
      );

      const member2 = TeamMember(
        id: 'member-1',
        name: 'John Doe',
        weeklyCapacity: 40.0,
        platformSpecializations: ['backend'],
        isActive: true,
      );

      const member3 = TeamMember(
        id: 'member-2',
        name: 'John Doe',
        weeklyCapacity: 40.0,
        platformSpecializations: ['backend'],
        isActive: true,
      );

      // Assert
      expect(member1, equals(member2));
      expect(member1, isNot(equals(member3)));
      expect(member1.hashCode, equals(member2.hashCode));
    });

    test('should check availability correctly', () {
      // Arrange
      const activeMember = TeamMember(
        id: 'member-1',
        name: 'John Doe',
        weeklyCapacity: 40.0,
        isActive: true,
      );
      
      const inactiveMember = TeamMember(
        id: 'member-2',
        name: 'Jane Doe',
        weeklyCapacity: 40.0,
        isActive: false,
      );
      
      const zeroCapacityMember = TeamMember(
        id: 'member-3',
        name: 'Bob Smith',
        weeklyCapacity: 0.0,
        isActive: true,
      );

      // Assert
      expect(activeMember.isAvailable, equals(true));
      expect(inactiveMember.isAvailable, equals(false));
      expect(zeroCapacityMember.isAvailable, equals(false));
    });

    test('should serialize to and from JSON', () {
      // Arrange
      const member = TeamMember(
        id: 'member-1',
        name: 'John Doe',
        weeklyCapacity: 32.0,
        email: 'john@example.com',
        role: 'Developer',
        skills: ['Dart', 'Flutter'],
        platformSpecializations: ['backend', 'qa'],
        isActive: true,
        skillLevel: 0.8,
      );

      // Act
      final json = member.toJson();
      final fromJson = TeamMember.fromJson(json);

      // Assert
      expect(fromJson, equals(member));
      expect(json['id'], equals('member-1'));
      expect(json['name'], equals('John Doe'));
      expect(json['weeklyCapacity'], equals(32.0));
      expect(json['email'], equals('john@example.com'));
      expect(json['role'], equals('Developer'));
      expect(json['skills'], equals(['Dart', 'Flutter']));
      expect(json['platformSpecializations'], equals(['backend', 'qa']));
      expect(json['isActive'], equals(true));
      expect(json['skillLevel'], equals(0.8));
    });

    test('should create copy with updated fields', () {
      // Arrange
      const original = TeamMember(
        id: 'member-1',
        name: 'John Doe',
        weeklyCapacity: 40.0,
        platformSpecializations: ['backend'],
        isActive: true,
      );

      // Act
      final updated = original.copyWith(
        name: 'John Smith',
        weeklyCapacity: 20.0,
        isActive: false,
      );

      // Assert
      expect(updated.id, equals(original.id));
      expect(updated.name, equals('John Smith'));
      expect(updated.weeklyCapacity, equals(20.0));
      expect(updated.isActive, equals(false));
      expect(updated.platformSpecializations, equals(original.platformSpecializations));
    });
  });
}
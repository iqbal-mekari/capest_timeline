import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capest_timeline/features/configuration/data/datasources/local_storage_datasource.dart';
import 'package:capest_timeline/services/storage/configuration_service.dart';
import 'package:capest_timeline/services/storage/application_state_service.dart';
import 'package:capest_timeline/services/storage/quarter_plan_storage_service.dart';
import 'package:capest_timeline/features/configuration/domain/entities/user_configuration.dart';
import 'package:capest_timeline/features/configuration/domain/entities/application_state.dart';
import 'package:capest_timeline/features/capacity_planning/domain/entities/quarter_plan.dart';
import 'package:capest_timeline/shared/themes/app_theme.dart';

void main() {
  group('Service Integration Tests', () {
    late SharedPreferences prefs;
    late LocalStorageDataSource dataSource;
    late ConfigurationService configService;
    late ApplicationStateService appStateService;
    late QuarterPlanStorageService quarterPlanService;

    setUp(() async {
      // Use in-memory shared preferences for testing
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      
      // Set up services
      dataSource = LocalStorageDataSource(preferences: prefs);
      configService = ConfigurationServiceImpl(storageDataSource: dataSource);
      appStateService = ApplicationStateServiceImpl(storageDataSource: dataSource);
      quarterPlanService = QuarterPlanStorageServiceImpl(dataSource: dataSource);
    });

    group('ConfigurationService Integration', () {
      test('should save and load configuration successfully', () async {
        // Arrange
        const config = UserConfiguration(
          theme: AppThemeMode.dark,
          autoSaveInterval: 60,
        );

        // Act
        final saveResult = await configService.saveConfiguration(config);
        final loadResult = await configService.loadConfiguration();

        // Assert
        expect(saveResult.isSuccess, true);
        expect(loadResult.isSuccess, true);
        expect(loadResult.value?.theme, AppThemeMode.dark);
        expect(loadResult.value?.autoSaveInterval, 60);
      });

      test('should reset to default configuration', () async {
        // Arrange - Save custom config first
        const customConfig = UserConfiguration(
          theme: AppThemeMode.dark,
          autoSaveInterval: 120,
        );
        await configService.saveConfiguration(customConfig);

        // Act
        final resetResult = await configService.resetConfiguration();
        final loadResult = await configService.loadConfiguration();

        // Assert
        expect(resetResult.isSuccess, true);
        expect(loadResult.isSuccess, true);
        expect(loadResult.value?.theme, AppThemeMode.system);
        expect(loadResult.value?.autoSaveInterval, 30);
      });
    });

    group('ApplicationStateService Integration', () {
      test('should save and restore application state', () async {
        // Arrange
        const state = ApplicationState(
          currentPlanId: 'Q1-2025',
          selectedQuarter: 1,
          selectedYear: 2025,
        );

        // Act
        final saveResult = await appStateService.saveState(state);
        final restoreResult = await appStateService.restoreState();

        // Assert
        expect(saveResult.isSuccess, true);
        expect(restoreResult.isSuccess, true);
        expect(restoreResult.value?.currentPlanId, 'Q1-2025');
        expect(restoreResult.value?.selectedQuarter, 1);
        expect(restoreResult.value?.selectedYear, 2025);
      });

      test('should reset application state', () async {
        // Arrange - Save custom state first
        const customState = ApplicationState(
          currentPlanId: 'Q4-2024',
          selectedQuarter: 4,
          selectedYear: 2024,
        );
        await appStateService.saveState(customState);

        // Act
        final resetResult = await appStateService.resetState();
        final restoreResult = await appStateService.restoreState();

        // Assert
        expect(resetResult.isSuccess, true);
        expect(restoreResult.isSuccess, true);
        expect(restoreResult.value?.currentPlanId, isNull);
        expect(restoreResult.value?.selectedQuarter, isNull);
        expect(restoreResult.value?.selectedYear, isNull);
        expect(restoreResult.value?.hasUnsavedChanges, false);
      });
    });

    group('QuarterPlanStorageService Integration', () {
      test('should save and load quarter plan', () async {
        // Arrange
        const plan = QuarterPlan(
          id: 'Q1-2025',
          quarter: 1,
          year: 2025,
          name: 'Q1 2025 Plan',
          initiatives: [],
          teamMembers: [],
          allocations: [],
        );

        // Act
        final saveResult = await quarterPlanService.saveQuarterPlan(plan);
        final loadResult = await quarterPlanService.loadQuarterPlan('Q1-2025');

        // Assert
        expect(saveResult.isSuccess, true);
        expect(loadResult.isSuccess, true);
        expect(loadResult.value?.id, 'Q1-2025');
        expect(loadResult.value?.name, 'Q1 2025 Plan');
        expect(loadResult.value?.quarter, 1);
        expect(loadResult.value?.year, 2025);
      });

      test('should list quarter plans', () async {
        // Arrange - Save multiple plans
        const plan1 = QuarterPlan(
          id: 'Q1-2025',
          quarter: 1,
          year: 2025,
          name: 'Q1 2025 Plan',
          initiatives: [],
          teamMembers: [],
          allocations: [],
        );
        const plan2 = QuarterPlan(
          id: 'Q2-2025',
          quarter: 2,
          year: 2025,
          name: 'Q2 2025 Plan',
          initiatives: [],
          teamMembers: [],
          allocations: [],
        );

        await quarterPlanService.saveQuarterPlan(plan1);
        await quarterPlanService.saveQuarterPlan(plan2);

        // Act
        final listResult = await quarterPlanService.listQuarterPlans();

        // Assert
        expect(listResult.isSuccess, true);
        expect(listResult.value?.length, 2);
        
        final planIds = listResult.value?.map((metadata) => metadata.id).toList();
        expect(planIds, contains('Q1-2025'));
        expect(planIds, contains('Q2-2025'));
      });

      test('should delete quarter plan', () async {
        // Arrange - Save plan first
        const plan = QuarterPlan(
          id: 'Q1-2025',
          quarter: 1,
          year: 2025,
          name: 'Q1 2025 Plan',
          initiatives: [],
          teamMembers: [],
          allocations: [],
        );
        await quarterPlanService.saveQuarterPlan(plan);

        // Act
        final deleteResult = await quarterPlanService.deleteQuarterPlan('Q1-2025');
        final loadResult = await quarterPlanService.loadQuarterPlan('Q1-2025');

        // Assert
        expect(deleteResult.isSuccess, true);
        expect(loadResult.isSuccess, true);
        expect(loadResult.value, isNull); // Plan should be deleted
      });
    });
  });
}
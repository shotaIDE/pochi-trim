import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pochi_trim/data/model/debounce_work_log_exception.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/model/user_profile.dart';
import 'package:pochi_trim/data/repository/dao/add_work_log_args.dart';
import 'package:pochi_trim/data/repository/house_repository.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/data/service/error_report_service.dart';
import 'package:pochi_trim/data/service/in_app_review_service.dart';
import 'package:pochi_trim/data/service/preference_service.dart';
import 'package:pochi_trim/data/service/system_service.dart';
import 'package:pochi_trim/data/service/work_log_service.dart';

class MockWorkLogRepository extends Mock implements WorkLogRepository {}

class MockAuthService extends Mock implements AuthService {}

class MockSystemService extends Mock implements SystemService {}

class MockErrorReportService extends Mock implements ErrorReportService {}

class MockInAppReviewService extends Mock implements InAppReviewService {}

class MockPreferenceService extends Mock implements PreferenceService {}

void main() {
  group('家事ログの連続登録禁止', () {
    late MockWorkLogRepository mockWorkLogRepository;
    late MockAuthService mockAuthService;
    late MockSystemService mockSystemService;
    late MockErrorReportService mockErrorReportService;
    late MockInAppReviewService mockInAppReviewService;
    late MockPreferenceService mockPreferenceService;

    // 共通のテストデータ
    const testUserProfile = UserProfile.withGoogleAccount(
      id: 'user-1',
      displayName: 'Test User',
      photoUrl: 'https://example.com/photo.jpg',
    );
    const testCurrentHouseId = 'house-1';

    setUpAll(() {
      registerFallbackValue(
        AddWorkLogArgs(
          houseWorkId: 'fallback-house-work-id',
          completedAt: DateTime(2023),
          completedBy: 'fallback-user',
        ),
      );
      registerFallbackValue(
        PreferenceKey.hasRequestedAppReviewWhenOver30WorkLogs,
      );
      registerFallbackValue(Exception('fallback'));
      registerFallbackValue(StackTrace.empty);
    });

    setUp(() {
      mockWorkLogRepository = MockWorkLogRepository();
      mockAuthService = MockAuthService();
      mockSystemService = MockSystemService();
      mockErrorReportService = MockErrorReportService();
      mockInAppReviewService = MockInAppReviewService();
      mockPreferenceService = MockPreferenceService();

      // ErrorReportServiceのモックメソッドの設定
      when(
        () => mockErrorReportService.recordError(
          any<Exception>(),
          any<StackTrace>(),
        ),
      ).thenAnswer((_) async {});

      // ReviewServiceのモックメソッドの設定
      when(
        () => mockInAppReviewService.requestReview(),
      ).thenAnswer((_) async {});

      // PreferenceServiceのモックメソッドの設定
      when(
        () => mockPreferenceService.getBool(any()),
      ).thenAnswer((_) async => false);
      when(
        () => mockPreferenceService.getString(any()),
      ).thenAnswer((_) async => '0');
      when(
        () =>
            mockPreferenceService.setString(any(), value: any(named: 'value')),
      ).thenAnswer((_) async {});
      when(
        () => mockPreferenceService.getInt(any()),
      ).thenAnswer((_) async => 0);
      when(
        () => mockPreferenceService.setInt(any(), value: any(named: 'value')),
      ).thenAnswer((_) async {});
    });

    test('初回の家事登録は成功すること', () async {
      // テスト用のデータ
      final now = DateTime(2023, 1, 1, 12);
      const houseWorkId = 'house-work-1';

      // モックの設定
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(now);
      when(
        () => mockWorkLogRepository.add(any()),
      ).thenAnswer((_) async => 'test-id');
      final container = ProviderContainer(
        overrides: [
          unwrappedCurrentHouseIdProvider.overrideWith(
            (_) => testCurrentHouseId,
          ),
          workLogRepositoryProvider.overrideWith((_) => mockWorkLogRepository),
          authServiceProvider.overrideWith((_) => mockAuthService),
          systemServiceProvider.overrideWith((_) => mockSystemService),
          errorReportServiceProvider.overrideWith(
            (_) => mockErrorReportService,
          ),
          inAppReviewServiceProvider.overrideWith(
            (_) => mockInAppReviewService,
          ),
          preferenceServiceProvider.overrideWith((_) => mockPreferenceService),
          currentUserProfileProvider.overrideWith(
            (_) => Stream.value(testUserProfile),
          ),
        ],
      );

      // 実行
      final workLogService = container.read(workLogServiceProvider);
      final result = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 検証
      expect(result, 'test-id'); // WorkLogIDが返される
      verify(() => mockWorkLogRepository.add(any())).called(1);
    });

    test('3秒以内の連続登録は拒否されること', () async {
      // テスト用のデータ
      final firstTime = DateTime(2023, 1, 1, 12);
      final secondTime = DateTime(2023, 1, 1, 12, 0, 1, 500); // 1.5秒後
      const houseWorkId = 'house-work-1';

      // モックの設定
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(firstTime);
      when(
        () => mockWorkLogRepository.add(any()),
      ).thenAnswer((_) async => 'test-id');
      final container = ProviderContainer(
        overrides: [
          unwrappedCurrentHouseIdProvider.overrideWith(
            (_) => testCurrentHouseId,
          ),
          workLogRepositoryProvider.overrideWith((_) => mockWorkLogRepository),
          authServiceProvider.overrideWith((_) => mockAuthService),
          systemServiceProvider.overrideWith((_) => mockSystemService),
          errorReportServiceProvider.overrideWith(
            (_) => mockErrorReportService,
          ),
          inAppReviewServiceProvider.overrideWith(
            (_) => mockInAppReviewService,
          ),
          preferenceServiceProvider.overrideWith((_) => mockPreferenceService),
          currentUserProfileProvider.overrideWith(
            (_) => Stream.value(testUserProfile),
          ),
        ],
      );

      // 実行
      final workLogService = container.read(workLogServiceProvider);
      final firstResult = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 2回目の登録（1.5秒後）
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(secondTime);

      // 検証
      expect(firstResult, 'test-id');
      expect(
        () => workLogService.recordWorkLog(houseWorkId: houseWorkId),
        throwsA(isA<DebounceWorkLogException>()),
      ); // 連打防止により例外がスローされる
      verify(() => mockWorkLogRepository.add(any())).called(1); // 1回のみ保存される
    });

    test('3秒後の登録は許可されること', () async {
      // テスト用のデータ
      final firstTime = DateTime(2023, 1, 1, 12);
      final secondTime = DateTime(2023, 1, 1, 12, 0, 3); // 3秒後
      const houseWorkId = 'house-work-1';

      // モックの設定
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(firstTime);
      when(
        () => mockWorkLogRepository.add(any()),
      ).thenAnswer((_) async => 'test-id');
      final container = ProviderContainer(
        overrides: [
          unwrappedCurrentHouseIdProvider.overrideWith(
            (_) => testCurrentHouseId,
          ),
          workLogRepositoryProvider.overrideWith((_) => mockWorkLogRepository),
          authServiceProvider.overrideWith((_) => mockAuthService),
          systemServiceProvider.overrideWith((_) => mockSystemService),
          errorReportServiceProvider.overrideWith(
            (_) => mockErrorReportService,
          ),
          inAppReviewServiceProvider.overrideWith(
            (_) => mockInAppReviewService,
          ),
          preferenceServiceProvider.overrideWith((_) => mockPreferenceService),
          currentUserProfileProvider.overrideWith(
            (_) => Stream.value(testUserProfile),
          ),
        ],
      );

      // 実行
      final workLogService = container.read(workLogServiceProvider);
      final firstResult = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 2回目の登録（3秒後）
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(secondTime);
      final secondResult = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 検証
      expect(firstResult, 'test-id');
      expect(secondResult, 'test-id'); // 3秒経過しているので許可される
      verify(() => mockWorkLogRepository.add(any())).called(2); // 2回とも保存される
    });

    test('異なる家事の連続登録は許可されること', () async {
      // テスト用のデータ
      final now = DateTime(2023, 1, 1, 12);
      const houseWorkId1 = 'house-work-1';
      const houseWorkId2 = 'house-work-2';

      // モックの設定
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(now);
      when(
        () => mockWorkLogRepository.add(any()),
      ).thenAnswer((_) async => 'test-id');
      final container = ProviderContainer(
        overrides: [
          unwrappedCurrentHouseIdProvider.overrideWith(
            (_) => testCurrentHouseId,
          ),
          workLogRepositoryProvider.overrideWith((_) => mockWorkLogRepository),
          authServiceProvider.overrideWith((_) => mockAuthService),
          systemServiceProvider.overrideWith((_) => mockSystemService),
          errorReportServiceProvider.overrideWith(
            (_) => mockErrorReportService,
          ),
          inAppReviewServiceProvider.overrideWith(
            (_) => mockInAppReviewService,
          ),
          preferenceServiceProvider.overrideWith((_) => mockPreferenceService),
          currentUserProfileProvider.overrideWith(
            (_) => Stream.value(testUserProfile),
          ),
        ],
      );

      // 実行
      final workLogService = container.read(workLogServiceProvider);
      final result1 = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId1,
      );
      final result2 = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId2,
      );

      // 検証
      expect(result1, 'test-id');
      expect(result2, 'test-id'); // 異なる家事なので許可される
      verify(() => mockWorkLogRepository.add(any())).called(2); // 2回とも保存される
    });

    test('ユーザープロファイルがnullの場合は登録が失敗すること', () async {
      // テスト用のデータ
      final now = DateTime(2023, 1, 1, 12);
      const houseWorkId = 'house-work-1';

      // モックの設定
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(now);
      final container = ProviderContainer(
        overrides: [
          unwrappedCurrentHouseIdProvider.overrideWith(
            (_) => testCurrentHouseId,
          ),
          workLogRepositoryProvider.overrideWith((_) => mockWorkLogRepository),
          authServiceProvider.overrideWith((_) => mockAuthService),
          systemServiceProvider.overrideWith((_) => mockSystemService),
          inAppReviewServiceProvider.overrideWith(
            (_) => mockInAppReviewService,
          ),
          currentUserProfileProvider.overrideWith(
            (_) => Stream.value(null), // ユーザープロファイルがnull
          ),
        ],
      );

      // 実行
      final workLogService = container.read(workLogServiceProvider);
      final result = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 検証
      expect(result, isNull);
      verifyNever(() => mockWorkLogRepository.add(any())); // 保存は呼ばれない
    });

    test('リポジトリで例外が発生した場合は登録が失敗すること', () async {
      // テスト用のデータ
      final now = DateTime(2023, 1, 1, 12);
      const houseWorkId = 'house-work-1';

      // モックの設定
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(now);
      when(
        () => mockWorkLogRepository.add(any()),
      ).thenThrow(Exception('DB Error'));
      final container = ProviderContainer(
        overrides: [
          unwrappedCurrentHouseIdProvider.overrideWith(
            (_) => testCurrentHouseId,
          ),
          workLogRepositoryProvider.overrideWith((_) => mockWorkLogRepository),
          authServiceProvider.overrideWith((_) => mockAuthService),
          systemServiceProvider.overrideWith((_) => mockSystemService),
          errorReportServiceProvider.overrideWith(
            (_) => mockErrorReportService,
          ),
          inAppReviewServiceProvider.overrideWith(
            (_) => mockInAppReviewService,
          ),
          preferenceServiceProvider.overrideWith((_) => mockPreferenceService),
          currentUserProfileProvider.overrideWith(
            (_) => Stream.value(testUserProfile),
          ),
        ],
      );

      // 実行
      final workLogService = container.read(workLogServiceProvider);
      final result = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 検証
      expect(result, isNull);
      verify(() => mockWorkLogRepository.add(any())).called(1);
    });

    test('2999msの連続登録は拒否され、3000msの登録は許可されること', () async {
      // テスト用のデータ
      final firstTime = DateTime(2023, 1, 1, 12);
      final secondTime = DateTime(2023, 1, 1, 12, 0, 2, 999); // 2999ms後
      final thirdTime = DateTime(2023, 1, 1, 12, 0, 3); // 3000ms後
      const houseWorkId = 'house-work-1';

      // モックの設定
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(firstTime);
      when(
        () => mockWorkLogRepository.add(any()),
      ).thenAnswer((_) async => 'test-id');
      final container = ProviderContainer(
        overrides: [
          unwrappedCurrentHouseIdProvider.overrideWith(
            (_) => testCurrentHouseId,
          ),
          workLogRepositoryProvider.overrideWith((_) => mockWorkLogRepository),
          authServiceProvider.overrideWith((_) => mockAuthService),
          systemServiceProvider.overrideWith((_) => mockSystemService),
          errorReportServiceProvider.overrideWith(
            (_) => mockErrorReportService,
          ),
          inAppReviewServiceProvider.overrideWith(
            (_) => mockInAppReviewService,
          ),
          preferenceServiceProvider.overrideWith((_) => mockPreferenceService),
          currentUserProfileProvider.overrideWith(
            (_) => Stream.value(testUserProfile),
          ),
        ],
      );

      // 実行
      final workLogService = container.read(workLogServiceProvider);
      final firstResult = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 2回目の登録（2999ms後）- 例外がスローされることを検証
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(secondTime);
      expect(
        () => workLogService.recordWorkLog(houseWorkId: houseWorkId),
        throwsA(isA<DebounceWorkLogException>()),
      ); // 2999msなので例外がスローされる

      // 3回目の登録（3000ms後）
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(thirdTime);
      final thirdResult = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 検証
      expect(firstResult, 'test-id');
      expect(thirdResult, 'test-id'); // 3000msなので許可される
      verify(
        () => mockWorkLogRepository.add(any()),
      ).called(2); // 1回目と3回目のみ保存される
    });
  });
}

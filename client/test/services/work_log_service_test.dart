import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pochi_trim/data/model/app_session.dart';
import 'package:pochi_trim/data/model/user_profile.dart';
import 'package:pochi_trim/data/model/work_log.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/data/service/system_service.dart';
import 'package:pochi_trim/data/service/work_log_service.dart';
import 'package:pochi_trim/ui/root_presenter.dart';

class MockWorkLogRepository extends Mock implements WorkLogRepository {}

class MockAuthService extends Mock implements AuthService {}

class MockSystemService extends Mock implements SystemService {}

void main() {
  group('家事ログの連続登録禁止', () {
    late MockWorkLogRepository mockWorkLogRepository;
    late MockAuthService mockAuthService;
    late MockSystemService mockSystemService;

    // 共通のテストデータ
    const testUserProfile = UserProfile.withGoogleAccount(
      id: 'user-1',
      displayName: 'Test User',
      email: 'test@example.com',
      photoUrl: 'https://example.com/photo.jpg',
    );
    final testAppSession = AppSession.signedIn(
      currentHouseId: 'house-1',
      isPro: false,
    );

    setUpAll(() {
      registerFallbackValue(
        WorkLog(
          id: 'fallback-id',
          houseWorkId: 'fallback-house-work-id',
          completedAt: DateTime.now(),
          completedBy: 'fallback-user',
        ),
      );
    });

    setUp(() {
      mockWorkLogRepository = MockWorkLogRepository();
      mockAuthService = MockAuthService();
      mockSystemService = MockSystemService();
    });

    test('初回の家事登録は成功すること', () async {
      // テスト用のデータ
      final now = DateTime(2023, 1, 1, 12);
      const houseWorkId = 'house-work-1';

      // モックの設定
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(now);
      when(
        () => mockWorkLogRepository.save(any()),
      ).thenAnswer((_) async => 'test-id');
      final container = ProviderContainer(
        overrides: [
          unwrappedCurrentAppSessionProvider.overrideWith(
            (_) => testAppSession,
          ),
          workLogRepositoryProvider.overrideWith((_) => mockWorkLogRepository),
          authServiceProvider.overrideWith((_) => mockAuthService),
          systemServiceProvider.overrideWith((_) => mockSystemService),
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
      expect(result, isTrue);
      verify(() => mockWorkLogRepository.save(any())).called(1);
    });

    test('3秒以内の連続登録は拒否されること', () async {
      // テスト用のデータ
      final firstTime = DateTime(2023, 1, 1, 12);
      final secondTime = DateTime(2023, 1, 1, 12, 0, 1, 500); // 1.5秒後
      const houseWorkId = 'house-work-1';

      // モックの設定
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(firstTime);
      when(
        () => mockWorkLogRepository.save(any()),
      ).thenAnswer((_) async => 'test-id');
      final container = ProviderContainer(
        overrides: [
          unwrappedCurrentAppSessionProvider.overrideWith(
            (_) => testAppSession,
          ),
          workLogRepositoryProvider.overrideWith((_) => mockWorkLogRepository),
          authServiceProvider.overrideWith((_) => mockAuthService),
          systemServiceProvider.overrideWith((_) => mockSystemService),
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
      final secondResult = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 検証
      expect(firstResult, isTrue);
      expect(secondResult, isFalse); // 連打防止により拒否される
      verify(() => mockWorkLogRepository.save(any())).called(1); // 1回のみ保存される
    });

    test('3秒後の登録は許可されること', () async {
      // テスト用のデータ
      final firstTime = DateTime(2023, 1, 1, 12);
      final secondTime = DateTime(2023, 1, 1, 12, 0, 3); // 3秒後
      const houseWorkId = 'house-work-1';

      // モックの設定
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(firstTime);
      when(
        () => mockWorkLogRepository.save(any()),
      ).thenAnswer((_) async => 'test-id');
      final container = ProviderContainer(
        overrides: [
          unwrappedCurrentAppSessionProvider.overrideWith(
            (_) => testAppSession,
          ),
          workLogRepositoryProvider.overrideWith((_) => mockWorkLogRepository),
          authServiceProvider.overrideWith((_) => mockAuthService),
          systemServiceProvider.overrideWith((_) => mockSystemService),
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
      expect(firstResult, isTrue);
      expect(secondResult, isTrue); // 3秒経過しているので許可される
      verify(() => mockWorkLogRepository.save(any())).called(2); // 2回とも保存される
    });

    test('異なる家事の連続登録は許可されること', () async {
      // テスト用のデータ
      final now = DateTime(2023, 1, 1, 12);
      const houseWorkId1 = 'house-work-1';
      const houseWorkId2 = 'house-work-2';

      // モックの設定
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(now);
      when(
        () => mockWorkLogRepository.save(any()),
      ).thenAnswer((_) async => 'test-id');
      final container = ProviderContainer(
        overrides: [
          unwrappedCurrentAppSessionProvider.overrideWith(
            (_) => testAppSession,
          ),
          workLogRepositoryProvider.overrideWith((_) => mockWorkLogRepository),
          authServiceProvider.overrideWith((_) => mockAuthService),
          systemServiceProvider.overrideWith((_) => mockSystemService),
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
      expect(result1, isTrue);
      expect(result2, isTrue); // 異なる家事なので許可される
      verify(() => mockWorkLogRepository.save(any())).called(2); // 2回とも保存される
    });

    test('ユーザープロファイルがnullの場合は登録が失敗すること', () async {
      // テスト用のデータ
      final now = DateTime(2023, 1, 1, 12);
      const houseWorkId = 'house-work-1';

      // モックの設定
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(now);
      final container = ProviderContainer(
        overrides: [
          unwrappedCurrentAppSessionProvider.overrideWith(
            (_) => testAppSession,
          ),
          workLogRepositoryProvider.overrideWith((_) => mockWorkLogRepository),
          authServiceProvider.overrideWith((_) => mockAuthService),
          systemServiceProvider.overrideWith((_) => mockSystemService),
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
      expect(result, isFalse);
      verifyNever(() => mockWorkLogRepository.save(any())); // 保存は呼ばれない
    });

    test('リポジトリで例外が発生した場合は登録が失敗すること', () async {
      // テスト用のデータ
      final now = DateTime(2023, 1, 1, 12);
      const houseWorkId = 'house-work-1';

      // モックの設定
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(now);
      when(
        () => mockWorkLogRepository.save(any()),
      ).thenThrow(Exception('DB Error'));
      final container = ProviderContainer(
        overrides: [
          unwrappedCurrentAppSessionProvider.overrideWith(
            (_) => testAppSession,
          ),
          workLogRepositoryProvider.overrideWith((_) => mockWorkLogRepository),
          authServiceProvider.overrideWith((_) => mockAuthService),
          systemServiceProvider.overrideWith((_) => mockSystemService),
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
      expect(result, isFalse);
      verify(() => mockWorkLogRepository.save(any())).called(1);
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
        () => mockWorkLogRepository.save(any()),
      ).thenAnswer((_) async => 'test-id');
      final container = ProviderContainer(
        overrides: [
          unwrappedCurrentAppSessionProvider.overrideWith(
            (_) => testAppSession,
          ),
          workLogRepositoryProvider.overrideWith((_) => mockWorkLogRepository),
          authServiceProvider.overrideWith((_) => mockAuthService),
          systemServiceProvider.overrideWith((_) => mockSystemService),
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

      // 2回目の登録（2999ms後）
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(secondTime);
      final secondResult = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 3回目の登録（3000ms後）
      when(() => mockSystemService.getCurrentDateTime()).thenReturn(thirdTime);
      final thirdResult = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 検証
      expect(firstResult, isTrue);
      expect(secondResult, isFalse); // 2999msなので拒否される
      expect(thirdResult, isTrue); // 3000msなので許可される
      verify(
        () => mockWorkLogRepository.save(any()),
      ).called(2); // 1回目と3回目のみ保存される
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pochi_trim/data/model/user_profile.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/data/service/system_service.dart';
import 'package:pochi_trim/data/service/work_log_service.dart';

@GenerateMocks([WorkLogRepository, AuthService, SystemService, Ref])
import 'work_log_service_test.mocks.dart';

Future<UserProfile?> _dummyUserProfileFuture() async => null;

void main() {
  group('WorkLogService 連打防止テスト', () {
    late MockWorkLogRepository mockWorkLogRepository;
    late MockAuthService mockAuthService;
    late MockSystemService mockSystemService;
    late MockRef mockRef;
    late WorkLogService workLogService;

    setUp(() {
      provideDummy<Future<UserProfile?>>(_dummyUserProfileFuture());

      mockWorkLogRepository = MockWorkLogRepository();
      mockAuthService = MockAuthService();
      mockSystemService = MockSystemService();
      mockRef = MockRef();

      workLogService = WorkLogService(
        workLogRepository: mockWorkLogRepository,
        authService: mockAuthService,
        currentHouseId: 'house-1',
        systemService: mockSystemService,
        ref: mockRef,
      );
    });

    test('初回の家事登録は成功すること', () async {
      // テスト用のデータ
      final now = DateTime(2023, 1, 1, 12);
      const houseWorkId = 'house-work-1';
      const userProfile = UserProfile.withGoogleAccount(
        id: 'user-1',
        displayName: 'Test User',
        email: 'test@example.com',
        photoUrl: 'https://example.com/photo.jpg',
      );

      // モックの設定
      when(mockSystemService.getCurrentDateTime()).thenReturn(now);
      when(
        mockRef.read(currentUserProfileProvider.future),
      ).thenAnswer((_) async => userProfile);
      when(mockWorkLogRepository.save(any)).thenAnswer((_) async => 'test-id');

      // 実行
      final result = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 検証
      expect(result, isTrue);
      verify(mockWorkLogRepository.save(any)).called(1);
    });

    test('1秒以内の連続登録は拒否されること', () async {
      // テスト用のデータ
      final firstTime = DateTime(2023, 1, 1, 12);
      final secondTime = DateTime(2023, 1, 1, 12, 0, 0, 500); // 500ms後
      const houseWorkId = 'house-work-1';
      const userProfile = UserProfile.withGoogleAccount(
        id: 'user-1',
        displayName: 'Test User',
        email: 'test@example.com',
        photoUrl: 'https://example.com/photo.jpg',
      );

      // モックの設定
      when(
        mockRef.read(currentUserProfileProvider.future),
      ).thenAnswer((_) async => userProfile);
      when(mockWorkLogRepository.save(any)).thenAnswer((_) async => 'test-id');

      // 1回目の登録
      when(mockSystemService.getCurrentDateTime()).thenReturn(firstTime);
      final firstResult = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 2回目の登録（500ms後）
      when(mockSystemService.getCurrentDateTime()).thenReturn(secondTime);
      final secondResult = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 検証
      expect(firstResult, isTrue);
      expect(secondResult, isFalse); // 連打防止により拒否される
      verify(mockWorkLogRepository.save(any)).called(1); // 1回のみ保存される
    });

    test('1秒後の登録は許可されること', () async {
      // テスト用のデータ
      final firstTime = DateTime(2023, 1, 1, 12);
      final secondTime = DateTime(2023, 1, 1, 12, 0, 1); // 1秒後
      const houseWorkId = 'house-work-1';
      const userProfile = UserProfile.withGoogleAccount(
        id: 'user-1',
        displayName: 'Test User',
        email: 'test@example.com',
        photoUrl: 'https://example.com/photo.jpg',
      );

      // モックの設定
      when(
        mockRef.read(currentUserProfileProvider.future),
      ).thenAnswer((_) async => userProfile);
      when(mockWorkLogRepository.save(any)).thenAnswer((_) async => 'test-id');

      // 1回目の登録
      when(mockSystemService.getCurrentDateTime()).thenReturn(firstTime);
      final firstResult = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 2回目の登録（1秒後）
      when(mockSystemService.getCurrentDateTime()).thenReturn(secondTime);
      final secondResult = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 検証
      expect(firstResult, isTrue);
      expect(secondResult, isTrue); // 1秒経過しているので許可される
      verify(mockWorkLogRepository.save(any)).called(2); // 2回とも保存される
    });

    test('異なる家事の連続登録は許可されること', () async {
      // テスト用のデータ
      final now = DateTime(2023, 1, 1, 12);
      const houseWorkId1 = 'house-work-1';
      const houseWorkId2 = 'house-work-2';
      const userProfile = UserProfile.withGoogleAccount(
        id: 'user-1',
        displayName: 'Test User',
        email: 'test@example.com',
        photoUrl: 'https://example.com/photo.jpg',
      );

      // モックの設定
      when(mockSystemService.getCurrentDateTime()).thenReturn(now);
      when(
        mockRef.read(currentUserProfileProvider.future),
      ).thenAnswer((_) async => userProfile);
      when(mockWorkLogRepository.save(any)).thenAnswer((_) async => 'test-id');

      // 異なる家事の連続登録
      final result1 = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId1,
      );
      final result2 = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId2,
      );

      // 検証
      expect(result1, isTrue);
      expect(result2, isTrue); // 異なる家事なので許可される
      verify(mockWorkLogRepository.save(any)).called(2); // 2回とも保存される
    });

    test('ユーザープロファイルがnullの場合は登録が失敗すること', () async {
      // テスト用のデータ
      final now = DateTime(2023, 1, 1, 12);
      const houseWorkId = 'house-work-1';

      // モックの設定
      when(mockSystemService.getCurrentDateTime()).thenReturn(now);
      when(
        mockRef.read(currentUserProfileProvider.future),
      ).thenAnswer((_) async => null); // ユーザープロファイルがnull

      // 実行
      final result = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 検証
      expect(result, isFalse);
      verifyNever(mockWorkLogRepository.save(any)); // 保存は呼ばれない
    });

    test('リポジトリで例外が発生した場合は登録が失敗すること', () async {
      // テスト用のデータ
      final now = DateTime(2023, 1, 1, 12);
      const houseWorkId = 'house-work-1';
      const userProfile = UserProfile.withGoogleAccount(
        id: 'user-1',
        displayName: 'Test User',
        email: 'test@example.com',
        photoUrl: 'https://example.com/photo.jpg',
      );

      // モックの設定
      when(mockSystemService.getCurrentDateTime()).thenReturn(now);
      when(
        mockRef.read(currentUserProfileProvider.future),
      ).thenAnswer((_) async => userProfile);
      when(mockWorkLogRepository.save(any)).thenThrow(Exception('DB Error'));

      // 実行
      final result = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 検証
      expect(result, isFalse);
      verify(mockWorkLogRepository.save(any)).called(1);
    });

    test('999msの連続登録は拒否され、1000msの登録は許可されること', () async {
      // テスト用のデータ
      final firstTime = DateTime(2023, 1, 1, 12);
      final secondTime = DateTime(2023, 1, 1, 12, 0, 0, 999); // 999ms後
      final thirdTime = DateTime(2023, 1, 1, 12, 0, 1); // 1000ms後
      const houseWorkId = 'house-work-1';
      const userProfile = UserProfile.withGoogleAccount(
        id: 'user-1',
        displayName: 'Test User',
        email: 'test@example.com',
        photoUrl: 'https://example.com/photo.jpg',
      );

      // モックの設定
      when(
        mockRef.read(currentUserProfileProvider.future),
      ).thenAnswer((_) async => userProfile);
      when(mockWorkLogRepository.save(any)).thenAnswer((_) async => 'test-id');

      // 1回目の登録
      when(mockSystemService.getCurrentDateTime()).thenReturn(firstTime);
      final firstResult = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 2回目の登録（999ms後）
      when(mockSystemService.getCurrentDateTime()).thenReturn(secondTime);
      final secondResult = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 3回目の登録（1000ms後）
      when(mockSystemService.getCurrentDateTime()).thenReturn(thirdTime);
      final thirdResult = await workLogService.recordWorkLog(
        houseWorkId: houseWorkId,
      );

      // 検証
      expect(firstResult, isTrue);
      expect(secondResult, isFalse); // 999msなので拒否される
      expect(thirdResult, isTrue); // 1000msなので許可される
      verify(mockWorkLogRepository.save(any)).called(2); // 1回目と3回目のみ保存される
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pochi_trim/data/model/update_work_log_exception.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';
import 'package:pochi_trim/data/service/system_service.dart';
import 'package:pochi_trim/ui/feature/home/edit_work_log_presenter.dart';

class MockSystemService extends Mock implements SystemService {}

class MockWorkLogRepository extends Mock implements WorkLogRepository {}

void main() {
  group('家事ログの完了日時の更新', () {
    late MockSystemService mockSystemService;
    late MockWorkLogRepository mockWorkLogRepository;
    late ProviderContainer container;

    setUpAll(() {
      registerFallbackValue(DateTime.now());
    });

    setUp(() {
      mockSystemService = MockSystemService();
      mockWorkLogRepository = MockWorkLogRepository();
      container = ProviderContainer(
        overrides: [
          workLogRepositoryProvider.overrideWith((_) => mockWorkLogRepository),
          systemServiceProvider.overrideWith((_) => mockSystemService),
        ],
      );
    });

    test('現在時刻より過去の日時で更新できること', () async {
      // Arrange
      const workLogId = 'test-work-log-id';
      final now = DateTime(2023, 12, 25, 15);
      final completedAt = DateTime(2023, 12, 25, 14, 30); // 30分前

      when(() => mockSystemService.getCurrentDateTime()).thenReturn(now);
      when(
        () => mockWorkLogRepository.updateCompletedAt(
          workLogId,
          completedAt: completedAt,
        ),
      ).thenAnswer((_) async {});

      // Act & Assert (例外がスローされないことを確認)
      await expectLater(
        container.read(
          updateCompletedAtOfWorkLogProvider(workLogId, completedAt).future,
        ),
        completes,
      );

      // Verify
      verify(
        () => mockWorkLogRepository.updateCompletedAt(
          workLogId,
          completedAt: completedAt,
        ),
      ).called(1);
      verify(() => mockSystemService.getCurrentDateTime()).called(1);
    });

    test('現在時刻と同じ日時で更新できること', () async {
      // Arrange
      const workLogId = 'test-work-log-id';
      final now = DateTime(2023, 12, 25, 15);
      final completedAt = now; // 現在時刻と同じ

      when(() => mockSystemService.getCurrentDateTime()).thenReturn(now);
      when(
        () => mockWorkLogRepository.updateCompletedAt(
          workLogId,
          completedAt: completedAt,
        ),
      ).thenAnswer((_) async {});

      // Act & Assert (例外がスローされないことを確認)
      await expectLater(
        container.read(
          updateCompletedAtOfWorkLogProvider(workLogId, completedAt).future,
        ),
        completes,
      );

      // Verify
      verify(
        () => mockWorkLogRepository.updateCompletedAt(
          workLogId,
          completedAt: completedAt,
        ),
      ).called(1);
      verify(() => mockSystemService.getCurrentDateTime()).called(1);
    });

    test('現在時刻より未来の日時では更新できないこと', () async {
      // Arrange
      const workLogId = 'test-work-log-id';
      final now = DateTime(2023, 12, 25, 15);
      final completedAt = DateTime(2023, 12, 25, 16); // 1時間後

      when(() => mockSystemService.getCurrentDateTime()).thenReturn(now);

      // Act & Assert
      await expectLater(
        container.read(
          updateCompletedAtOfWorkLogProvider(workLogId, completedAt).future,
        ),
        throwsA(isA<UpdateWorkLogExceptionFutureDateTime>()),
      );

      // Verify (リポジトリのupdateCompletedAtが呼ばれていないことを確認)
      verifyNever(
        () => mockWorkLogRepository.updateCompletedAt(
          any(),
          completedAt: any(named: 'completedAt'),
        ),
      );
      verify(() => mockSystemService.getCurrentDateTime()).called(1);
    });

    test('データストアに対する更新が失敗した場合、更新できないこと', () async {
      // Arrange
      const workLogId = 'test-work-log-id';
      final now = DateTime(2023, 12, 25, 15);
      final completedAt = DateTime(2023, 12, 25, 14, 30); // 30分前

      when(() => mockSystemService.getCurrentDateTime()).thenReturn(now);
      when(
        () => mockWorkLogRepository.updateCompletedAt(
          workLogId,
          completedAt: completedAt,
        ),
      ).thenThrow(const UpdateWorkLogException.uncategorized());

      // Act & Assert
      await expectLater(
        container.read(
          updateCompletedAtOfWorkLogProvider(workLogId, completedAt).future,
        ),
        throwsA(isA<UpdateWorkLogExceptionUncategorized>()),
      );

      // Verify
      verify(
        () => mockWorkLogRepository.updateCompletedAt(
          workLogId,
          completedAt: completedAt,
        ),
      ).called(1);
      verify(() => mockSystemService.getCurrentDateTime()).called(1);
    });

    test('正しい引数でリポジトリのupdateCompletedAtメソッドが呼ばれること', () async {
      // Arrange
      const workLogId = 'specific-work-log-id';
      final now = DateTime(2023, 12, 25, 15);
      final completedAt = DateTime(2023, 12, 25, 10, 15, 30); // 具体的な時刻

      when(() => mockSystemService.getCurrentDateTime()).thenReturn(now);
      when(
        () => mockWorkLogRepository.updateCompletedAt(
          workLogId,
          completedAt: completedAt,
        ),
      ).thenAnswer((_) async {});

      // Act
      await container.read(
        updateCompletedAtOfWorkLogProvider(workLogId, completedAt).future,
      );

      // Assert
      verify(
        () => mockWorkLogRepository.updateCompletedAt(
          workLogId,
          completedAt: completedAt,
        ),
      ).called(1);
      verify(() => mockSystemService.getCurrentDateTime()).called(1);
    });

    test('ミリ秒レベルで未来の場合でも例外がスローされること', () async {
      // Arrange
      const workLogId = 'test-work-log-id';
      final now = DateTime(2023, 12, 25, 15);
      final completedAt = DateTime(2023, 12, 25, 15, 0, 0, 1); // 1ミリ秒後

      when(() => mockSystemService.getCurrentDateTime()).thenReturn(now);

      // Act & Assert
      await expectLater(
        container.read(
          updateCompletedAtOfWorkLogProvider(workLogId, completedAt).future,
        ),
        throwsA(isA<UpdateWorkLogExceptionFutureDateTime>()),
      );

      // Verify (リポジトリのupdateCompletedAtが呼ばれていないことを確認)
      verifyNever(
        () => mockWorkLogRepository.updateCompletedAt(
          any(),
          completedAt: any(named: 'completedAt'),
        ),
      );
      verify(() => mockSystemService.getCurrentDateTime()).called(1);
    });

    test('境界値テスト: 現在時刻の1ミリ秒前は成功すること', () async {
      // Arrange
      const workLogId = 'test-work-log-id';
      final now = DateTime(2023, 12, 25, 15, 0, 0, 1);
      final completedAt = DateTime(2023, 12, 25, 15); // 1ミリ秒前

      when(() => mockSystemService.getCurrentDateTime()).thenReturn(now);
      when(
        () => mockWorkLogRepository.updateCompletedAt(
          workLogId,
          completedAt: completedAt,
        ),
      ).thenAnswer((_) async {});

      // Act & Assert
      await expectLater(
        container.read(
          updateCompletedAtOfWorkLogProvider(workLogId, completedAt).future,
        ),
        completes,
      );

      // Verify
      verify(
        () => mockWorkLogRepository.updateCompletedAt(
          workLogId,
          completedAt: completedAt,
        ),
      ).called(1);
      verify(() => mockSystemService.getCurrentDateTime()).called(1);
    });
  });
}

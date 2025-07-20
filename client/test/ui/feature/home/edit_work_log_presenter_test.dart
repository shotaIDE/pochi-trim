import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pochi_trim/data/model/update_work_log_exception.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';
import 'package:pochi_trim/data/service/error_report_service.dart';
import 'package:pochi_trim/data/service/system_service.dart';
import 'package:pochi_trim/ui/feature/home/edit_work_log_presenter.dart';

class MockWorkLogRepository extends WorkLogRepository {
  MockWorkLogRepository()
    : super(
        houseId: 'test-house-id',
        systemService: MockSystemService(),
        errorReportService: MockErrorReportService(),
      );

  var _shouldThrowException = false;
  UpdateWorkLogException? _exceptionToThrow;
  String? _lastUpdateId;
  DateTime? _lastUpdateDateTime;

  void setThrowException(UpdateWorkLogException exception) {
    _shouldThrowException = true;
    _exceptionToThrow = exception;
  }

  void resetMock() {
    _shouldThrowException = false;
    _exceptionToThrow = null;
    _lastUpdateId = null;
    _lastUpdateDateTime = null;
  }

  @override
  Future<void> updateCompletedAt(
    String id, {
    required DateTime completedAt,
  }) async {
    _lastUpdateId = id;
    _lastUpdateDateTime = completedAt;

    if (_shouldThrowException && _exceptionToThrow != null) {
      throw _exceptionToThrow!;
    }
  }

  String? get lastUpdateId => _lastUpdateId;
  DateTime? get lastUpdateDateTime => _lastUpdateDateTime;
}

class MockSystemService extends SystemService {
  var currentDateTime = DateTime(2023, 12, 25, 15);

  @override
  DateTime getCurrentDateTime() => currentDateTime;
}

class MockErrorReportService extends ErrorReportService {
  @override
  Future<void> recordError(
    dynamic error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) async {
    // テスト用の空実装
  }
}

void main() {
  group('updateCompletedAtOfWorkLog', () {
    late ProviderContainer container;
    late MockWorkLogRepository mockWorkLogRepository;
    late MockSystemService mockSystemService;

    setUp(() {
      mockWorkLogRepository = MockWorkLogRepository();
      mockSystemService = MockSystemService();

      container = ProviderContainer(
        overrides: [
          workLogRepositoryProvider.overrideWithValue(mockWorkLogRepository),
          systemServiceProvider.overrideWithValue(mockSystemService),
        ],
      );
      addTearDown(container.dispose);
    });

    tearDown(() {
      mockWorkLogRepository.resetMock();
    });

    test('現在時刻より過去の日時で更新が成功すること', () async {
      // Arrange
      const workLogId = 'test-work-log-id';
      final now = DateTime(2023, 12, 25, 15);
      final completedAt = DateTime(2023, 12, 25, 14, 30); // 30分前

      mockSystemService.currentDateTime = now;

      // Act & Assert (例外がスローされないことを確認)
      await expectLater(
        container.read(
          updateCompletedAtOfWorkLogProvider(workLogId, completedAt).future,
        ),
        completes,
      );

      // Verify
      expect(mockWorkLogRepository.lastUpdateId, equals(workLogId));
      expect(mockWorkLogRepository.lastUpdateDateTime, equals(completedAt));
    });

    test('現在時刻と同じ日時で更新が成功すること', () async {
      // Arrange
      const workLogId = 'test-work-log-id';
      final now = DateTime(2023, 12, 25, 15);
      final completedAt = now; // 現在時刻と同じ

      mockSystemService.currentDateTime = now;

      // Act & Assert (例外がスローされないことを確認)
      await expectLater(
        container.read(
          updateCompletedAtOfWorkLogProvider(workLogId, completedAt).future,
        ),
        completes,
      );

      // Verify
      expect(mockWorkLogRepository.lastUpdateId, equals(workLogId));
      expect(mockWorkLogRepository.lastUpdateDateTime, equals(completedAt));
    });

    test('未来の日時が指定された場合にfutureDateTimeException例外がスローされること', () async {
      // Arrange
      const workLogId = 'test-work-log-id';
      final now = DateTime(2023, 12, 25, 15);
      final completedAt = DateTime(2023, 12, 25, 16); // 1時間後

      mockSystemService.currentDateTime = now;

      // Act & Assert
      await expectLater(
        container.read(
          updateCompletedAtOfWorkLogProvider(workLogId, completedAt).future,
        ),
        throwsA(isA<UpdateWorkLogExceptionFutureDateTime>()),
      );

      // Verify (リポジトリのupdateCompletedAtが呼ばれていないことを確認)
      expect(mockWorkLogRepository.lastUpdateId, isNull);
      expect(mockWorkLogRepository.lastUpdateDateTime, isNull);
    });

    test('リポジトリでuncategorized例外がスローされた場合にそのまま伝播されること', () async {
      // Arrange
      const workLogId = 'test-work-log-id';
      final now = DateTime(2023, 12, 25, 15);
      final completedAt = DateTime(2023, 12, 25, 14, 30); // 30分前

      mockSystemService.currentDateTime = now;
      mockWorkLogRepository.setThrowException(
        const UpdateWorkLogException.uncategorized(),
      );

      // Act & Assert
      await expectLater(
        container.read(
          updateCompletedAtOfWorkLogProvider(workLogId, completedAt).future,
        ),
        throwsA(isA<UpdateWorkLogExceptionUncategorized>()),
      );

      // Verify
      expect(mockWorkLogRepository.lastUpdateId, equals(workLogId));
      expect(mockWorkLogRepository.lastUpdateDateTime, equals(completedAt));
    });

    test('正しい引数でリポジトリのupdateCompletedAtメソッドが呼ばれること', () async {
      // Arrange
      const workLogId = 'specific-work-log-id';
      final now = DateTime(2023, 12, 25, 15);
      final completedAt = DateTime(2023, 12, 25, 10, 15, 30); // 具体的な時刻

      mockSystemService.currentDateTime = now;

      // Act
      await container.read(
        updateCompletedAtOfWorkLogProvider(workLogId, completedAt).future,
      );

      // Assert
      expect(mockWorkLogRepository.lastUpdateId, equals(workLogId));
      expect(mockWorkLogRepository.lastUpdateDateTime, equals(completedAt));
    });
  });
}

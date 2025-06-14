import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/house_work.dart';
import 'package:pochi_trim/data/model/work_log.dart';
import 'package:pochi_trim/data/repository/house_work_repository.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';
import 'package:pochi_trim/data/service/work_log_service.dart';
import 'package:pochi_trim/ui/feature/home/work_log_included_house_work.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'work_logs_presenter.g.dart';

@riverpod
Future<List<WorkLogIncludedHouseWork>> workLogsIncludedHouseWork(
  Ref ref,
) async {
  final houseWorksFuture = ref.watch(_houseWorksFilePrivateProvider.future);
  final workLogsFuture = ref.watch(
    _completedWorkLogsFilePrivateProvider.future,
  );

  final houseWorks = await houseWorksFuture;
  final workLogs = await workLogsFuture;

  final workLogsForDisplay = workLogs
      .map((workLog) {
        final houseWork = houseWorks.firstWhereOrNull(
          (houseWork) => houseWork.id == workLog.houseWorkId,
        );

        if (houseWork == null) {
          return null;
        }

        return WorkLogIncludedHouseWork.fromWorkLogAndHouseWork(
          workLog: workLog,
          houseWork: houseWork,
        );
      })
      .nonNulls
      .toList();

  return workLogsForDisplay;
}

// TODO(ide): 複数のPresenterに定義されているので、共通化する
@riverpod
Stream<List<HouseWork>> _houseWorksFilePrivate(Ref ref) {
  final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);

  return houseWorkRepository.getAll();
}

// TODO(ide): 複数のPresenterに定義されているので、共通化する
@riverpod
Stream<List<WorkLog>> _completedWorkLogsFilePrivate(Ref ref) {
  final workLogRepository = ref.watch(workLogRepositoryProvider);

  return workLogRepository.getCompletedWorkLogs();
}

/// ページネーション状態クラス
class WorkLogsPaginationState {
  const WorkLogsPaginationState({
    required this.workLogs,
    required this.isLoading,
    required this.hasMore,
    required this.lastCompletedAt,
  });

  final List<WorkLog> workLogs;
  final bool isLoading;
  final bool hasMore;
  final DateTime? lastCompletedAt;

  WorkLogsPaginationState copyWith({
    List<WorkLog>? workLogs,
    bool? isLoading,
    bool? hasMore,
    DateTime? lastCompletedAt,
  }) {
    return WorkLogsPaginationState(
      workLogs: workLogs ?? this.workLogs,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
    );
  }
}

/// 無限スクロール用の家事ログページネーション状態管理
@riverpod
class WorkLogsPagination extends _$WorkLogsPagination {
  @override
  WorkLogsPaginationState build() {
    return const WorkLogsPaginationState(
      workLogs: [],
      isLoading: false,
      hasMore: true,
      lastCompletedAt: null,
    );
  }

  /// 初期ロードを実行
  Future<void> loadInitial() async {
    if (state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final workLogService = ref.read(workLogServiceProvider);
      final workLogs = await workLogService
          .getCompletedWorkLogsWithPagination();

      state = WorkLogsPaginationState(
        workLogs: workLogs,
        isLoading: false,
        hasMore: workLogs.length == 20,
        lastCompletedAt: workLogs.isNotEmpty ? workLogs.last.completedAt : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// 次のページをロード
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final workLogService = ref.read(workLogServiceProvider);
      final newWorkLogs = await workLogService
          .getCompletedWorkLogsWithPagination(
            lastCompletedAt: state.lastCompletedAt,
          );

      final allWorkLogs = [...state.workLogs, ...newWorkLogs];

      state = WorkLogsPaginationState(
        workLogs: allWorkLogs,
        isLoading: false,
        hasMore: newWorkLogs.length == 20,
        lastCompletedAt: newWorkLogs.isNotEmpty
            ? newWorkLogs.last.completedAt
            : state.lastCompletedAt,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// リフレッシュを実行
  Future<void> refresh() async {
    state = const WorkLogsPaginationState(
      workLogs: [],
      isLoading: false,
      hasMore: true,
      lastCompletedAt: null,
    );
    await loadInitial();
  }
}

/// ページネーション対応の家事ログ表示用プロバイダー
@riverpod
Future<List<WorkLogIncludedHouseWork>> workLogsIncludedHouseWorkWithPagination(
  Ref ref,
) async {
  final houseWorksFuture = ref.watch(_houseWorksFilePrivateProvider.future);
  final paginationState = ref.watch(workLogsPaginationProvider);

  final houseWorks = await houseWorksFuture;
  final workLogs = paginationState.workLogs;

  final workLogsForDisplay = workLogs
      .map((WorkLog workLog) {
        final houseWork = houseWorks.firstWhereOrNull(
          (houseWork) => houseWork.id == workLog.houseWorkId,
        );

        if (houseWork == null) {
          return null;
        }

        return WorkLogIncludedHouseWork.fromWorkLogAndHouseWork(
          workLog: workLog,
          houseWork: houseWork,
        );
      })
      .nonNulls
      .toList();

  return workLogsForDisplay;
}

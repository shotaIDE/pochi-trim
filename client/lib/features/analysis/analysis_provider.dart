import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/analysis/analysis_screen.dart';
import 'package:house_worker/features/analysis/weekday_frequency.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
import 'package:house_worker/services/house_id_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analysis_provider.g.dart';

// 曜日ごとの家事実行頻度を取得するプロバイダー（期間フィルタリング付き）
@riverpod
Future<List<WeekdayFrequency>> filteredWeekdayFrequencies(
  Ref ref, {
  required int period,
}) async {
  // フィルタリングされた家事ログのデータを待機
  final workLogs = await ref.watch(filteredWorkLogsProvider(period).future);
  final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);
  final houseId = ref.watch(currentHouseIdProvider);

  // 曜日名の配列（インデックスは0が日曜日）
  final weekdayNames = ['日曜日', '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日'];

  // 曜日ごと、家事IDごとにグループ化して頻度をカウント
  final weekdayMap = <int, Map<String, int>>{};
  // 各曜日の初期化
  for (var i = 0; i < 7; i++) {
    weekdayMap[i] = <String, int>{};
  }

  // 家事ログを曜日と家事IDでグループ化
  for (final workLog in workLogs) {
    final weekday = workLog.completedAt.weekday % 7; // 0-6の値（0が日曜日）
    final houseWorkId = workLog.houseWorkId;

    weekdayMap[weekday]![houseWorkId] =
        (weekdayMap[weekday]![houseWorkId] ?? 0) + 1;
  }

  // WeekdayFrequencyのリストを作成
  final result = <WeekdayFrequency>[];
  for (var i = 0; i < 7; i++) {
    final houseWorkFrequencies = <HouseWorkFrequency>[];
    var totalCount = 0;

    // 各家事IDごとの頻度を取得
    for (final entry in weekdayMap[i]!.entries) {
      final houseWork = await houseWorkRepository.getByIdOnce(
        houseId: houseId,
        houseWorkId: entry.key,
      );

      if (houseWork != null) {
        houseWorkFrequencies.add(
          HouseWorkFrequency(houseWork: houseWork, count: entry.value),
        );
        totalCount += entry.value;
      }
    }

    // 頻度の高い順にソート
    houseWorkFrequencies.sort((a, b) => b.count.compareTo(a.count));

    result.add(
      WeekdayFrequency(
        weekday: weekdayNames[i],
        houseWorkFrequencies: houseWorkFrequencies,
        totalCount: totalCount,
      ),
    );
  }

  return result;
}

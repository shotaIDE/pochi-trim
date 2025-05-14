import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/count.dart';
import 'package:house_worker/data/service/database_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_presenter.g.dart';

@riverpod
Stream<Count> currentCount(Ref ref) {
  final databaseService = ref.watch(databaseServiceProvider);

  return databaseService.getAll();
}

@riverpod
Future<void> countUpResult(Ref ref) async {
  final databaseService = ref.watch(databaseServiceProvider);

  final currentCount = await ref.read(currentCountProvider.future);

  final newCount = currentCount.copyWith(
    value: currentCount.value + 1,
    updatedAt: DateTime.now(),
  );

  // TODO(ide): エラー処理
  await databaseService.save(newCount);
}

@riverpod
Future<void> clearCountResult(Ref ref) async {
  final databaseService = ref.watch(databaseServiceProvider);

  final currentCount = await ref.read(currentCountProvider.future);

  final newCount = currentCount.copyWith(value: 0, updatedAt: DateTime.now());

  // TODO(ide): エラー処理
  await databaseService.save(newCount);
}

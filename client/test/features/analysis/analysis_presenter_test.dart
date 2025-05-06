import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/features/analysis/analysis_presenter.dart';

void main() {
  group('HouseWorkVisibilities Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('初期状態は空のマップであること', () {
      final visibilities = container.read(houseWorkVisibilitiesProvider);
      expect(visibilities, isEmpty);
    });

    test('toggle()メソッドが家事の表示状態を切り替えること', () {
      // 初期状態を確認
      var visibilities = container.read(houseWorkVisibilitiesProvider);
      expect(visibilities, isEmpty);

      // house-work-1の表示状態を切り替え（初期状態はtrueとみなされる）
      container
          .read(houseWorkVisibilitiesProvider.notifier)
          .toggle(houseWorkId: 'house-work-1');

      // 状態が更新されたことを確認
      visibilities = container.read(houseWorkVisibilitiesProvider);
      expect(visibilities['house-work-1'], isFalse);

      // もう一度切り替え
      container
          .read(houseWorkVisibilitiesProvider.notifier)
          .toggle(houseWorkId: 'house-work-1');

      // 状態が再度更新されたことを確認
      visibilities = container.read(houseWorkVisibilitiesProvider);
      expect(visibilities['house-work-1'], isTrue);
    });

    // focusOrUnfocus()メソッドは_houseWorksFilePrivateProviderに依存しているため、
    // 実際のテストでは実行できません。このメソッドのテストは省略します。
    // 代わりに、このメソッドの動作を説明するコメントを残しておきます。

    // focusOrUnfocus()メソッドは以下の機能を持っています：
    // 1. 特定の家事にフォーカスを当てると、その家事のみが表示され、他の家事は非表示になる
    // 2. すでにフォーカスが当たっている家事に対して再度呼び出すと、フォーカスが解除され、元の状態に戻る
    // 3. 別の家事にフォーカスを当てると、フォーカスが移動する

    // toggle()メソッドのみをテストする追加のテストケース
    test('複数の家事の表示状態を切り替えること', () {
      // 初期状態を確認
      var visibilities = container.read(houseWorkVisibilitiesProvider);
      expect(visibilities, isEmpty);

      // house-work-1の表示状態を切り替え
      container
          .read(houseWorkVisibilitiesProvider.notifier)
          .toggle(houseWorkId: 'house-work-1');

      // house-work-2の表示状態を切り替え
      container
          .read(houseWorkVisibilitiesProvider.notifier)
          .toggle(houseWorkId: 'house-work-2');

      // 状態が更新されたことを確認
      visibilities = container.read(houseWorkVisibilitiesProvider);
      expect(visibilities['house-work-1'], isFalse);
      expect(visibilities['house-work-2'], isFalse);
      expect(visibilities.containsKey('house-work-3'), isFalse);

      // house-work-1の表示状態を再度切り替え
      container
          .read(houseWorkVisibilitiesProvider.notifier)
          .toggle(houseWorkId: 'house-work-1');

      // 状態が更新されたことを確認
      visibilities = container.read(houseWorkVisibilitiesProvider);
      expect(visibilities['house-work-1'], isTrue);
      expect(visibilities['house-work-2'], isFalse);
      expect(visibilities.containsKey('house-work-3'), isFalse);
    });
  });
}

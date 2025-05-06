import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/features/analysis/analysis_presenter.dart';

void main() {
  group('家事の表示状態', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('初期は、すべての家事がデフォルト（表示）状態であること', () {
      final visibilities = container.read(houseWorkVisibilitiesProvider);

      expect(visibilities, isEmpty);
    });

    group('表示状態のトグル', () {
      test('1つの家事をトグルすると、非表示状態になり、再度トグルすると、表示状態になること', () {
        var visibilities = container.read(houseWorkVisibilitiesProvider);

        expect(visibilities, isEmpty);

        container
            .read(houseWorkVisibilitiesProvider.notifier)
            .toggle(houseWorkId: 'house-work-1');

        visibilities = container.read(houseWorkVisibilitiesProvider);

        expect(visibilities['house-work-1'], isFalse);

        container
            .read(houseWorkVisibilitiesProvider.notifier)
            .toggle(houseWorkId: 'house-work-1');

        visibilities = container.read(houseWorkVisibilitiesProvider);

        expect(visibilities['house-work-1'], isTrue);
      });

      test('2つの家事をトグルすると、それぞれが独立して非表示状態と表示状態になること', () {
        var visibilities = container.read(houseWorkVisibilitiesProvider);

        expect(visibilities, isEmpty);

        container
            .read(houseWorkVisibilitiesProvider.notifier)
            .toggle(houseWorkId: 'house-work-1');
        container
            .read(houseWorkVisibilitiesProvider.notifier)
            .toggle(houseWorkId: 'house-work-2');

        visibilities = container.read(houseWorkVisibilitiesProvider);

        expect(visibilities['house-work-1'], isFalse);
        expect(visibilities['house-work-2'], isFalse);

        container
            .read(houseWorkVisibilitiesProvider.notifier)
            .toggle(houseWorkId: 'house-work-1');

        visibilities = container.read(houseWorkVisibilitiesProvider);

        expect(visibilities['house-work-1'], isTrue);
        expect(visibilities['house-work-2'], isFalse);
      });
    });

    group('フォーカスとアンフォーカス', () {
      test('家事をフォーカスすると、フォーカスした家事が表示状態となり、それ以外の家事が非表示状態になること', () {
        // TODO(ide): 実装
      });
    });
  });
}

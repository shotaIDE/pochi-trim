import 'package:logging/logging.dart';

enum Flavor { emulator, dev, prod }

final Flavor flavor = _getFlavor();

Flavor _getFlavor() {
  final logger = Logger('Flavor');

  const flavorString = String.fromEnvironment('FLUTTER_APP_FLAVOR');
  final flavor = Flavor.values.firstWhere(
    (value) => value.name == flavorString,
    orElse:
        () =>
            throw UnimplementedError(
              'Flavor "$flavorString" is not implemented',
            ),
  );

  logger.info('Detected flavor: ${flavor.name}');

  return flavor;
}

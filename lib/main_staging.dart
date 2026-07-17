import 'package:poms/configs/flavor/staging_flavor_config.dart';

import 'package:poms/main.dart' as runner;

Future<void> main() async {
  final config = StagingFlavorConfig();

  runner.main(flavorConfig: config);
}

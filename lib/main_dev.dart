import 'package:poms/configs/flavor/dev_flavor_config.dart';

import 'package:poms/main.dart' as runner;

Future<void> main() async {
  final config = DevFlavorConfig();

  runner.main(flavorConfig: config);
}

import 'package:poms/configs/flavor/prod_flavor_config.dart';

import 'package:poms/main.dart' as runner;

Future<void> main() async {
  final config = ProdFlavorConfig();

  runner.main(flavorConfig: config);
}

import 'package:poms/configs/flavor/flavor_config.dart';

class DevFlavorConfig implements FlavorConfig {
  static const String _rawApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const int _rawApiConnectTimeout = int.fromEnvironment(
    'API_CONNECT_TIMEOUT',
    defaultValue: 3000,
  );
  static const int _rawApiReceiveTimeout = int.fromEnvironment(
    'API_RECEIVE_TIMEOUT',
    defaultValue: 60000,
  );

  @override
  String get appName => 'POMS';

  @override
  String get bundleId => 'com.poms.app';

  @override
  String get apiBaseUrl {
    if (_rawApiBaseUrl.isEmpty) {
      return 'http://localhost:3000';
    }
    return _rawApiBaseUrl;
  }

  @override
  int get apiConnectTimeout => _rawApiConnectTimeout;

  @override
  int get apiReceiveTimeout => _rawApiReceiveTimeout;
}

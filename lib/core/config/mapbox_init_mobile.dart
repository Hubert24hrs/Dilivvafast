import 'package:dilivvafast/core/config/app_config.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxInit {
  static void init() {
    final accessToken = AppConfig.instance.mapboxAccessToken;
    if (accessToken.isNotEmpty) {
      MapboxOptions.setAccessToken(accessToken);
    }
  }
}

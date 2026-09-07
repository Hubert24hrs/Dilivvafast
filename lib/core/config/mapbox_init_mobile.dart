import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:dilivvafast/core/config/app_config.dart';

class MapboxInit {
  /// Must be called AFTER `dotenv.load()`, otherwise the token reads back
  /// empty and every map tile request fails with a 401. `main()` orders these
  /// deliberately.
  static void init() {
    final token = AppConfig.instance.mapboxAccessToken;
    if (token.isEmpty) {
      debugPrint(
        '[Dilivvafast] MAPBOX_ACCESS_TOKEN is not set in .env — maps will not render.',
      );
      return;
    }
    MapboxOptions.setAccessToken(token);
  }
}

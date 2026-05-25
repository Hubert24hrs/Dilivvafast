import 'package:fast_delivery/core/constants/app_constants.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxInit {
  static void init() {
    MapboxOptions.setAccessToken(AppConstants.mapboxAccessToken);
  }
}

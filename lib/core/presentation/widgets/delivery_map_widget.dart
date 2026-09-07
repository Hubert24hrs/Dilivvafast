import 'package:flutter/material.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

/// A reusable delivery map widget that shows pickup/dropoff markers
/// and an optional driver location marker with route visualization.
///
/// Uses a lightweight custom-painted map visualization. For production,
/// swap internals with Mapbox or Google Maps when API key is configured.
class DeliveryMapWidget extends StatelessWidget {
  const DeliveryMapWidget({
    super.key,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.driverLat,
    this.driverLng,
    this.pickupLabel = 'Pickup',
    this.dropoffLabel = 'Dropoff',
    this.height = 200,
    this.showRoute = true,
    this.interactive = false,
    this.onPickupTap,
    this.onDropoffTap,
  });

  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final double? driverLat;
  final double? driverLng;
  final String pickupLabel;
  final String dropoffLabel;
  final double height;
  final bool showRoute;
  final bool interactive;
  final VoidCallback? onPickupTap;
  final VoidCallback? onDropoffTap;

  bool get _hasPickup => pickupLat != null && pickupLng != null;
  bool get _hasDropoff => dropoffLat != null && dropoffLng != null;
  bool get _hasDriver => driverLat != null && driverLng != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.palette.brand.withValues(alpha: 0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Map background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D1B2A),
                  Color(0xFF1B2838),
                  Color(0xFF0D1B2A),
                ],
              ),
            ),
            child: CustomPaint(
              size: Size.infinite,
              painter: _MapGridPainter(lineColor: context.palette.border),
            ),
          ),

          // Route line
          if (showRoute && _hasPickup && _hasDropoff)
            CustomPaint(
              size: Size.infinite,
              painter: _RoutePainter(
                routeColor: context.palette.brand,
                hasDriver: _hasDriver,
              ),
            ),

          // Markers
          if (_hasPickup || _hasDropoff || _hasDriver)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_hasDriver) _buildDriverMarker(context),
                  const Spacer(),
                  Row(
                    children: [
                      if (_hasPickup)
                        Expanded(
                          child: GestureDetector(
                            onTap: onPickupTap,
                            child: _buildLocationPin(context, 
                              label: pickupLabel,
                              color: const Color(0xFF4CAF50),
                              icon: Icons.radio_button_checked,
                              lat: pickupLat!,
                              lng: pickupLng!,
                            ),
                          ),
                        ),
                      if (_hasPickup && _hasDropoff)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_forward,
                            color: context.palette.textMuted,
                            size: 16,
                          ),
                        ),
                      if (_hasDropoff)
                        Expanded(
                          child: GestureDetector(
                            onTap: onDropoffTap,
                            child: _buildLocationPin(context, 
                              label: dropoffLabel,
                              color: const Color(0xFFFF5252),
                              icon: Icons.flag,
                              lat: dropoffLat!,
                              lng: dropoffLng!,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

          // Empty state
          if (!_hasPickup && !_hasDropoff)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map,
                      size: 32,
                      color: context.palette.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    interactive
                        ? 'Tap to select location'
                        : 'No locations set',
                    style: TextStyle(
                        color: context.palette.textMuted,
                        fontSize: 12),
                  ),
                ],
              ),
            ),

          // Mapbox badge
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '© Mapbox',
                style: TextStyle(
                    color: context.palette.textSecondary, fontSize: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPin(BuildContext context, {
    required String label,
    required Color color,
    required IconData icon,
    required double lat,
    required double lng,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
                Text(
                  '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                  style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 8),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverMarker(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.palette.brand.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: context.palette.brand.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.palette.brand,
              ),
            ),
            const SizedBox(width: 6),
            Text('Driver Location',
                style: TextStyle(
                    color: context.palette.brand,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Text(
              '${driverLat!.toStringAsFixed(3)}, ${driverLng!.toStringAsFixed(3)}',
              style: TextStyle(
                  color: context.palette.textSecondary, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid lines painter for the map background
class _MapGridPainter extends CustomPainter {
  _MapGridPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    // Horizontal lines
    for (var y = 0.0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical lines
    for (var x = 0.0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

/// Route line painter
class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.hasDriver, required this.routeColor});

  final bool hasDriver;
  final Color routeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = routeColor.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Curved route from left-bottom to right-bottom
    path.moveTo(size.width * 0.15, size.height * 0.75);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * (hasDriver ? 0.2 : 0.35),
      size.width * 0.85,
      size.height * 0.75,
    );

    // Draw dashed line
    final dashPath = Path();
    const dashLength = 8.0;
    const dashGap = 5.0;
    var distance = 0.0;

    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        dashPath.addPath(
            metric.extractPath(distance, end), Offset.zero);
        distance += dashLength + dashGap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

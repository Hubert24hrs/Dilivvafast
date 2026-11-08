// Renders Play Store phone screenshots (1080 x 1920, 9:16) of real app
// screens with sample data. Not part of the normal test suite:
//
//   flutter test tool/store_screenshots_test.dart --dart-define=FONTS_DIR=<dir>
//
// FONTS_DIR must hold Outfit-400/500/600/700/800.ttf (the files google_fonts
// downloads for the app) and materialicons-regular.otf. Output goes to
// build/store_screenshots/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dilivvafast/core/domain/entities/bank_account.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';
import 'package:dilivvafast/features/booking/presentation/screens/matching_screen.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_bid.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';
import 'package:dilivvafast/features/courier/presentation/screens/orders_screen.dart';
import 'package:dilivvafast/features/driver/presentation/screens/driver_bank_account_screen.dart';
import 'package:dilivvafast/features/rating/presentation/screens/rating_screen.dart';

const _fontsDir = String.fromEnvironment('FONTS_DIR');
final _shot = GlobalKey();

Future<void> _loadFonts() async {
  ByteData read(String name) =>
      ByteData.sublistView(File('$_fontsDir/$name').readAsBytesSync());
  final outfit = [
    for (final w in [400, 500, 600, 700, 800]) read('Outfit-$w.ttf'),
  ];
  // google_fonts names its families Outfit_regular, Outfit_500, … Load every
  // weight into each so a bold run inside a regular family is real bold.
  for (final family in [
    'Outfit_regular',
    'Outfit_500',
    'Outfit_600',
    'Outfit_700',
    'Outfit_800',
    'Roboto',
  ]) {
    final loader = FontLoader(family);
    for (final f in outfit) {
      loader.addFont(Future.value(f));
    }
    await loader.load();
  }
  // Text with no font family (e.g. button labels that override the theme's
  // text style) and glyphs Outfit lacks (the ₦ sign) fall back to the
  // platform font on a phone — Roboto on Android. The test engine's fallback
  // family is FlutterTest, so Roboto is loaded there.
  final fallback = FontLoader('FlutterTest');
  for (final w in ['regular', 'medium', 'bold', 'black']) {
    fallback.addFont(Future.value(read('roboto-$w.ttf')));
  }
  await fallback.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(read('materialicons-regular.otf')));
  await icons.load();
}

CourierOrderModel _order(
  String id,
  OrderStatus status, {
  String from = '14 Admiralty Way, Lekki Phase 1',
  String to = '23 Adeola Odeku St, Victoria Island',
  double fare = 1500,
  int daysAgo = 0,
  PaymentMethod pay = PaymentMethod.transfer,
}) {
  final at = DateTime.now().subtract(Duration(days: daysAgo, hours: 2));
  return CourierOrderModel(
    id: id,
    userId: 'c1',
    driverId: status == OrderStatus.pending ? null : 'd1',
    status: status,
    pickupAddress: from,
    pickupGeoPoint: const GeoPoint(6.4479, 3.4737),
    dropoffAddress: to,
    dropoffGeoPoint: const GeoPoint(6.4281, 3.4219),
    packageDescription: 'Documents',
    recipientName: 'Ada Okafor',
    recipientPhone: '+2348031234567',
    estimatedDistanceKm: 7.4,
    estimatedDurationMin: 28,
    trackingCode: 'DLV-${id.toUpperCase()}',
    offeredFare: fare,
    recommendedFare: 1700,
    totalFare: fare,
    paymentMethod: pay,
    deliveredAt: status == OrderStatus.delivered ? at : null,
    createdAt: at,
    updatedAt: at,
  );
}

UserModel _courier() => UserModel(
  uid: 'd1',
  fullName: 'Musa Bello',
  email: 'courier@example.com',
  phone: '+2348030000000',
  referralCode: 'MUSA2026',
  rating: 4.9,
  totalDeliveries: 812,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  vehicleType: 'motorcycle',
  vehiclePlate: 'LAG-482KJ',
  payoutAccount: const BankAccount(
    bankName: 'GTBank',
    accountNumber: '0123456789',
    accountName: 'Musa Bello',
  ),
);

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.runAsync(() async {
    final boundary =
        _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('build/store_screenshots/$name.png')
      ..createSync(recursive: true);
    out.writeAsBytesSync(png!.buffer.asUint8List());
  });
}

Future<void> _show(
  WidgetTester tester,
  Widget screen,
  List<dynamic> overrides,
) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      // ignore: argument_type_not_assignable
      overrides: overrides.cast(),
      child: RepaintBoundary(
        key: _shot,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: screen,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('1 courier offers', (tester) async {
    final order = _order('o1', OrderStatus.pending, fare: 1500);
    final bids = [
      const CourierBid(
        driverId: 'd1',
        amount: 1500,
        status: BidStatus.open,
        etaMinutes: 4,
        driverName: 'Musa',
        driverRating: 4.9,
        driverTrips: 812,
        vehicleLabel: 'Motorcycle',
        vehiclePlate: 'LAG-482KJ',
      ),
      const CourierBid(
        driverId: 'd2',
        amount: 1700,
        status: BidStatus.open,
        etaMinutes: 3,
        driverName: 'Tunde',
        driverRating: 4.8,
        driverTrips: 356,
        vehicleLabel: 'Motorcycle',
        vehiclePlate: 'LAG-219FE',
      ),
      const CourierBid(
        driverId: 'd3',
        amount: 1800,
        status: BidStatus.open,
        etaMinutes: 6,
        driverName: 'Chidi',
        driverRating: 4.95,
        driverTrips: 1204,
        vehicleLabel: 'Motorcycle',
        vehiclePlate: 'KJA-773AA',
      ),
    ];
    await _show(tester, const MatchingScreen(orderId: 'o1'), [
      orderStreamProvider('o1').overrideWith((ref) => Stream.value(order)),
      orderBidsProvider('o1').overrideWith((ref) => Stream.value(bids)),
    ]);
    await _capture(tester, '1_courier_offers');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('2 rate your courier', (tester) async {
    await _show(tester, const RatingScreen(orderId: 'o1'), []);
    await tester.tap(find.byTooltip('5 stars'));
    await tester.pump();
    await tester.tap(find.text('Fast delivery'));
    await tester.tap(find.text('Careful with the package'));
    await tester.tap(find.text('Polite'));
    await tester.pump();
    await _capture(tester, '2_rate_courier');
  });

  testWidgets('3 courier bank account', (tester) async {
    await _show(tester, const DriverBankAccountScreen(), [
      currentUserIdProvider.overrideWithValue('d1'),
      currentUserProvider.overrideWith((ref) => Stream.value(_courier())),
    ]);
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, '3_courier_bank_account');
  });

  testWidgets('4 request history', (tester) async {
    final orders = [
      _order('a7', OrderStatus.inTransit, fare: 1600),
      _order(
        'b3',
        OrderStatus.delivered,
        fare: 1400,
        daysAgo: 1,
        from: '3 Broad St, Lagos Island',
        to: '5 Admiralty Way, Lekki',
      ),
      _order(
        'c9',
        OrderStatus.delivered,
        fare: 2200,
        daysAgo: 3,
        from: 'Ikeja City Mall, Ikeja',
        to: '12 Awolowo Rd, Ikoyi',
        pay: PaymentMethod.cash,
      ),
      _order(
        'd2',
        OrderStatus.delivered,
        fare: 1300,
        daysAgo: 6,
        from: 'Yaba Tech, Yaba',
        to: 'Surulere, Lagos',
        pay: PaymentMethod.cash,
      ),
    ];
    await _show(tester, const OrdersScreen(), [
      customerOrdersProvider.overrideWith((ref) => Stream.value(orders)),
    ]);
    await _capture(tester, '4_request_history');
  });
}

import 'package:json_annotation/json_annotation.dart';

/// The three product surfaces a signed-in person can move between.
///
/// Registration always creates a [customer]; [driver] and [investor] are
/// unlocked afterwards from the drawer and are gated on [ModeAccess.approved].
/// [admin] is internal and never selectable from the client.
enum AppMode {
  @JsonValue('customer')
  customer,
  @JsonValue('driver')
  driver,
  @JsonValue('investor')
  investor,
  @JsonValue('admin')
  admin;

  /// Modes a customer can request from the drawer.
  static const switchable = [AppMode.customer, AppMode.driver, AppMode.investor];

  String get label => switch (this) {
        AppMode.customer => 'Customer',
        AppMode.driver => 'Driver',
        AppMode.investor => 'Investor',
        AppMode.admin => 'Admin',
      };

  String get tagline => switch (this) {
        AppMode.customer => 'Send packages across Nigeria',
        AppMode.driver => 'Earn by delivering on your route',
        AppMode.investor => 'Fund bikes and earn passive income',
        AppMode.admin => 'Manage the platform',
      };

  String get homeRoute => switch (this) {
        AppMode.customer => '/customer/home',
        AppMode.driver => '/driver/home',
        AppMode.investor => '/investor/home',
        AppMode.admin => '/admin/dashboard',
      };

  /// Route prefix used to decide which mode a location belongs to.
  String get routePrefix => switch (this) {
        AppMode.customer => '/customer',
        AppMode.driver => '/driver',
        AppMode.investor => '/investor',
        AppMode.admin => '/admin',
      };
}

/// How far a person has progressed towards being allowed into a mode.
///
/// Only the backend (admin console or Cloud Function) may move a user to
/// [approved]; the client can request, which writes [pending].
enum ModeAccess {
  @JsonValue('none')
  none,
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
  @JsonValue('suspended')
  suspended;

  bool get isApproved => this == ModeAccess.approved;
  bool get isPending => this == ModeAccess.pending;

  String get label => switch (this) {
        ModeAccess.none => 'Not enrolled',
        ModeAccess.pending => 'Under review',
        ModeAccess.approved => 'Active',
        ModeAccess.rejected => 'Declined',
        ModeAccess.suspended => 'Suspended',
      };
}

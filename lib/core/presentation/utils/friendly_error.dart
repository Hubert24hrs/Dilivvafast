import 'dart:async';
import 'dart:io' show SocketException;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// A message safe to show a customer or driver for any error.
///
/// Screens used to render `'Error: $e'`, which put raw Firebase exceptions in
/// front of users — `[cloud_firestore/permission-denied] Missing or
/// insufficient permissions`, or a missing-index error that embeds an
/// internal console URL. The underlying error is still logged for debugging.
String friendlyError(Object error) {
  debugPrint('friendlyError: $error');

  if (error is SocketException || error is TimeoutException) {
    return "You're offline or the connection is slow. Please try again.";
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' || 'unauthenticated' =>
        "You don't have access to this. Try signing in again.",
      'unavailable' || 'deadline-exceeded' || 'network-request-failed' =>
        "You're offline or the connection is slow. Please try again.",
      'not-found' => 'That item no longer exists.',
      'resource-exhausted' => 'Too many requests. Please wait a moment.',
      _ => 'Something went wrong. Please try again.',
    };
  }
  return 'Something went wrong. Please try again.';
}

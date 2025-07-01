// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tripthread/main.dart';
import 'package:tripthread/services/storage_service.dart';
import 'package:tripthread/services/api_service.dart';
import 'package:tripthread/services/trip_service.dart';
import 'package:tripthread/services/connectivity_service.dart';

class MockStorageService implements StorageService {}

class MockApiService implements ApiService {}

class MockTripService implements TripService {}

class MockConnectivityService extends ConnectivityService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasInternetConnection() async => true;

  @override
  ConnectivityResult get connectionStatus => ConnectivityResult.wifi;

  @override
  void dispose() {}
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      TripThreadApp(
        storageService: MockStorageService(),
        apiService: MockApiService(),
        tripService: MockTripService(),
        connectivityService: MockConnectivityService(),
      ),
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

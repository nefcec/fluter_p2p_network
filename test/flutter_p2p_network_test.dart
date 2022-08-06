import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_p2p_network/flutter_p2p_network.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_p2p_network');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('onStart', () async {
    P2pNetWork p2pNetWork = P2pNetWork();
    expect(
        await p2pNetWork.onStart(
            bootId: "",
            bootAddress: "",
            keyPath: "",
            onReceived: ({
              required Uint8List data,
              required int length,
              required int messageId,
              required String remotePeerId,
            }) {}),
        '42');
  });
}

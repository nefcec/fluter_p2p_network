import 'package:flutter/services.dart';
import 'package:flutter_p2p_network/src/flutter_p2p_network.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(
        await P2pNetWork.onStart(
          bootId: "",
          bootAddress: "",
          keyPath: "",
        ),
        '42');
  });
}

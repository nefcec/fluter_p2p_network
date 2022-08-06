import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class PeerState {
  final String id;
  final String address;
  final int uptime;
  final ReachAbility reachAbility;

  PeerState(this.id, this.address, this.uptime, this.reachAbility);
}

enum ReachAbility {
  reachAbilityUnknown,

  reachAbilityPublic,

  reachAbilityPrivate,
}

class P2pNetWork {
  static const String pluginName = 'co.yangdong.p2pnetwork';
  static const String onReceivedEvent = '$pluginName.onReceived';
  static const String onStartMethod = '$pluginName.onStart';
  static const String onStopMethod = '$pluginName.onStop';
  static const String onRequestMethod = '$pluginName.onRequest';

  static const String onStartErrorCode = '$pluginName.ON_START_ERROR';
  static const String onStopErrorCode = '$pluginName.ON_STOP_ERROR';
  static const String onRequestErrorCode = '$pluginName.ON_REQUEST_ERROR';

  P2pNetWork();

  final MethodChannel _methodChannel = const MethodChannel(pluginName);

  final EventChannel _receivedEventChannel =
      const EventChannel(onReceivedEvent);
  StreamSubscription? _receivedEventSubscription;

  Future<PeerState> onStart({
    required String bootId,
    required String bootAddress,
    required String keyPath,
    required void Function({
      required String remotePeerId,
      required int length,
      required int messageId,
      required Uint8List data,
    })
        onReceived,
  }) async {
    _receivedEventSubscription =
        _receivedEventChannel.receiveBroadcastStream().listen((event) {
      String remotePeerId = event["remotePeerId"];
      int length = event["length"];
      int messageId = event["messageId"];
      Uint8List data = event["data"];
      onReceived(
        remotePeerId: remotePeerId,
        length: length,
        messageId: messageId,
        data: data,
      );
    });
    final result = await _methodChannel.invokeMethod(onStartMethod, {
      "bootId": bootId,
      "bootAddress": bootAddress,
      "keyPath": keyPath,
    });
    String id = result["id"];
    String address = result["address"];
    int uptime = result["uptime"];
    int reachAbility = result["reachAbility"];
    return PeerState(id, address, uptime, ReachAbility.values[reachAbility]);
  }

  Future<void> onRequest({
    required String peerId,
    required int messageId,
    required Uint8List data,
  }) async {
    return await _methodChannel.invokeMethod(onRequestMethod, {
      "peerId": peerId,
      "messageId": messageId,
      "data": data,
    });
  }

  Future<void> onStop() async {
    await _methodChannel.invokeMethod(onStopMethod);
    _receivedEventSubscription?.cancel();
    _receivedEventSubscription = null;
  }
}

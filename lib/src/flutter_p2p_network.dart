import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_p2p_network/src/config.dart';

class PeerState {
  final String id;
  final String address;
  final int uptime;
  final ReachAbility reachAbility;

  PeerState(this.id, this.address, this.uptime, this.reachAbility);
}

abstract class PeerListener {
  void onMessage({
    required String remotePeerId,
    required int length,
    required Uint8List data,
  });
}

enum ReachAbility {
  reachAbilityUnknown,

  reachAbilityPublic,

  reachAbilityPrivate,
}

class P2pNetWork {
  P2pNetWork._internal();

  factory P2pNetWork() => _instance;

  static late final P2pNetWork _instance = P2pNetWork._internal();

  final MethodChannel _methodChannel = const MethodChannel(pluginName);

  final EventChannel _onMessageEventChannel =
      const EventChannel(onMessageEvent);
  StreamSubscription? _onMessageEventSubscription;

  final List<PeerListener> _listeners = [];

  Future<PeerState> _onStart({
    required String bootId,
    required String bootAddress,
    required String keyPath,
  }) async {
    final result = await _methodChannel.invokeMethod(onStartMethod, {
      "bootId": bootId,
      "bootAddress": bootAddress,
      "keyPath": keyPath,
    });
    String id = result["id"];
    String address = result["address"];
    int uptime = result["uptime"];
    int reachAbility = result["reachAbility"];
    _onMessage();
    return PeerState(id, address, uptime, ReachAbility.values[reachAbility]);
  }

  Future<void> _sendMessage({
    required String peerId,
    required Uint8List data,
  }) {
    return _methodChannel.invokeMethod(sendMessageMethod, {
      "peerId": peerId,
      "data": data,
    });
  }

  void _addPeerListener(PeerListener listener) {
    _listeners.add(listener);
  }

  Future<void> _onStop() async {
    await _methodChannel.invokeMethod(onStopMethod);
    _onMessageEventSubscription?.cancel();
    _onMessageEventSubscription = null;
  }

  Future<void> _onMessage() async {
    _onMessageEventSubscription =
        _onMessageEventChannel.receiveBroadcastStream().listen((event) {
      String remotePeerId = event["remotePeerId"];
      int length = event["length"];
      Uint8List data = event["data"];
      for (final listener in _listeners) {
        listener.onMessage(
          remotePeerId: remotePeerId,
          length: length,
          data: data,
        );
      }
    });
  }

  /// 启动P2P
  ///
  /// [bootId] bootId
  /// [bootAddress] bootAddress
  /// [keyPath] 私钥存放路径
  static Future<PeerState> onStart({
    required String bootId,
    required String bootAddress,
    required String keyPath,
  }) =>
      _instance._onStart(
          bootId: bootId, bootAddress: bootAddress, keyPath: keyPath);

  /// 发送消息
  ///
  /// [peerId] 节点地址
  /// [data] 消息
  static Future<void> sendMessage({
    required String peerId,
    required Uint8List data,
  }) =>
      _instance._sendMessage(peerId: peerId, data: data);

  /// 添加监听
  static void addPeerListener(PeerListener listener) =>
      _instance._addPeerListener(listener);

  /// 停止P2P
  static Future<void> onStop() => _instance._onStop();
}

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_p2p_network/src/config.dart';

class NodeInfo {
  final String nodeId;
  final String address;
  final int uptime;
  final ReachAbility reachAbility;

  NodeInfo({
    required this.nodeId,
    required this.address,
    required this.uptime,
    required this.reachAbility,
  });
}

abstract class OnMessageListener {
  void onMessage(MessageInfo message) {}
}

// abstract class OnP2pStateChangeListener {
//   void onPeerStateChange(NodeInfo state) {}
// }

// class P2pStateListener extends OnP2pStateChangeListener {
//   void Function(NodeInfo state)? onStateChanged;
//
//   P2pStateListener(this.onStateChanged);
//
//   @override
//   void onPeerStateChange(NodeInfo state) {
//     onStateChanged?.call(state);
//   }
// }

// abstract class PeerListener {
//   void onMessage(MessageData message) {}
//
//   void onFindClients(List<String> list) {}
//
//   void onPeerStateChange(PeerState state) {}
// }

enum ReachAbility {
  reachAbilityUnknown(0),
  reachAbilityPublic(1),
  reachAbilityPrivate(2);

  final int value;
  const ReachAbility(this.value);

  static ReachAbility fromInt(int value) {
    return ReachAbility.values.firstWhere((e) => e.value == value);
  }
}

class Test {
  final RootIsolateToken rootIsolateToken;
  final MethodChannel methodChannel;
  Test(
    this.rootIsolateToken,
    this.methodChannel,
  );
}

class P2pNetWork {
  P2pNetWork._internal();

  factory P2pNetWork() => _instance;

  static late final P2pNetWork _instance = P2pNetWork._internal();

  final MethodChannel _methodChannel = const MethodChannel(pluginName);

  final EventChannel _onMessageEventChannel =
      const EventChannel(onMessageEvent);
  StreamSubscription? _onMessageEventSubscription;

  final EventChannel _onFindClientsEventChannel =
      const EventChannel(onFindClientsEvent);
  StreamSubscription? _onFindClientsSubscription;

  final EventChannel _onPeerStateChangeEventChannel =
      const EventChannel(onPeerStateChangeEvent);
  StreamSubscription? _onPeerStateChangeSubscription;

  // final List<PeerListener> _listeners = [];

  final Map<int, OnMessageListener> _onMessageListeners = {};
  // final Map<int, OnP2pStateChangeListener> _onPeerStateChangeListeners = {};

  void _setOnMessageListener() {
    _onMessageEventSubscription =
        _onMessageEventChannel.receiveBroadcastStream().listen((event) {
      String remoteId = event["remoteId"];
      int length = event["length"];
      Uint8List data = event["data"];
      for (final key in _onMessageListeners.keys) {
        _onMessageListeners[key]?.onMessage(
          MessageInfo(
            remoteId: remoteId,
            length: length,
            data: data,
          ),
        );
      }
    });
  }

  Future<NodeInfo> _onStart({
    required String bootId,
    required String bootAddress,
    required String keyPath,
  }) async {
    // _onMessage();
    // _onFindClients();
    // _onPeerStateChange();
    _setOnMessageListener();
    final node = await _methodChannel.invokeMethod(onStartMethod, {
      "bootId": bootId,
      "bootAddress": bootAddress,
      "keyPath": keyPath,
    });

    return NodeInfo(
      nodeId: node["nodeId"],
      address: node["address"],
      uptime: node["uptime"],
      reachAbility: ReachAbility.fromInt(node["reachAbility"]),
    );
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

  Future<void> _onStartReceiveMessage() {
    return _methodChannel.invokeMethod(onStartReceiveMessageMethod);
  }

  // void _addPeerListener(PeerListener listener) {
  //   _listeners.add(listener);
  // }

  void _addOnMessageListener(OnMessageListener listener) {
    _onMessageListeners[listener.hashCode] = listener;
  }

  void _removeOnMessageListener(OnMessageListener listener) {
    _onMessageListeners.remove(listener.hashCode);
  }

  // void _addOnP2pStateChangeListener(OnP2pStateChangeListener listener) {
  //   _onPeerStateChangeListeners[listener.hashCode] = listener;
  // }
  //
  // void _removeOnP2pStateChangeListener(OnP2pStateChangeListener listener) {
  //   _onPeerStateChangeListeners.remove(listener.hashCode);
  // }

  Future<void> _onStop() async {
    await _methodChannel.invokeMethod(onStopMethod);
    _onMessageEventSubscription?.cancel();
    _onMessageEventSubscription = null;
    _onFindClientsSubscription?.cancel();
    _onFindClientsSubscription = null;
    _onPeerStateChangeSubscription?.cancel();
    _onPeerStateChangeSubscription = null;
  }

  // Future<void> _onFindClients() async {
  //   _onFindClientsSubscription =
  //       _onFindClientsEventChannel.receiveBroadcastStream().listen((event) {
  //     for (final listener in _listeners) {
  //       final clients = FindClientsData.fromBuffer(event);
  //       listener.onFindClients(clients.list);
  //     }
  //   });
  // }

  // Future<void> _onPeerStateChange() async {
  //   _onPeerStateChangeSubscription =
  //       _onPeerStateChangeEventChannel.receiveBroadcastStream().listen((event) {
  //     // bool connected = event["connected"];
  //     String id = event["id"];
  //     String address = event["address"];
  //     int uptime = event["uptime"];
  //     int reachAbility = event["reachAbility"];
  //     for (final key in _onPeerStateChangeListeners.keys) {
  //       _onPeerStateChangeListeners[key]?.onPeerStateChange(
  //           Node(id, address, uptime, ReachAbility.values[reachAbility]));
  //     }
  //   });
  // }

  /// 启动P2P
  ///
  /// [bootId] bootId
  /// [bootAddress] bootAddress
  /// [keyPath] 私钥存放路径
  static Future<NodeInfo> onStart({
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
  // static void addPeerListener(PeerListener listener) =>
  //     _instance._addPeerListener(listener);

  static void addOnMessageListener(OnMessageListener listener) =>
      _instance._addOnMessageListener(listener);

  static void removeOnP2pMessageListener(OnMessageListener listener) =>
      _instance._removeOnMessageListener(listener);

  // static void addOnP2pStateChangeListener(OnP2pStateChangeListener listener) =>
  //     _instance._addOnP2pStateChangeListener(listener);
  //
  // static void removeOnP2pStateChangeListener(
  //         OnP2pStateChangeListener listener) =>
  //     _instance._removeOnP2pStateChangeListener(listener);

  /// 停止P2P
  static Future<void> onStop() => _instance._onStop();

  /// 开始接收消息
  static Future<void> onStartReceiveMessage() =>
      _instance._onStartReceiveMessage();
}

class MessageInfo {
  final String remoteId;
  final int length;
  final Uint8List data;

  const MessageInfo({
    required this.remoteId,
    required this.length,
    required this.data,
  });
}

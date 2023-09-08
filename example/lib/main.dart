import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_p2p_network/p2p.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with PeerListener {
  @override
  void initState() {
    super.initState();
  }

  Future<void> onStart() async {
    try {
      Directory dir = await getApplicationDocumentsDirectory();
      String keyPath = dir.path;

      P2pNetWork.addPeerListener(this);
      final peerState = await P2pNetWork.onStart(
        bootId: "12D3KooWAKzXfMEHicYoLWe2G3MuLJpcLAyjJmyiu4ZEZmd63sTB",
        bootAddress: "/dns4/yangdong.co/tcp/25556",
        keyPath: keyPath,
      );
      print("==========================================>");
      print(peerState.id);
      print(peerState.address);
      print(peerState.uptime);
      print(peerState.reachAbility);
      print("==========================================>");
    } catch (e) {
      // print(e);
    }
  }

  Future<void> onRequest() async {
    try {
      List<String> peerIds = [
        "12D3KooWMCqtKcxmLmKjwkkRsCBtJxiH2r1N9HBHnb77zUdmZ7sm",
        "12D3KooWG88KDHPJwGwZzvyrjkAoTnJC46mtUS9xEaVf1MbsTiy8"
      ];
      List<int> data = utf8.encode("你好啊，你看到这条消息了吗？");
      await P2pNetWork.sendMessage(
        peerId: peerIds[1],
        data: Uint8List.fromList(data),
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              OutlinedButton(
                onPressed: () {
                  onStart();
                },
                child: const Text("启动"),
              ),
              OutlinedButton(
                onPressed: () {
                  onRequest();
                },
                child: const Text("发送消息"),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void onMessage(
      {required String remotePeerId,
      required int length,
      required Uint8List data}) {
    print(remotePeerId);
    print(length);
    print(utf8.decode(data));
  }
}

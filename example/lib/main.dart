import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter_p2p_network/flutter_p2p_network.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  P2pNetWork p2p = P2pNetWork();

  @override
  void initState() {
    super.initState();
  }

  Future<void> onStart() async {
    try {
      Directory dir = await getApplicationDocumentsDirectory();
      String keyPath = dir.path;

      final peerState = await p2p.onStart(
          bootId: "12D3KooWAKzXfMEHicYoLWe2G3MuLJpcLAyjJmyiu4ZEZmd63sTB",
          bootAddress: "/dns4/yangdong.co/tcp/25556",
          keyPath: keyPath,
          onReceived: ({
            required String remotePeerId,
            required int length,
            required int messageId,
            required Uint8List data,
          }) {
            print(remotePeerId);
            print(length);
            print(messageId);
            print(utf8.decode(data));
          });
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
      await p2p.onRequest(
        peerId: peerIds[1],
        messageId: 111,
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
}

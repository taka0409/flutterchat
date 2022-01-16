import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/provider.dart';
import 'room.dart';
import 'entry.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'チャットアプリ',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final roomIdProvider = StateProvider((ref) => '0000');

    return Scaffold(
      appBar: AppBar(
        title: Text('チャットアプリ'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(20),
              child: ElevatedButton(
                child: const Text('部屋を作る'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.orange,
                  onPrimary: Colors.white,
                ),
                onPressed: () async {
                  QuerySnapshot snap = await FirebaseFirestore.instance
                      .collection('rooms').doc('1111').collection('messages')
                      .orderBy('time')
                      .get(); // データ
                  final tmp = [];
                  snap.docs.forEach((element) {
                    tmp.add(Card(
                      child: Text(
                        element.get('message'),
                        style: TextStyle(
                          fontSize: 30,
                        ),
                      ),
                    ));
                    context.read(messagesProvider).state = tmp;
                  });
                  context.read(roomIdProvider).state = '1111';
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Room()
                      )
                  );
                },
              ),
            ),
            Container(
              child: ElevatedButton(
                child: const Text('部屋に入る'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.orange,
                  onPrimary: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Entry()
                      )
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
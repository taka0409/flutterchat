import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

class Room extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final roomIdProvider = StateProvider((ref) => '1111');
    final roomId = watch(roomIdProvider).state;
    late String message;
    final _form = GlobalKey<FormState>();
    final TextEditingController _textEditingController = new TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: Text(roomId),
        ),
      body: Column(
        children: [
          Expanded(
              child: SingleChildScrollView(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    messages(roomId)
                  ],
                )
              )
          ),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey
                )
              )
            ),
            child: Row(
              children: [
                Container(
                    margin: EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 10
                    ),
                    child: Icon(
                      Icons.photo_outlined,
                      color: Colors.blue,
                    )
                ),
                Container(
                    margin: EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 10
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.blue
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(
                      Icons.gif,
                      color: Colors.blue,
                    )
                ),
                Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey
                        ),
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white30
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 10
                      ),
                      child: Form(
                        key: _form,
                        child: TextFormField(
                          controller: _textEditingController,
                          style: TextStyle(
                            fontSize: 20.0,
                            color: Colors.black,
                          ),
                          onSaved: (value) {
                            message = value!;
                          },
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '新しいメッセージを作成'
                          ),
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                        ),
                      )
                    )
                ),
                Container(
                    padding: EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 10
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        _form.currentState!.save();
                        FirebaseFirestore.instance
                            .collection('rooms').doc(roomId).collection('messages')
                            .add({
                          'message':message,
                          'sender':'saka@i.com',
                          'time': DateTime.now(),
                        });
                        _textEditingController.clear();
                      },
                    )
                )
              ],
            ),
          )
        ]
      ),
    );
  }
}

Widget messages(roomId) {
  return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection('rooms').doc(roomId).collection('messages')
        .orderBy('time').snapshots(),
    builder: (BuildContext context,
        AsyncSnapshot<QuerySnapshot> snap) {
          final List<Widget> tmp = [];
          final ret = Column(
              children: tmp
          );
          TextMessage();
          snap.data!.docs.forEach((element) {
            tmp.add(Card(
              child: Text(
                element.get('message'),
                style: TextStyle(
                  fontSize: 30,
                ),
              ),
            ));
          });
          return ret;
        }
  );
}
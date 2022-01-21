import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/size_config.dart';
import 'package:intl/intl.dart';

final _auth = FirebaseAuth.instance;
final _db = FirebaseFirestore.instance;

class Room extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final user = _auth.currentUser;
    final roomIdProvider = StateProvider((ref) => '1111');
    final roomId = watch(roomIdProvider).state;
    late String message;
    final _form = GlobalKey<FormState>();
    final TextEditingController _textEditingController =
        new TextEditingController();
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(roomId),
      ),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(child: messages(roomId))),
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey))),
          child: Row(
            children: [
              Container(
                  margin: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  child: Icon(
                    Icons.photo_outlined,
                    color: Colors.grey,
                  )),
              Container(
                  margin: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(
                    Icons.gif,
                    color: Colors.grey,
                  )),
              Flexible(
                  child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.white30),
                      padding:
                          EdgeInsets.symmetric(vertical: 0, horizontal: 10),
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
                              hintText: '新しいメッセージを作成'),
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                        ),
                      ))),
              Container(
                  padding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      _form.currentState!.save();
                      _db
                          .collection('rooms')
                          .doc(roomId)
                          .collection('messages')
                          .add({
                        'message': message,
                        'sender': user!.email,
                        'time': DateTime.now(),
                      });
                      _textEditingController.clear();
                    },
                  ))
            ],
          ),
        )
      ]),
    );
  }
}

Widget messages(roomId) {
  return StreamBuilder(
      stream: messagesStream(roomId),
      builder: (BuildContext context, AsyncSnapshot<List<MessageInfo>> snap) {
        final List<Widget> tmp = [];
        final ret = Column(children: tmp);
        final userNameMap = {};
        final user = _auth.currentUser;

        if (!snap.hasData) {
          return ret;
        }

        var befDate = '';
        var befTime = '';
        var nowDate = '';
        var nowTime = '';
        DateFormat outputDate = DateFormat('yyyy-MM-dd');
        DateFormat outputTime = DateFormat('hh:mm');
        var befSender = '';
        var nowSender = '';

        snap.data!.forEach((element) {

          var isMyMessage = element.sender == user!.email;
          var nowDateTime = element.time.toDate();
          nowDate = outputDate.format(nowDateTime);
          nowTime = outputTime.format(nowDateTime);
          nowSender = element.sender;
          if (!userNameMap.containsKey(element.name)) {
            userNameMap[element.sender] = element.name;
          }
          if (nowDate != befDate) {
            tmp.add(dateMessageWidget(nowDate));
          }
          if (befSender != nowSender && !isMyMessage) {
            tmp.add(nameMessageWidget(userNameMap[nowSender]));
          }
          if (nowSender != befSender || befTime != nowTime) {
            tmp.add(myMessageWidget(isMyMessage, element.message, nowTime));
          } else {
            tmp.add(myMessageWidget(isMyMessage, element.message, ''));
          }
          befDate = nowDate;
          befTime = nowTime;
          befSender = nowSender;
        });
        return ret;
      });
}

Widget myMessageWidget(isMyMessage, content, time) {
  if (isMyMessage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        timeMessageWidget(time),
        ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: SizeConfig.blockSizeHorizontal * 70),
            child: Container(
              padding: EdgeInsets.all(5),
              child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  color: Colors.blue,
                  child: Padding(
                      padding: EdgeInsets.all(5),
                      child: SelectableText(content,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                          )))),
            ))
      ],
    );
  } else {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: SizeConfig.blockSizeHorizontal * 70),
            child: Container(
                padding: EdgeInsets.all(5),
                child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    color: Colors.grey[200],
                    child: Padding(
                        padding: EdgeInsets.all(5),
                        child: SelectableText(content,
                            style: TextStyle(
                              fontSize: 30,
                            )))))),
        timeMessageWidget(time)
      ],
    );
  }
}

Widget dateMessageWidget(date) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: Colors.grey[300],
          child: Padding(
              padding: EdgeInsets.all(5),
              child: Text(date,
                  style: TextStyle(
                    fontSize: 20,
                  ))))
    ],
  );
}

Widget timeMessageWidget(time) {
  return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 5
      ),
      child:SelectableText(
      time,
      style: TextStyle(
          fontSize: 15
      ))
  );
}

Widget nameMessageWidget(name) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Padding(
          padding: EdgeInsets.symmetric(
            vertical: 5,
            horizontal: 10
          ),
          child: Text(name ?? 'none',
              style: TextStyle(
                fontSize: 15,
              )))
    ]
  );
}

class MessageInfo {
  late String sender;
  late String name;
  late String message;
  late Timestamp time;

  MessageInfo(sender, name, message, time) {
    this.sender = sender;
    this.name = name;
    this.message = message;
    this.time = time;
  }
}

Future<MessageInfo> generateMessageInfo(QueryDocumentSnapshot message) async {
  var name = await getUserData(message.get('sender'));
  return MessageInfo(message.get('sender'),name,message.get('message'),message.get('time'));
}
Stream<List<MessageInfo>> messagesStream(roomId) {
  return _db
    .collection('rooms')
    .doc(roomId)
    .collection('messages')
    .orderBy('time')
    .snapshots()
    .asyncMap((messages) => Future.wait([for (var message in messages.docs) generateMessageInfo(message)]));
}

Future<String> getUserData(nowSender) async {
  var doc = await _db.collection('users').doc(nowSender).get();
  var name = await doc.get('name');
  return Future<String>.value(name);
}
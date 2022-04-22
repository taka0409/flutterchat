import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/size_config.dart';
import 'package:intl/intl.dart';

final _auth = FirebaseAuth.instance;
final _db = FirebaseFirestore.instance;
final _storage = FirebaseStorage.instance;

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
                  )
              )
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
      builder: (BuildContext context, AsyncSnapshot<List<BaseMessageInfo>> snap) {
        final List<Widget> tmp = [];
        final ret = Column(children: tmp);
        final userNameMap = {};
        final user = _auth.currentUser;

        if (!snap.hasData) {
          return ret;
        }

        var befDate = '';
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
          if (element is TextMessageInfo) {
            tmp.add(bubbleMessageWidget(isMyMessage, textMessageWidget(element.message), nowTime));
          } else if (element is ImageMessageInfo) {
            tmp.add(bubbleMessageWidget(isMyMessage, element.image, nowTime));
          }
          befDate = nowDate;
          befSender = nowSender;
        });
        return ret;
      });
}
Widget bubbleMessageWidget(isMyMessage, content, time) {
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
                      child: content
                  )
              ),
            )
        )
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
                        child: content
                    )
                ),
            )
        ),
        timeMessageWidget(time)
      ],
    );
  }
}

Widget textMessageWidget(text) {
  return SelectableText(text,
      style: TextStyle(
        fontSize: 30,
      ));
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

class BaseMessageInfo {
  late String sender;
  late String name;
  late Timestamp time;

  BaseMessageInfo(String sender, String name, Timestamp time) {
    this.sender = sender;
    this.name = name;
    this.time = time;
  }
}

class TextMessageInfo extends BaseMessageInfo {
  late String message;

  TextMessageInfo(String sender, String name, Timestamp time, String message): super(sender, name, time) {
    this.message = message;
  }
}

class ImageMessageInfo extends BaseMessageInfo {
  late Image image = Image(
    image: NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg'),
  );

  ImageMessageInfo(String sender, String name, Timestamp time, Image image) : super(sender, name, time) {
    this.image = image;
  }
}

Future<BaseMessageInfo> generateMessageInfo(QueryDocumentSnapshot<Map<String, dynamic>> message, roomId) async {
  var messageData = message.data();
  var doc = await _db.collection('users').doc(message.get('sender')).get();
  var nickName = await doc.get('name');
  bool? isImage = false;
  if(messageData.containsKey('isImage')) {
    isImage = await message.get('isImage');
  }

  if (isImage != null && isImage) {
    final fileName = message.id;
    final filePath = "images/" + roomId + "/" + fileName;
    final String url = await _storage.ref(filePath).getDownloadURL();
    final image = new Image(image: new CachedNetworkImageProvider(url));
    return ImageMessageInfo(message.get('sender'), nickName, message.get('time'), image);
  } else {
    return TextMessageInfo(message.get('sender'), nickName, message.get('time'), message.get('message'));
  }
}

Stream<List<BaseMessageInfo>> messagesStream(roomId) {
  return _db
    .collection('rooms')
    .doc(roomId)
    .collection('messages')
    .orderBy('time')
    .snapshots()
    .asyncMap((messages) => Future.wait([for (var message in messages.docs) generateMessageInfo(message, roomId)]));
}

Future<String> getUserData(nowSender) async {
  var doc = await _db.collection('users').doc(nowSender).get();
  var name = await doc.get('name');
  return Future<String>.value(name);
}
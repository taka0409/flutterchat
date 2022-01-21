import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/room.dart';

class Entry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    late String roomId;
    final roomIdProvider = StateProvider((ref) => '0000');
    final _form = GlobalKey<FormState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('entry'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(bottom: 20),
              width: 200,
              child: Form(
                key: _form,
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: '部屋ID'),
                  onSaved: (value) {
                    roomId = value!;
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'テキストを入力してください。';
                    }
                    if (value.length != 4) {
                      return '4桁で入力してください。';
                    }
                  }
                ),
              )
              ),
            Container(
              padding: EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                child: const Text('部屋に入る'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.orange,
                  onPrimary: Colors.white,
                ),
                onPressed: () {
                  if (_form.currentState!.validate()) {
                    _form.currentState!.save();
                    context.read(roomIdProvider).state = roomId;
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Room()
                        )
                    );
                  }
                },
              ),
            ),
          ]
        ),
      ),
    );
  }
}

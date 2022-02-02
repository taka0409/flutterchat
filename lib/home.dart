import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/provider.dart';
import 'entry.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'チャットアプリ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    late String mailAddress;
    late String password;
    late String nickName;
    final _form = GlobalKey<FormState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('チャットアプリ'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              HomeAlertMessageWidget(),
              Form(
                key: _form,
                child: Column(
                  children: [
                    TextFormField(
                        decoration: const InputDecoration(labelText: "ニックネーム(新規登録のみ)"),
                        onSaved: (value) {
                          nickName = value!;
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'テキストを入力してください。';
                          }
                          var maxLength = 10;
                          if (value.length > maxLength) {
                            return '最大' + maxLength.toString() + '文字で入力してください';
                          }
                        }
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "メールアドレス"),
                      onSaved: (value) {
                        mailAddress = value!;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "パスワード(6文字以上)"),
                      obscureText: true,
                      onSaved: (value) {
                        password = value!;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        _form.currentState!.save();
                        try {
                          await FirebaseAuth.instance.signInWithEmailAndPassword(
                            email: mailAddress,
                            password: password,
                          );
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Entry()
                              )
                          );
                        } catch (e) {
                          // ログインに失敗した場合
                          context.read(homeAlertMessageProvider).state = e.toString();
                        }
                      },
                      child: Text("ログイン"),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        _form.currentState!.save();
                        try {
                          await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                            email: mailAddress,
                            password: password,
                          );
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(mailAddress)
                              .set({
                            'image': '',
                            'name': nickName,
                          });
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Entry()
                              )
                          );
                        } catch (e) {
                          // ログインに失敗した場合
                          context.read(homeAlertMessageProvider).state = e.toString();
                        }
                      },
                      child: const Text("新規登録"),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class HomeAlertMessageWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final alertMessage = watch(homeAlertMessageProvider).state;
    return Text(
      alertMessage,
      style: TextStyle(
        fontSize: 20,
        color: Colors.red,
      )
    );
  }
}
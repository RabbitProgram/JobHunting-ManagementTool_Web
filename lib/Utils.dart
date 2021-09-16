import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jobhunting_managementtool/signin.dart';

import 'main.dart';

class Utils {
  //SHA-256でハッシュ化
  static String toSHA256(String text) {
    var bytes = utf8.encode(text);
    var digest = sha256.convert(bytes);
    return digest.toString(); //ハッシュ値を返す
  }

  // Googleアカウントを使ってサインイン
  static Future<UserCredential> SignIn_Google() async {
    // 認証フローのトリガー
    final googleUser = await GoogleSignIn(scopes: [
      'email',
    ]).signIn();
    // リクエストから、認証情報を取得
    final googleAuth = await googleUser?.authentication;
    // クレデンシャルを新しく作成
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    // サインインしたら、UserCredentialを返す
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  //サインアウト
  static Future<void> SignOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    try {
      await googleSignIn.signOut();

      loginUser = null;

      //サインイン画面に移動
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SigninPage(),
          ));
    } catch (e) {
      print(e);
    }
  }
}

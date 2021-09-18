import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'main.dart';

class Utils {
  //企業IDからロゴ画像のURLを調べる
  static Future<String> GetLogoURL(String id) async {
    String url = "";

    //ロゴ画像がアップロードされているかどうかを確認
    try {
      Reference imageRef = storage.ref().child("logo").child(id + ".png");
      url = await imageRef.getDownloadURL();
    } catch (e) {}

    return url;
  }

  //現在の状態（進捗状況）の番号を表示用の文字列に変換
  static String State_to_String(int state) {
    switch (state) {
      case 0:
        return "検討中";
      case 1:
        return "エントリー済み";
      case 2:
        return "選考中";
      case 3:
        return "辞退";
      case 4:
        return "お祈り";
      case 5:
        return "内定";
      default:
        return "";
    }
  }

  //現在の状態（進捗状況）の番号を色に変換
  static Color State_to_Color(int state) {
    switch (state) {
      case 0:
        return Colors.yellowAccent;
      case 1:
        return Colors.lightGreenAccent;
      case 2:
        return Colors.lightBlueAccent;
      case 3:
        return Colors.purpleAccent;
      case 4:
        return Colors.pinkAccent;
      case 5:
        return Colors.redAccent;
      default:
        return Colors.white;
    }
  }

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
      //→main.dartのinitState()に記述しているサインアウト検知プログラムで処理される
    } catch (e) {
      print(e);
    }
  }
}

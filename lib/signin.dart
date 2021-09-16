import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

import 'Toasts.dart';
import 'Utils.dart';
import 'main.dart';
import 'overlay_loading_molecules.dart';

class SigninPage extends StatefulWidget {
  @override
  State createState() => SigninPageState();
}

class SigninPageState extends State<SigninPage> {
  bool _isVisibleLoading = false; //ローディングアニメーション表示

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false, //中央寄せを解除
        title: Text(
          AppTitle,
          style: TextStyle(color: Colors.black87),
        ),
      ),
      body: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          overflow: Overflow.clip,
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        child: Column(
                          children: [
                            Container(
                                height: 200,
                                child: Image.asset('images/icon.png')),
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20.0)),
                            Text(
                              "サインインして\nタスクを登録してみましょう",
                              style: TextStyle(
                                fontSize: 25,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 30.0)),
                            SignInButton(
                              Buttons.Google,
                              onPressed: () async {
                                //ローディングアニメーションを表示
                                setState(() {
                                  _isVisibleLoading = true;
                                });

                                try {
                                  final userCredential =
                                      await Utils.SignIn_Google();
                                  loginUser = userCredential.user;
                                } on Exception catch (e) {
                                  loginUser = null;
                                }

                                //ローディングアニメーションを非表示
                                setState(() {
                                  _isVisibleLoading = false;
                                });

                                if (loginUser == null) {
                                  //エラーの場合
                                  Toasts.ErrorToast_Show(context,
                                      "サインイン時にエラーが発生しました", Icons.warning);
                                } else {
                                  Toasts.SafeToast_Show(
                                      context, "サインインしました", Icons.info_outline);

                                  //メイン画面に移動
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MainPage(),
                                      ));
                                }
                              },
                            ),
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 30.0)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  "Copyright (C) 2015-2021 RabbitProgram All Rights Reserved.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                Padding(padding: const EdgeInsets.symmetric(vertical: 8.0)),
              ],
            ),
            //ローディングアニメーション
            OverlayLoadingMolecules(visible: _isVisibleLoading)
          ],
        ),
      ),
    );
  }
}

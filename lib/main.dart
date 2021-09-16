import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jobhunting_managementtool/signin.dart';

import 'Toasts.dart';
import 'Utils.dart';
import 'overlay_loading_molecules.dart';

String AppTitle = "就活管理ツール for Web";
final auth = FirebaseAuth.instance;
final storage = FirebaseStorage.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();
User? loginUser = null; //ログイン中のアカウント情報（ログインしていない場合はnull）
Random rand = new Random(); //乱数生成用

//各種情報の取得方法
//プロフィール画像：Image.network((loginUser?.photoURL).toString())
//アカウント名　　：(loginUser?.displayName).toString()
//メールアドレス　：(loginUser?.email).toString()

Future<void> main() async {
  /*Firebase用の次の2文は、index.htmlに記入済みのため不要
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();*/

  setUrlStrategy(PathUrlStrategy());

  runApp(JHMTapp());
}

class JHMTapp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //日本語化
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale("en"),
        const Locale("ja"),
      ],
      locale: Locale('ja', 'JP'),
      title: AppTitle,
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  State createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isVisibleLoading = true; //ローディングアニメーション表示

  @override
  void initState() {
    super.initState();

    auth.authStateChanges().listen((User? u) {
      if (u == null) {
        //ログアウトした場合 or 起動時にログインしていない状態だった場合→サインイン画面に移動
        loginUser = null;
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SigninPage(),
            ));
        print("ログインしていません");
      } else {
        //ログインした場合 or 起動時にログイン済みの状態だった場合
        loginUser = auth.currentUser;
        print("ログインしました：" + (loginUser?.displayName).toString());

        //データ読み込み

      }

      //表示を更新
      setState(() {
        _isVisibleLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false, //中央寄せを解除
        title: Text(
          AppTitle,
          style: TextStyle(color: Colors.black87),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.upload_file,
              color: Colors.pink,
            ),
            tooltip: "アップロードテスト",
            onPressed: () => setState(() async {
              //try {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['jpg', 'jpeg', 'png'],
              );

              if (result != null) {
                PlatformFile file = result.files.first;
                //ファイルサイズ（単位はbyte）：file.size

                if ((file.size / 1024 / 1024) > 5) {
                  //画像サイズが5MBより大きい場合
                  Toasts.ErrorToast_Show(
                      context, "画像サイズが5MBを超えているためアップロードできません", Icons.warning);
                  return;
                }

                //ローディングアニメーションを表示
                setState(() {
                  _isVisibleLoading = true;
                });

                //企業ID生成
                String companyID = Utils.toSHA256("data" +
                    DateTime.now().toString() +
                    rand.nextInt(1000).toString());

                //アップロード
                await storage
                    .ref("logo/$companyID.${file.extension}")
                    .putData(file.bytes!);

                Toasts.SafeToast_Show(
                    context, "画像をアップロードしました", Icons.info_outline);
              }
              /*} catch (e) {
                Toasts.ErrorToast_Show(
                    context, "エラーが発生しました\n" + e.toString(), Icons.warning);
                print(e.toString());
              }*/

              //ローディングアニメーションを非表示
              setState(() {
                _isVisibleLoading = false;
              });
            }),
          ),
          (loginUser == null)
              ? Container()
              : Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: ElevatedButton(
                    child: ClipOval(
                        child: Image.network(
                      (loginUser?.photoURL).toString(),
                      fit: BoxFit.contain,
                    )),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.white, //背景色
                      shape: const CircleBorder(
                          //枠線
                          /*side: BorderSide(
                    color: Colors.white,
                    width: 2,
                    style: BorderStyle.solid,
                  ),*/
                          ),
                    ),
                    onPressed: () {
                      //右側のドロワーを表示
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                  ),
                ),
        ],
      ),
      body: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          overflow: Overflow.clip,
          children: <Widget>[
            SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.pink,
                    ),
                    child: DataTable(
                      showCheckboxColumn: false, //チェックボックスを表示しない
                      dataRowHeight: 116,
                      columns: <DataColumn>[
                        DataColumn(label: Text('ロゴ')),
                        DataColumn(label: Text('企業名')),
                        DataColumn(label: Text('開始')),
                        DataColumn(label: Text('終了')),
                        DataColumn(label: Text('その他')),
                      ],
                      rows: <DataRow>[
                        DataRow(
                          cells: <DataCell>[
                            DataCell(Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, bottom: 8.0),
                              child: Image.network(
                                  "https://cdn.akamai.steamstatic.com/steam/apps/965470/header.jpg?t=1593155030",
                                  height: 100.0,
                                  width: 200.0,
                                  fit: BoxFit.cover),
                            )),
                            DataCell(Text('月')),
                            DataCell(Text('9:00')),
                            DataCell(Text('18:00')),
                            DataCell(Text('dummy')),
                          ],
                          onSelectChanged: (newValue) {
                            print('row 1 pressed');
                          },
                        ),
                      ],
                    ))),
            /*GridView.count(
              crossAxisCount: 3,
              children: List.generate(50, (index) {
                return Center(
                  child: Text(
                    'Item $index',
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                );
              }),
            ),*/
            //ローディングアニメーション
            OverlayLoadingMolecules(visible: _isVisibleLoading)
          ],
        ),
      ),
      //右から出てくるドロワー
      endDrawer: Drawer(
        child: ListView(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text((loginUser?.displayName).toString()),
              accountEmail: Text((loginUser?.email).toString()),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: NetworkImage((loginUser?.photoURL).toString()),
              ),
            ),
            ListTile(
              title: Text("サインアウト"),
              leading: Icon(Icons.logout),
              onTap: () {
                Navigator.pop(context);

                //サインアウト
                Utils.SignOut(context);
              },
            ),
            ListTile(
              title: Text('Honolulu'),
              onTap: () {
                print("ここに動作を入力");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Dallas'),
              onTap: () {
                print("ここに動作を入力");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Seattle'),
              onTap: () {
                print("ここに動作を入力");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Tokyo'),
              onTap: () {
                print("ここに動作を入力");
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

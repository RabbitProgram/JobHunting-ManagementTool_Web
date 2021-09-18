import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jobhunting_managementtool/signin.dart';
import 'package:url_launcher/url_launcher.dart';

import 'CompanyData.dart';
import 'Utils.dart';
import 'edit.dart';
import 'overlay_loading_molecules.dart';

String AppTitle = "就活管理ツール for Web";
var auth = FirebaseAuth.instance;
var storage = FirebaseStorage.instance;
GoogleSignIn googleSignIn = GoogleSignIn();
User? loginUser = null; //ログイン中のアカウント情報（ログインしていない場合はnull）
Random rand = new Random(); //乱数生成用

//各種情報の取得方法
//プロフィール画像：Image.network((loginUser?.photoURL).toString())
//アカウント名　　：(loginUser?.displayName).toString()
//メールアドレス　：(loginUser?.email).toString()

void main() {
  //Firebase用の次の2文は、index.htmlに記入済みのため不要
  //WidgetsFlutterBinding.ensureInitialized();
  //Firebase.initializeApp();

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
  List<CompanyData> companyList = []; //登録済みの企業情報

  @override
  void initState() {
    super.initState();

    auth.authStateChanges().listen((User? u) async {
      if (u == null) {
        //ログアウトした場合 or 起動時にログインしていない状態だった場合→サインイン画面に移動
        loginUser = null;
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SigninPage(),
            ));
        //print("ログインしていません");

      } else {
        //ログインした場合 or 起動時にログイン済みの状態だった場合
        loginUser = auth.currentUser;
        //print("ログインしました：" + (loginUser?.displayName).toString());

        //データ読み込み
        companyList = [];
        final snapshot = await FirebaseFirestore.instance
            .collection((loginUser?.email).toString())
            .get();
        for (var now in snapshot.docs) {
          CompanyData temp = new CompanyData.Set(now.id, now["name"],
              now["state"], now["address"], now["homepageURL"]);
          temp.logoURL = await Utils.GetLogoURL(now.id);

          companyList.add(temp);
        }
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
          /*IconButton(
              icon: Icon(
                Icons.cloud,
                color: Colors.pink,
              ),
              tooltip: "CloudStore",
              onPressed: () async {}),*/
          //アカウントのプロフィール画像を表示するボタン
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
            (companyList.length == 0)
                ? Center(
                    child: Text(
                    "右下のボタンを押して企業を登録してください",
                    style: TextStyle(color: Colors.black54),
                  ))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                          //dividerColor: Colors.pink,
                          ),
                      child: DataTable(
                        showCheckboxColumn: false, //チェックボックスを表示しない
                        dataRowHeight: 116,
                        columns: <DataColumn>[
                          DataColumn(label: Text('ロゴ')),
                          DataColumn(label: Text('企業名')),
                          DataColumn(label: Text('現在の状態')),
                        ],
                        rows: List.generate(
                          companyList.length,
                          (index) {
                            return DataRow(
                              cells: <DataCell>[
                                DataCell(Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, bottom: 8.0),
                                  child:
                                      (companyList[index].logoURL.length == 0)
                                          ? Image.asset('images/noimage.png',
                                              height: 100.0,
                                              width: 200.0,
                                              fit: BoxFit.contain)
                                          : Image.network(
                                              companyList[index].logoURL,
                                              height: 100.0,
                                              width: 200.0,
                                              fit: BoxFit.contain),
                                )),
                                DataCell(Text(companyList[index].name)),
                                DataCell(Text(
                                  Utils.State_to_String(
                                      companyList[index].state),
                                  style: TextStyle(
                                      fontSize: 20,
                                      backgroundColor: Utils.State_to_Color(
                                          companyList[index].state)),
                                )),
                              ],
                              onSelectChanged: (newValue) async {
                                //編集画面に移動
                                CompanyData data = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => new EditPage(
                                        data: companyList[index],
                                      ),
                                    ));

                                //戻ってきたらここが実行される
                                if (data.id == "-1") {
                                  //削除された場合
                                  companyList.removeAt(index);
                                } else if (data.id.length != 0) {
                                  //1回以上保存した場合→リストを更新して表示を更新
                                  companyList[index] = data;
                                }

                                setState(() {});
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          //編集画面に移動
          CompanyData data = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => new EditPage(
                  data: new CompanyData(),
                ),
              ));

          //戻ってきたらここが実行される
          if (data.id == "-1") {
            //新規登録後に続けて削除された場合→何もしない

          } else if (data.id.length != 0) {
            //1回以上保存した場合→リストに追加して表示を更新
            companyList.add(data);
          }

          setState(() {});
        },
        label: Text('新規登録'),
        icon: Icon(Icons.add),
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
              title: Text('作者のホームページを開く'),
              leading: Icon(Icons.public),
              onTap: () async {
                Navigator.pop(context);

                String url = "https://rabbitprogram.com/";
                if (await canLaunch(url)) {
                  await launch(url);
                }
              },
            ),
            //区切り線
            Divider(
              thickness: 1.25, //厚み
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
          ],
        ),
      ),
    );
  }
}

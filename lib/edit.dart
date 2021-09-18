import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jobhunting_managementtool/CompanyData.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Toasts.dart';
import 'Utils.dart';
import 'main.dart';
import 'overlay_loading_molecules.dart';

//保存FloatingActionButtonの状態保持用
enum _SaveButtonState {
  GONE, //非表示
  VISIBLE, //表示
  WAIT, //保存中
  SAVED, //保存完了
}

class EditPage extends StatefulWidget {
  EditPage({Key? key, required this.data}) : super(key: key);

  CompanyData data; //編集中の企業ID（新規登録の場合は空欄）

  @override
  State createState() => EditPageState();
}

class EditPageState extends State<EditPage> {
  String _appbarTitle = "";
  bool _isVisibleLoading = false; //ローディングアニメーション表示
  _SaveButtonState _saveButton = _SaveButtonState.GONE; //変更された場合はVISIBLE
  List<DropdownMenuItem<int>> _dropdownItems = []; //ドロップダウンリスト
  int _dropdownSelect = 0; //ドロップダウンの選択中要素番号
  late TextEditingController _controller_name; //初期値セット用
  late TextEditingController _controller_address;
  late TextEditingController _controller_homepageURL;
  CompanyData _data_result = new CompanyData(); //返却用
  bool _isEnabled_googlemapopen = true; //Googleマップで開くボタンの状態（true：有効）

  @override
  void initState() {
    super.initState();

    _appbarTitle = (widget.data.id.length == 0) ? "新規登録" : widget.data.name;
    _dropdownSelect = widget.data.state;

    _controller_name = new TextEditingController(text: widget.data.name);
    _controller_address = new TextEditingController(text: widget.data.address);
    _controller_homepageURL =
        new TextEditingController(text: widget.data.homepageURL);

    //ロゴ画像のURLを確認
    Future(() async {
      widget.data.logoURL = await Utils.GetLogoURL(widget.data.id);
      //print("企業ID：" + widget.data.id);
      //print("画像URL：" + widget.data.logoURL);

      setState(() {});
    });

    //ドロップダウンリストを準備
    for (int i = 0; i < 6; i++) {
      _dropdownItems
        ..add(DropdownMenuItem(
          child: Text(
            Utils.State_to_String(i),
            style: TextStyle(
                fontSize: 25, backgroundColor: Utils.State_to_Color(i)),
          ),
          value: i,
        ));
    }
  }

  @override
  void dispose() {
    _controller_name.dispose();
    _controller_address.dispose();
    _controller_homepageURL.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false, //中央寄せを解除
        iconTheme: IconThemeData(color: Colors.pink), //アイコンの色
        title: Text(
          _appbarTitle,
          style: TextStyle(color: Colors.black87),
        ),
        leading: TextButton(
          child: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context, _data_result),
        ),
        actions: <Widget>[
          (widget.data.id.length == 0)
              ? Container()
              : IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.pink,
                  ),
                  tooltip: "削除",
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          title: Text("確認"),
                          content: Text("企業名[${widget.data.name}] を削除しますか？"),
                          actions: <Widget>[
                            // ボタン領域
                            FlatButton(
                              child: Text("はい"),
                              onPressed: () async {
                                Navigator.pop(context);

                                //ローディングアニメーションを表示
                                setState(() {
                                  _isVisibleLoading = true;
                                });

                                try {
                                  await FirebaseFirestore.instance
                                      .collection((loginUser?.email).toString())
                                      .doc(widget.data.id)
                                      .delete();
                                } catch (e) {}
                                try {
                                  await FirebaseStorage.instance
                                      .ref("logo/${widget.data.id}.png")
                                      .delete();
                                } catch (e) {}

                                //ローディングアニメーションを非表示
                                setState(() {
                                  _isVisibleLoading = false;
                                });

                                //前の画面に戻る
                                _data_result.id = "-1"; //削除フラグ
                                Navigator.pop(context, _data_result);
                              },
                            ),
                            FlatButton(
                              child: Text("いいえ"),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        );
                      },
                    );
                  }),
        ],
      ),
      body: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          overflow: Overflow.clip,
          children: <Widget>[
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 20.0, bottom: 10.0, left: 10.0, right: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    /*Container(
                      width: double.infinity,
                      child: Text(
                        "企業情報",
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0)),*/
                    SizedBox(
                      height: 200.0,
                      //width: 400.0,
                      child: ElevatedButton(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                          child: (widget.data.logoURL.length == 0)
                              ? Image.asset('images/noimage.png',
                                  fit: BoxFit.contain)
                              : Image.network(widget.data.logoURL,
                                  fit: BoxFit.contain),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.grey.shade100,
                        ),
                        onPressed: () async {
                          if (widget.data.id.length == 0) {
                            //まだ1度も保存されていない場合
                            Toasts.WarningToast_Show(
                                context,
                                "画像を登録するには、先に企業名を入力して保存ボタンを押してください",
                                Icons.info_outline);
                            return;
                          }

                          try {
                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['jpg', 'jpeg', 'png'],
                            );

                            if (result != null) {
                              PlatformFile file = result.files.first;
                              //ファイルサイズ（単位はbyte）：file.size

                              if ((file.size / 1024 / 1024) > 5) {
                                //画像サイズが5MBより大きい場合
                                Toasts.ErrorToast_Show(
                                    context,
                                    "画像サイズが5MBを超えているためアップロードできません",
                                    Icons.warning);
                                return;
                              }

                              //ローディングアニメーションを表示
                              setState(() {
                                _isVisibleLoading = true;
                              });

                              //アップロード
                              await storage
                                  .ref("logo/${widget.data.id}.png")
                                  .putData(file.bytes!);

                              //ロゴ画像URLを調べる
                              widget.data.logoURL =
                                  await Utils.GetLogoURL(widget.data.id);

                              //表示を更新
                              setState(() {});

                              Toasts.SafeToast_Show(
                                  context, "画像をアップロードしました", Icons.info_outline);
                            }
                          } catch (e) {
                            Toasts.ErrorToast_Show(context,
                                "エラーが発生しました\n" + e.toString(), Icons.warning);
                            print(e.toString());
                          }

                          //ローディングアニメーションを非表示
                          setState(() {
                            _isVisibleLoading = false;
                          });
                        },
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0)),
                    Row(
                      children: [
                        DropdownButton(
                          items: _dropdownItems,
                          value: _dropdownSelect,
                          onChanged: (value) => {
                            setState(() {
                              _dropdownSelect = int.parse(value.toString());
                              setState(() {
                                _saveButton = _SaveButtonState.VISIBLE;
                              });
                            }),
                          },
                        ),
                        Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5.0)),
                        Expanded(
                          child: TextField(
                            controller: _controller_name,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: '企業名',
                            ),
                            onChanged: (text) {
                              widget.data.name = text;
                              setState(() {
                                _saveButton = _SaveButtonState.VISIBLE;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 5.0)),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller_address,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: '住所',
                            ),
                            onChanged: (text) {
                              widget.data.address = text;
                              setState(() {
                                _saveButton = _SaveButtonState.VISIBLE;
                              });
                            },
                          ),
                        ),
                        Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5.0)),
                        ElevatedButton(
                          child: Text('Googleマップで開く'),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.orange,
                            onPrimary: Colors.white,
                          ),
                          onPressed: !_isEnabled_googlemapopen
                              ? null
                              : () async {
                                  //住所をGoogleマップで開く
                                  if (widget.data.address.length != 0) {
                                    setState(() {
                                      _isEnabled_googlemapopen = false;
                                    });

                                    try {
                                      //住所→緯度経度
                                      final response = await http.get(Uri.parse(
                                          'https://rabbitprogram.com/api/geocoding.py?address=${widget.data.address}'));
                                      List location = response.body.split(",");

                                      //緯度経度をもとにGoogleマップで開く
                                      String url =
                                          "https://www.google.com/maps?q=${location[0]},${location[1]}";
                                      await launch(url);
                                    } catch (e) {
                                      Toasts.ErrorToast_Show(
                                          context,
                                          "エラーが発生しました\n" + e.toString(),
                                          Icons.warning);
                                      print(e.toString());
                                    }

                                    setState(() {
                                      _isEnabled_googlemapopen = true;
                                    });
                                  }
                                },
                        ),
                      ],
                    ),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 5.0)),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller_homepageURL,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'ホームページのURL',
                            ),
                            onChanged: (text) {
                              widget.data.homepageURL = text;
                              setState(() {
                                _saveButton = _SaveButtonState.VISIBLE;
                              });
                            },
                          ),
                        ),
                        Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5.0)),
                        ElevatedButton(
                          child: Text('開く'),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.orange,
                            onPrimary: Colors.white,
                          ),
                          onPressed: () async {
                            //URLを開く
                            String url = widget.data.homepageURL;
                            if (await canLaunch(url)) {
                              await launch(url);
                            }
                          },
                        ),
                      ],
                    ),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 5.0)),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0)),
                  ],
                ),
              ),
            ),
            //ローディングアニメーション
            OverlayLoadingMolecules(visible: _isVisibleLoading)
          ],
        ),
      ),
      floatingActionButton: (_saveButton == _SaveButtonState.GONE)
          ? null
          : FloatingActionButton(
              onPressed: (_saveButton != _SaveButtonState.VISIBLE)
                  ? null
                  : () async {
                      if (widget.data.name.length == 0) {
                        Toasts.ErrorToast_Show(
                            context, "企業名を入力してください", Icons.warning);
                        return;
                      }

                      //値を反映
                      widget.data.state = _dropdownSelect;

                      //保存中
                      setState(() {
                        _saveButton = _SaveButtonState.WAIT;
                      });

                      if (widget.data.id.length == 0) {
                        //新規登録の場合→企業IDを生成
                        widget.data.id = Utils.toSHA256("data" +
                            (loginUser?.email).toString() +
                            DateTime.now().toString() +
                            rand.nextInt(1000).toString());
                      }

                      //アップロード
                      await FirebaseFirestore.instance
                          .collection((loginUser?.email).toString()) //メールアドレス
                          .doc(widget.data.id)
                          .set({
                        'name': widget.data.name,
                        'state': widget.data.state,
                        'address': widget.data.address,
                        'homepageURL': widget.data.homepageURL
                      });

                      _data_result = widget.data; //返却用にセット
                      _appbarTitle = widget.data.name; //Appbarの表示を更新

                      //保存完了
                      setState(() {
                        _saveButton = _SaveButtonState.SAVED;
                      });

                      await Future.delayed(Duration(milliseconds: 500)); //待機

                      //保存ボタンを非表示
                      setState(() {
                        _saveButton = _SaveButtonState.GONE;
                      });
                    },
              child: (_saveButton == _SaveButtonState.VISIBLE)
                  ? Icon(Icons.save)
                  : (_saveButton == _SaveButtonState.WAIT)
                      ? Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: CircularProgressIndicator(
                              valueColor: new AlwaysStoppedAnimation<Color>(
                                  Colors.white)),
                        )
                      : Icon(Icons.check),
            ),
    );
  }
}

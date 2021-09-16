import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum _ToastColor { safe, warning, error }

class Toasts {
//安全トーストを表示
  static void SafeToast_Show(BuildContext context, String text, IconData icon) {
    ShowToast(context, text, icon, _ToastColor.safe);
  }

//注意トーストを表示
  static void WarningToast_Show(
      BuildContext context, String text, IconData icon) {
    ShowToast(context, text, icon, _ToastColor.warning);
  }

//警告トーストを表示
  static void ErrorToast_Show(
      BuildContext context, String text, IconData icon) {
    ShowToast(context, text, icon, _ToastColor.error);
  }

//トーストを表示（private）
  static void ShowToast(BuildContext context, String text, IconData icon,
      _ToastColor toastColor) {
    //トーストの色を調べる
    Color color = GetToastColor(toastColor);

    late FToast fToast;
    fToast = FToast();
    fToast.init(context);

    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: color,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
          ),
          SizedBox(
            width: 12.0,
          ),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    //画面右上に表示
    fToast.showToast(
        child: toast,
        toastDuration: Duration(seconds: 3),
        positionedToastBuilder: (context, child) {
          return Positioned(
            child: child,
            top: 76.0,
            right: 16.0,
          );
        });
  }

//トーストの背景色を返すクラス（private）
  static Color GetToastColor(_ToastColor mode) {
    late Color color;

    switch (mode) {
      case _ToastColor.safe:
        color = Colors.greenAccent.shade700;
        break;
      case _ToastColor.warning:
        color = Colors.yellow.shade700;
        break;
      case _ToastColor.error:
        color = Colors.redAccent.shade700;
        break;
    }

    return color;
  }
}

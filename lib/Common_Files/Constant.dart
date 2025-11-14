// ignore_for_file: constant_identifier_names
import 'package:flutter/services.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:flutter/material.dart';
import '../../Common_Files/commonAppColor.dart';
import 'dart:io';

const String kAppName = "Inner-Body Analysis";
const String font_roboto = "Roboto";


class Constant {
  
  static const platform = MethodChannel('com.example.avatardemo/camera');
  
// Check Email is Valid Or Not
  static Future<bool> emailValidation(String emailId) async {
    final bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(emailId);
    return emailValid;
  }

  //This function is using for geet the device languagee
  static String getDeviceLanguageCode() {
    String languageCode = Platform.localeName.split('_')[0];
    if (languageCode == 'ja') {
      return languageCode;
    }
    return 'en';
  }

  static showHideProgressHud(bool show) {
    if (show == true) {
      SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.clear);
      SVProgressHUD.setDefaultStyle(SVProgressHUDStyle.custom);
      SVProgressHUD.setForegroundColor(commonAppColor.appBackgroundColor);
      SVProgressHUD.setBackgroundColor(commonAppColor.yellowColor);
      SVProgressHUD.show();
    } else {
      SVProgressHUD.dismiss();
    }
  }

//For Show Alert Dialog
  static Future<String> displayDialogAlert(BuildContext context, String title,
      String message, String buttonTitleOne, String buttonTitleTwo) async {
    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title,
                  style: const TextStyle(
                      fontFamily: font_roboto,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.normal,
                      fontSize: 20,
                      color: commonAppColor.blackColor)),
              content: Text(message,
                  style: const TextStyle(
                      fontFamily: font_roboto,
                      fontWeight: FontWeight.normal,
                      fontStyle: FontStyle.normal,
                      fontSize: 16,
                      color: commonAppColor.blackColor)),
              actions: <Widget>[
                TextButton(
                  child: Text(buttonTitleOne,
                      style: const TextStyle(
                          fontFamily: font_roboto,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                          fontSize: 20,
                          color: commonAppColor.blackColor)),
                  onPressed: () {
                    Navigator.of(context).pop(buttonTitleOne);
                  },
                ),
                Visibility(
                  visible: (buttonTitleTwo != ''),
                  child: TextButton(
                    child: Text(buttonTitleTwo,
                        style: const TextStyle(
                            fontFamily: font_roboto,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontSize: 20,
                            color: commonAppColor.blackColor)),
                    onPressed: () {
                      Navigator.of(context).pop(buttonTitleTwo);
                    },
                  ),
                )
              ],
            );
          },
        ) ??
        '';
  }

}

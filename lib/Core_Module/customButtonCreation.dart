// ignore_for_file: must_be_immutable
import 'package:webrtc/Common_Files/commonAppColor.dart';
import 'package:flutter/material.dart';

class customButtonCreation extends StatelessWidget {
  final Color backgroundColor;
  final String title;
  final VoidCallback onPressed;
  final Color borderColor;
  final Color textColor;
  String? leftImageName;
  FontWeight? fontWeight = FontWeight.normal;
  String? fontName = "Roboto";
  double? buttonHeight = 50;
  double? buttonFontSize = 16;

  customButtonCreation(
      {super.key, required this.backgroundColor,
      required this.title,
      required this.onPressed,
      required this.borderColor,
      required this.textColor,
      this.leftImageName,
      this.fontWeight,
      this.fontName,
      this.buttonHeight,
      this.buttonFontSize});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: commonAppColor.grayLightColor,
        animationDuration: const Duration(milliseconds: 1000),
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Border radius
            side: BorderSide(color: borderColor, width: 3)),
      ),
      child: SizedBox(
        height: buttonHeight ?? 50.0,
        child:
            Row(mainAxisAlignment: leftImageName != null && title != '' ? MainAxisAlignment.start : MainAxisAlignment.center, children: <Widget>[
          if (leftImageName != null)
            Container(
              height: 30,
              width: 30,
              margin: leftImageName != null && title != '' ? const EdgeInsets.only(right: 10) : const EdgeInsets.only(left: 10, right: 10),
              child: Image.asset(
                leftImageName ?? '',
              ),
            ),
          leftImageName != null && title != '' ? const SizedBox(width: 20) : const SizedBox(width: 0),
          Text(
            title,
            style: TextStyle(
                fontFamily: fontName,
                fontWeight: fontWeight,
                color: textColor,
                fontSize: buttonFontSize),
          ),
        ]),
      ),
    );
  }
}

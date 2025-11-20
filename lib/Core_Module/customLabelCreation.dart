// ignore_for_file: must_be_immutable
import 'package:flutter/material.dart';
import '../Common_Files/commonAppColor.dart';
import '../Common_Files/Constant.dart';

class customLabelCreation extends StatelessWidget {
  final String headingText;
  double? textFontSize = 20;
  String? textFontName = font_roboto;
  FontWeight? textFont = FontWeight.bold;
  customLabelCreation(
      {super.key, required this.headingText, this.textFontSize, this.textFontName, this.textFont});

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(left: 20, right: 20, top: 30),
        padding: const EdgeInsets.only(left: 0, right: 0),
        child: Row(children: [
          Expanded(child: Text(headingText,
            style: TextStyle(
                fontFamily: textFontName,
                fontWeight: textFont,
                fontStyle: FontStyle.normal,
                fontSize: textFontSize,
                color: commonAppColor.blackColor)))
          
        ],));
  }
}

// ignore_for_file: must_be_immutable
import 'package:flutter/material.dart';
import '../Common_Files/commonAppColor.dart';
import '../Common_Files/Constant.dart';

class customTextFieldCreation extends StatelessWidget {
  final TextEditingController controllerTextEditing;
  final String hintText;
  final bool obscureText;
  double? textFontSize = 20;
  String? textFontName = font_roboto;
  TextAlign? textAlignDirection = TextAlign.left; 
  FontWeight? textFont = FontWeight.normal;
  TextInputType? keyBoardType = TextInputType.text;
  final VoidCallback? onTapTextField;
  ValueChanged<String>? onChanged;
  FocusNode? fieldFocusNode = FocusNode();
  int? charlength = 10000;

  customTextFieldCreation(
      {super.key, required this.controllerTextEditing,
      required this.hintText,
      required this.obscureText,
      this.textFontSize,
      this.textAlignDirection,
      this.textFont,
      this.keyBoardType,
      this.onTapTextField,
      this.onChanged,
      this.charlength,
      this.fieldFocusNode,
      this.textFontName});

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(left:20, right: 20, top: 10),
        padding: const EdgeInsets.only(top: 0, right: 0),
        child: TextField(
            controller: controllerTextEditing,
            focusNode: fieldFocusNode,
            showCursor: true,
            maxLength: charlength,
            keyboardType: keyBoardType,
            textAlign: textAlignDirection ?? TextAlign.left,
            decoration: InputDecoration(
                border: InputBorder.none,
                counter: const Offstage(),
                hintStyle: TextStyle(
                    fontFamily: textFontName,
                    fontWeight: textFont,
                    fontStyle: FontStyle.normal,
                    fontSize: textFontSize,
                    color: Colors.grey),
                hintText: hintText),
            onTap: onTapTextField??  () {},
            onChanged: onChanged,
            obscureText: obscureText == true ? true : false,
            obscuringCharacter: '*',
            style: TextStyle(
                fontFamily: textFontName,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.normal,
                fontSize: textFontSize,
                color: commonAppColor.blackColor)));
  }
}

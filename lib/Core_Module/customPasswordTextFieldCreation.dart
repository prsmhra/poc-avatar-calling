// ignore_for_file: must_be_immutable
import 'package:flutter/material.dart';
import '../Common_Files/commonAppColor.dart';
import '../Common_Files/Constant.dart';

class customPasswordTextFieldCreation extends StatelessWidget {
  final TextEditingController controllerTextEditing;
  final String hintText;
  final bool obscureText;
  double? textFontSize = 20;
  String? textFontName = font_roboto;
  final VoidCallback? onButtonPressed;
  String? imageName;

  customPasswordTextFieldCreation(
      {super.key, required this.controllerTextEditing,
      required this.hintText,
      required this.obscureText,
      this.textFontSize,
      this.textFontName,
      this.onButtonPressed,
      this.imageName});

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width - 90,
              child: TextField(
                  controller: controllerTextEditing,
                  showCursor: true,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      counter: const Offstage(),
                      hintStyle: TextStyle(
                          fontFamily: textFontName,
                          fontWeight: FontWeight.normal,
                          fontStyle: FontStyle.normal,
                          fontSize: textFontSize,
                          color: Colors.grey),
                      hintText: hintText),
                  textAlign: TextAlign.left,
                  onTap: () {
                    print('Tap text field');
                  },
                  obscureText: obscureText == true ? true : false,
                  obscuringCharacter: '*',
                  style: TextStyle(
                      fontFamily: textFontName,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.normal,
                      fontSize: textFontSize,
                      color: commonAppColor.blackColor)),
            ),
            SizedBox(
              height: 50,
              width: 50,
              child: IconButton(
                icon: Image.asset(imageName ?? 'assets/Show.png'),
                iconSize: 40,
                onPressed: onButtonPressed ?? () {
                  
                },
              ),
            )
          ],
        ));
  }
}

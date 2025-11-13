import 'package:webrtc/Common_Files/Constant.dart';
import 'package:webrtc/Common_Files/commonAppColor.dart';
import 'package:webrtc/Core_Module/custom360RotationImage.dart';
import 'package:webrtc/Core_Module/customButtonCreation.dart';
import 'package:flutter/material.dart';

// ignore: camel_case_types, must_be_immutable
class alertwarningwidget extends StatelessWidget {
  final String title;
  final String description;
  final String? imageIcon;
  final String? button1Text;
  final String? button2Text;
  final VoidCallback? onButton1Pressed;
  final VoidCallback? onButton2Pressed;
  final VoidCallback? myVoidCallback;
  String? buttonFontName = font_roboto;
  FontWeight? buttonFontWeight = FontWeight.bold;
  FontWeight? decriptionFontWeight = FontWeight.normal;

  alertwarningwidget(
      {super.key, required this.title,
      required this.description,
      this.imageIcon,
      this.button1Text,
      this.button2Text,
      this.onButton1Pressed,
      this.onButton2Pressed,
      this.buttonFontName,
      this.buttonFontWeight,
      this.decriptionFontWeight,
      this.myVoidCallback});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 1000), () {
    // Here you can write your code
        myVoidCallback!();
    });
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: MediaQuery.of(context).size.width - 40,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            color: commonAppColor.grayVeryLightColor,
          ),
          child: Column(
            children: [
              Container(
                  margin: const EdgeInsets.only(left: 20, top: 20, right: 20),
                  child: Image.asset(
                    imageIcon ?? "assets/Reset_PWD_Success.png",
                  )),
              Container(
                  margin: const EdgeInsets.only(left: 20, top: 20, right: 20),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20)),
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                        fontFamily: font_roboto,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                        fontSize: 22,
                        color: commonAppColor.blackColor),
                    child: Text(title, textAlign: TextAlign.center),
                  )),
              Container(
                  margin: const EdgeInsets.only(
                      left: 20, top: 20, right: 20, bottom: 30),
                  child: Align(
                    child: DefaultTextStyle(
                      style: TextStyle(
                          color: commonAppColor.blackColor,
                          fontFamily: font_roboto,
                          fontSize: 14,
                          fontWeight: decriptionFontWeight,
                          height: 1.7),
                      child: Text(description, textAlign: TextAlign.center),
                    ),
                  )),
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(top: 20),
                child: const custom360RotationImage(),
              ),
              Visibility(
                visible: (button1Text != null),
                child: Container(
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: customButtonCreation(
                    title: button1Text ?? "",
                    backgroundColor: Colors.white,
                    borderColor: Colors.black,
                    textColor: Colors.black,
                    onPressed: onButton1Pressed ?? () {},
                    fontWeight: buttonFontWeight,
                    fontName: buttonFontName,
                    buttonFontSize: 20,
                  ),
                ),
              ),
              Visibility(
                visible: (button2Text != null),
                child: Container(
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: customButtonCreation(
                    title: button2Text ?? "",
                    backgroundColor: Colors.white,
                    borderColor: Colors.black,
                    textColor: Colors.black,
                    onPressed: onButton2Pressed ?? () {},
                    fontWeight: buttonFontWeight,
                    fontName: buttonFontName,
                    buttonFontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

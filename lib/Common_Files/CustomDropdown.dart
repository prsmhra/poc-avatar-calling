// ignore_for_file: must_be_immutable
import 'package:webrtc/Common_Files/Constant.dart';
import 'package:webrtc/Common_Files/commonAppColor.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

// ignore: camel_case_types
class customDropDown extends StatelessWidget {
  List<String> items = [];
  final ValueChanged<String?> valueChanged;

  customDropDown({super.key, required this.items, required this.valueChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        items: items
            .map(
              (String item) => DropdownMenuItem<String>(
                value: item,
                alignment: Alignment.center,
                child: Text(
                  item,
                  style: const TextStyle(
                    fontFamily: font_roboto,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                    fontSize: 15,
                    color: commonAppColor.blackColor,
                  ),
                ),
              ),
            )
            .toList(),
        iconStyleData: const IconStyleData(icon: SizedBox.shrink()),
        onChanged: valueChanged,
        menuItemStyleData: const MenuItemStyleData(height: 50),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 300,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
          offset: const Offset(0, -2),
        ),
      ),
    );
  }
}

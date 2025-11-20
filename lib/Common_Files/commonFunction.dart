const String accessKey = "qKQTMitj9zTYTokTCgLgIWtZ2cwEJw2EvUnK2NJLRc";
const String encryptionKey =
    "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEQFlk7Nn7MULhf/yadlMA9QAFdhIHJ14nqY9VS7eOkEsuTSfG26BCvTHFMmBJ8kGYpmchPr9h+jGRjp3VNda/ew==";
const String font_roboto = "Roboto";


class Constant {
// Check Email is Valid Or Not
  static Future<bool> emailValidation(String emailId) async {
    final bool emailValid = 
    RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
      .hasMatch(emailId);
    return emailValid;
  }

}
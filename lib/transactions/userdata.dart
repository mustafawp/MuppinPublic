class UserData {
  final bool success;
  final dynamic data;

  UserData(this.success, this.data);
}

// ignore: camel_case_types
class newUser {
  String docId;
  String accName;
  dynamic profilePhoto;
  String email;
  String password;
  String phone;
  String aboutText;
  String gender;
  String birthday;
  String since;
  String pronouns;
  List badges;
  Map<String, dynamic> socials;

  newUser({
    required this.docId,
    required this.accName,
    required this.profilePhoto,
    required this.email,
    required this.password,
    required this.phone,
    required this.aboutText,
    required this.gender,
    required this.birthday,
    required this.since,
    required this.pronouns,
    required this.badges,
    required this.socials,
  });
}

// ignore: camel_case_types
class searchUserDatas {
  final String username;
  final dynamic pp;
  final String documentId;
  final String about;

  searchUserDatas(
      {required this.username,
      required this.pp,
      required this.documentId,
      required this.about});
}

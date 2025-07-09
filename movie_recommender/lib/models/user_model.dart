class UserModel {
  String uid;
  String name;
  int followingCount = 0;
  int followersCount = 0;

  UserModel({
    required this.uid,
    required this.name,
  });
}
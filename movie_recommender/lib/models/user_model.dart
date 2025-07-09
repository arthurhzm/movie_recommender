class UserModel {
  String uid;
  String name;
  String? photoUrl;
  int followingCount = 0;
  int followersCount = 0;

  UserModel({
    required this.uid,
    required this.name,
    this.photoUrl,
    this.followingCount = 0,
    this.followersCount = 0,
  });
}
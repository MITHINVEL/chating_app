class ChatUser {
  String uid;
  String username;
  String displayName;
  String email;
  String? mobile; // Added mobile number field
  String? photoURL;
  String? bio;
  DateTime createdAt;
  DateTime lastSeen;
  bool isOnline;
  List<String> blockedUsers;

  ChatUser({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.email,
    this.mobile, // Added mobile parameter
    this.photoURL,
    this.bio,
    required this.createdAt,
    required this.lastSeen,
    this.isOnline = false,
    this.blockedUsers = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'displayName': displayName,
      'displayNameLower': displayName.toLowerCase(), // For search
      'email': email,
      'mobile': mobile, // Added mobile to JSON
      'photoURL': photoURL,
      'bio': bio,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'isOnline': isOnline,
      'blockedUsers': blockedUsers,
    };
  }

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'], // Added mobile from JSON
      photoURL: json['photoURL'],
      bio: json['bio'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(json['lastSeen'] ?? 0),
      isOnline: json['isOnline'] ?? false,
      blockedUsers: List<String>.from(json['blockedUsers'] ?? []),
    );
  }

  ChatUser copyWith({
    String? uid,
    String? username,
    String? displayName,
    String? email,
    String? mobile, // Added mobile parameter
    String? photoURL,
    String? bio,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
    List<String>? blockedUsers,
  }) {
    return ChatUser(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile, // Added mobile to copyWith
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }
}

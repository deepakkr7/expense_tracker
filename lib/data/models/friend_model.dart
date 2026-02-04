import 'package:equatable/equatable.dart';

class FriendModel extends Equatable {
  final String id;
  final String userId; // The user who added this friend
  final String friendId; // The friend's user ID
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime addedAt;

  const FriendModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.addedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'friendId': friendId,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  // Create from Firestore Map
  factory FriendModel.fromMap(Map<String, dynamic> map) {
    return FriendModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      friendId: map['friendId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      addedAt: DateTime.parse(map['addedAt']),
    );
  }

  // Copy with method
  FriendModel copyWith({
    String? id,
    String? userId,
    String? friendId,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? addedAt,
  }) {
    return FriendModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    friendId,
    name,
    email,
    photoUrl,
    addedAt,
  ];
}

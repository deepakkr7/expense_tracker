import 'package:equatable/equatable.dart';

class GroupModel extends Equatable {
  final String id;
  final String userId; // Creator of the group
  final String name;
  final String? emoji;
  final List<String> memberIds; // List of friend IDs in this group
  final DateTime createdDate;

  const GroupModel({
    required this.id,
    required this.userId,
    required this.name,
    this.emoji,
    required this.memberIds,
    required this.createdDate,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'emoji': emoji,
      'memberIds': memberIds,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  // Create from Firestore Map
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'],
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdDate: DateTime.parse(map['createdDate']),
    );
  }

  // Copy with method
  GroupModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? emoji,
    List<String>? memberIds,
    DateTime? createdDate,
  }) {
    return GroupModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      memberIds: memberIds ?? this.memberIds,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  @override
  List<Object?> get props => [id, userId, name, emoji, memberIds, createdDate];
}

// Predefined group emojis
class GroupEmojis {
  static const String roommates = '🏠';
  static const String trip = '✈️';
  static const String family = '👨‍👩‍👧‍👦';
  static const String party = '🎉';
  static const String work = '💼';
  static const String friends = '👥';
  static const String custom = '🎯';

  static const List<String> all = [
    roommates,
    trip,
    family,
    party,
    work,
    friends,
    custom,
  ];
}

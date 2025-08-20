class Message {
  final String? id;
  final String? senderId;
  final String? receiverId;
  final String? message;
  final DateTime? createdAt;
  final bool isRead;
  final String? senderName;

  Message({
    this.id,
    this.senderId,
    this.receiverId,
    this.message,
    this.createdAt,
    required this.isRead,
    this.senderName,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String?,
      senderId: json['sender_id'] as String?,
      receiverId: json['receiver_id'] as String?,
      message: json['message'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      isRead: json['is_read'] as bool? ?? false,
      senderName: json['sender_name'] as String? ?? json['users']?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (senderId != null) 'sender_id': senderId,
      if (receiverId != null) 'receiver_id': receiverId,
      if (message != null) 'message': message,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'is_read': isRead,
      if (senderName != null) 'sender_name': senderName,
    };
  }
}
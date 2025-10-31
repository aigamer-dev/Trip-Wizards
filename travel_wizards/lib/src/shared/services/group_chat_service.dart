import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isAiResponse;
  final List<String> mentions;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isAiResponse = false,
    this.mentions = const [],
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAiResponse: data['isAiResponse'] ?? false,
      mentions: List<String>.from(data['mentions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isAiResponse': isAiResponse,
      'mentions': mentions,
    };
  }
}

class GroupChatService {
  GroupChatService._();
  static final GroupChatService instance = GroupChatService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ChatMessage>> getChatMessages(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('chat')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
  }

  Future<void> sendMessage({
    required String tripId,
    required String message,
    bool isAiResponse = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final mentions = _extractMentions(message);
    final shouldTriggerAi = mentions.contains('@ai') || mentions.contains('@wizard');

    final chatMessage = ChatMessage(
      id: '',
      senderId: user.uid,
      senderName: user.displayName ?? 'User',
      message: message,
      timestamp: DateTime.now(),
      isAiResponse: isAiResponse,
      mentions: mentions,
    );

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('chat')
        .add(chatMessage.toMap());

    if (shouldTriggerAi && !isAiResponse) {
      await _generateAiResponse(tripId, message);
    }
  }

  Future<void> _generateAiResponse(String tripId, String userMessage) async {
    try {
      final response = await _callAiService(userMessage);
      
      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('chat')
          .add({
        'senderId': 'ai',
        'senderName': 'Travel Wizard AI',
        'message': response,
        'timestamp': FieldValue.serverTimestamp(),
        'isAiResponse': true,
        'mentions': [],
      });
    } catch (e) {
      debugPrint('Error generating AI response: $e');
    }
  }

  Future<String> _callAiService(String message) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'AI: Based on your message "$message", I suggest exploring destinations that match your interests. Would you like specific recommendations?';
  }

  List<String> _extractMentions(String message) {
    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(message);
    return matches.map((match) => match.group(0)!).toList();
  }

  Future<List<String>> getTripBuddies(String tripId) async {
    try {
      final tripDoc = await _firestore.collection('trips').doc(tripId).get();
      if (tripDoc.exists) {
        final data = tripDoc.data();
        final buddies = data?['buddies'] as List<dynamic>?;
        return buddies?.map((e) => e.toString()).toList() ?? [];
      }
    } catch (e) {
      debugPrint('Error getting trip buddies: $e');
    }
    return [];
  }
}

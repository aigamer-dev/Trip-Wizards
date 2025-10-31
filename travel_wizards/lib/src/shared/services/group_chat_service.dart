import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'encryption_service.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isAiResponse;
  final List<String> mentions;
  final bool isEncrypted;
  final Map<String, dynamic>? encryptedData;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isAiResponse = false,
    this.mentions = const [],
    this.isEncrypted = false,
    this.encryptedData,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isEncrypted = data['isEncrypted'] ?? false;
    
    String displayMessage = data['message'] ?? '';
    
    // Try to decrypt if encrypted
    if (isEncrypted && data['encryptedData'] != null) {
      try {
        final encryptedDataMap = data['encryptedData'] as Map<String, dynamic>;
        displayMessage = '[Encrypted message - decrypting...]';
        // Actual decryption happens asynchronously
        EncryptionService.instance.decryptMessage(encryptedDataMap).then((decrypted) {
          displayMessage = decrypted;
        }).catchError((e) {
          displayMessage = '[Unable to decrypt]';
        });
      } catch (e) {
        displayMessage = '[Decryption error]';
      }
    }
    
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      message: displayMessage,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAiResponse: data['isAiResponse'] ?? false,
      mentions: List<String>.from(data['mentions'] ?? []),
      isEncrypted: isEncrypted,
      encryptedData: data['encryptedData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': FieldValue.serverTimestamp(),
      'isAiResponse': isAiResponse,
      'mentions': mentions,
      'isEncrypted': isEncrypted,
    };
    
    if (isEncrypted && encryptedData != null) {
      map['encryptedData'] = encryptedData;
      map['message'] = '[Encrypted]'; // Placeholder
    } else {
      map['message'] = message;
    }
    
    return map;
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
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String tripId,
    required String message,
    bool isAiResponse = false,
    bool enableEncryption = true,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final mentions = _extractMentions(message);
    final shouldTriggerAi =
        mentions.contains('@ai') || mentions.contains('@wizard');

    // Get trip buddies for encryption
    final buddies = await getTripBuddies(tripId);
    Map<String, dynamic>? encryptedData;
    bool isEncrypted = false;

    // Encrypt message if enabled and there are buddies
    if (enableEncryption && buddies.isNotEmpty) {
      try {
        encryptedData = await EncryptionService.instance.encryptMessage(
          message,
          buddies,
        );
        isEncrypted = true;
      } catch (e) {
        if (kDebugMode) {
          print('Encryption failed, sending unencrypted: $e');
        }
        // Fall back to unencrypted if encryption fails
        isEncrypted = false;
      }
    }

    final chatMessage = ChatMessage(
      id: '',
      senderId: user.uid,
      senderName: user.displayName ?? 'User',
      message: message,
      timestamp: DateTime.now(),
      isAiResponse: isAiResponse,
      mentions: mentions,
      isEncrypted: isEncrypted,
      encryptedData: encryptedData,
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

      await _firestore.collection('trips').doc(tripId).collection('chat').add({
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

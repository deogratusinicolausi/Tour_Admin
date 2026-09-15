import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turiva_admin/services/sound_service.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Get ALL chats (Admin view)
  Stream<List<ChatModel>> getAllChats() {
    return _firestore
        .collection('chats')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.lastMessageAt ?? DateTime(2000);
        final bDate = b.lastMessageAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ⭐️ Get messages
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return aDate.compareTo(bDate);
      });
      return list;
    });
  }

  // ⭐️ Send message (Admin)
  Future<String?> sendMessage({
    required String chatId,
    required String adminId,
    required String adminName,
    required String adminPhoto,
    required String userId,
    required String message,
    String messageType = 'text',
    String imageUrl = '',
  }) async {
    try {
      final ref = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'chatId': chatId,
        'senderId': adminId,
        'senderName': adminName,
        'senderPhoto': adminPhoto,
        'receiverId': userId,
        'message': message,
        'messageType': messageType,
        'imageUrl': imageUrl,
        'fileName': '',
        'fileUrl': '',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update chat
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();
      final currentUnreadUser = chatDoc.data()?['unreadByUser'] ?? 0;

      await chatRef.update({
        'adminId': adminId,
        'adminName': adminName,
        'adminPhoto': adminPhoto,
        'lastMessage': messageType == 'text' ? message : '📷 Photo',
        'lastMessageType': messageType,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadByUser': currentUnreadUser + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ⭐️ Create notification for user
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': '💬 New Message from Admin',
        'body': messageType == 'text' ? message : '📷 Photo',
        'type': 'chat',
        'category': 'info',
        'icon': '💬',
        'actionType': 'open_chat',
        'actionId': chatId,
        'isRead': false,
        'isPushed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return ref.id;
    } catch (e) {
      print('🔥 Error sending message: $e');
      return null;
    }
  }

  // ⭐️ Mark messages as read (Admin)
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in messages.docs) {
        final senderId = (doc.data())['senderId'] ?? '';
        if (senderId != 'admin') {
          await doc.reference.update({
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await _firestore.collection('chats').doc(chatId).update({
        'unreadByAdmin': 0,
      });
    } catch (e) {
      print('🔥 Error marking as read: $e');
    }
  }

  // ⭐️ Set typing
  Future<void> setTyping(String chatId, bool isTyping) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'adminTyping': isTyping,
      });
    } catch (e) {
      print('🔥 Error setting typing: $e');
    }
  }

  // ⭐️ Get total unread
  Stream<int> getTotalUnread() {
    return _firestore.collection('chats').snapshots().map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['unreadByAdmin'] ?? 0) as int;
      }
      return total;
    });
  }

  // ⭐️ Delete chat
  Future<bool> deleteChat(String chatId) async {
    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();
      for (var doc in messages.docs) {
        await doc.reference.delete();
      }
      await _firestore.collection('chats').doc(chatId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Listen for new messages (Sound)
  void listenForNewMessages() {
    bool isFirstLoad = true;

    _firestore
        .collection('chats')
        .snapshots()
        .listen((snapshot) {
      if (isFirstLoad) {
        isFirstLoad = false;
        return;
      }

      // Check if any chat has unreadByAdmin > 0
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data != null && (data['unreadByAdmin'] ?? 0) > 0) {
            SoundService.playByType('chat');
          }
        }
      }
    });
  }
}
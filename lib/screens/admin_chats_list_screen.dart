import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../utils/colors.dart';
import 'admin_chat_detail_screen.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import '../providers/app_theme_provider.dart';
import 'package:provider/provider.dart';

class AdminChatsListScreen extends StatefulWidget {
  const AdminChatsListScreen({super.key});

  @override
  State<AdminChatsListScreen> createState() =>
      _AdminChatsListScreenState();
}

class _AdminChatsListScreenState extends State<AdminChatsListScreen> {
  final _service = ChatService();
  String _filter = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text('💬 ${context.tr('chats')}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // SEARCH + FILTER
          Container(
            padding: EdgeInsets.all(width * 0.04),
            color: AppColors.primary,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: context.tr('search_chats'),
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding:
                      EdgeInsets.symmetric(vertical: height * 0.015),
                    ),
                  ),
                ),
                SizedBox(height: height * 0.015),
                Row(
                  children: [
                    _filterChip('all', '🔔 ${context.tr('all')}'),
                    _filterChip('unread', '🔵 ${context.tr('unread')}'),
                    _filterChip('recent', '🕐 ${context.tr('recent')}'),
                  ],
                ),
              ],
            ),
          ),

          // LIST
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: _service.getAllChats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var chats = snapshot.data ?? [];

                // Filter
                if (_filter == 'unread') {
                  chats = chats.where((c) => c.unreadByAdmin > 0).toList();
                }

                // Search
                if (_searchQuery.isNotEmpty) {
                  chats = chats
                      .where((c) =>
                  c.userName.toLowerCase().contains(_searchQuery) ||
                      c.lastMessage
                          .toLowerCase()
                          .contains(_searchQuery))
                      .toList();
                }

                if (chats.isEmpty) {
                  return _buildEmptyState(width, height);
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.04),
                  itemCount: chats.length,
                  itemBuilder: (context, i) => _buildChatCard(
                    chats[i],
                    width,
                    height,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _filter == value;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        margin: EdgeInsets.only(right: width * 0.02),
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.04, vertical: height * 0.008),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGold
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: width * 0.028,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: width * 0.2, color: Colors.grey.shade300),
          SizedBox(height: height * 0.02),
          Text(
            context.tr('no_chats_yet'),
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(ChatModel chat, double width, double height) {
    final hasUnread = chat.unreadByAdmin > 0;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminChatDetailScreen(
              chatId: chat.id,
              userId: chat.userId,
              userName: chat.userName,
              userPhoto: chat.userPhoto,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: height * 0.012),
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: hasUnread
              ? Border.all(
              color: AppColors.primary.withOpacity(0.3), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: width * 0.07,
              backgroundColor: AppColors.primary,
              backgroundImage: chat.userPhoto.isNotEmpty
                  ? NetworkImage(chat.userPhoto)
                  : null,
              child: chat.userPhoto.isEmpty
                  ? Text(
                chat.userName.isNotEmpty
                    ? chat.userName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white, fontSize: 20),
              )
                  : null,
            ),
            SizedBox(width: width * 0.03),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.04,
                            color: context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        chat.timeAgo,
                        style: TextStyle(
                          color: hasUnread
                              ? AppColors.primary
                              : Colors.grey.shade500,
                          fontSize: width * 0.028,
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.005),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          style: TextStyle(
                            color: hasUnread
                                ? context.textPrimary
                                : Colors.grey.shade500,
                            fontSize: width * 0.032,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: const BoxDecoration(
                            gradient: AppColors.mainGradient,
                            borderRadius:
                            BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Text(
                            '${chat.unreadByAdmin}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
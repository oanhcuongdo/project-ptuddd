import 'package:flutter/material.dart';

class ChatRoomsTab extends StatelessWidget {
  const ChatRoomsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Phân Hệ Chat Realtime (Chat 1-1 & Chat Nhóm Học Tập)',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }
}

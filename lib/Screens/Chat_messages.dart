import 'package:flutter/material.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildChatTile('Alice', 'Hey, is the task still available?', '10:30 AM'),
        _buildChatTile('Bob', 'I have completed the delivery.', 'Yesterday'),
        _buildChatTile('Charlie', 'Can you provide more details?', 'Mon'),
        _buildChatTile('Support', 'Your dispute has been resolved.', 'Sun'),
      ],
    );
  }

  Widget _buildChatTile(String name, String lastMessage, String time) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundImage: AssetImage('assets/images/placeholder_profile.jpg'),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      onTap: () {},
    );
  }
}

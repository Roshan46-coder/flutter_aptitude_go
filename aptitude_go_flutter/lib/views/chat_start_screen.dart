import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'inbox_screen.dart';

class ChatStartScreen extends StatefulWidget {
  const ChatStartScreen({super.key});

  @override
  State<ChatStartScreen> createState() => _ChatStartScreenState();
}

class _ChatStartScreenState extends State<ChatStartScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  void _searchUsers(String query) {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);

    final queryLower = query.toLowerCase();
    final results = <Map<String, dynamic>>[];

    final knownUsers = ['alice', 'bob', 'charlie', 'aptix_bot'];
    for (final name in knownUsers) {
      if (name.contains(queryLower)) {
        results.add({'username': name, 'first_name': name[0].toUpperCase() + name.substring(1), 'last_name': ''});
      }
    }

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _startChat(String username) async {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            conversationId: DateTime.now().millisecondsSinceEpoch,
            otherUsername: username,
          ),
        ),
      ).then((_) => Navigator.pop(context));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Conversation')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a user...',
                prefixIcon: const Icon(Icons.search, color: Colors.white30),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white30),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Type a username to start a conversation'
                              : 'No users found',
                          style: const TextStyle(color: Colors.white30),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.1),
                                child: Text(
                                  (user['username'] as String? ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(color: AppTheme.neonPurple, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                '${user['first_name']} ${user['last_name']}'.trim().isEmpty
                                    ? '@${user['username']}'
                                    : '${user['first_name']} ${user['last_name']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('@${user['username'] ?? ''}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                              trailing: ElevatedButton(
                                onPressed: () => _startChat(user['username']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.neonPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                child: const Text('Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

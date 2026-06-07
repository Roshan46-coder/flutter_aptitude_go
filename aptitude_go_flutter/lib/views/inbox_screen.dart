import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'profile_screen.dart';
import 'candidate_recruiter_view.dart';
import 'chat_start_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInbox();
  }

  Future<void> _fetchInbox() async {
    setState(() { _isLoading = true; _error = null; });
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final response = await api.get('inbox/');
      if (mounted) {
        setState(() {
          _conversations = response.data['conversations'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load inbox.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New Conversation',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatStartScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatStartScreen()),
        ),
        backgroundColor: AppTheme.neonPurple,
        child: const Icon(Icons.add_comment_outlined, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
          : _error != null
              ? Center(child: Text(_error!))
              : _conversations.isEmpty
                  ? const Center(child: Text('No conversations yet.', style: TextStyle(color: Colors.white30)))
                  : RefreshIndicator(
                      onRefresh: _fetchInbox,
                      color: AppTheme.neonPurple,
                      child: ListView.separated(
                        itemCount: _conversations.length,
                        separatorBuilder: (_, _) => const Divider(color: AppTheme.divider, height: 1),
                        itemBuilder: (context, index) {
                          final conv = _conversations[index];
                          final other = conv['other_user'];
                          final lastMsg = conv['last_message'];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.15),
                              backgroundImage: (other != null && other['avatar_url'] != null)
                                  ? NetworkImage(other['avatar_url']) : null,
                              child: (other == null || other['avatar_url'] == null)
                                  ? const Icon(Icons.person, color: AppTheme.neonPurple) : null,
                            ),
                            title: Text(
                              other?['username'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              lastMsg?['content'] ?? 'No messages yet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white38, fontSize: 13),
                            ),
                            trailing: lastMsg != null
                                ? Text(
                                    _formatTime(lastMsg['timestamp']),
                                    style: const TextStyle(color: Colors.white24, fontSize: 11),
                                  )
                                : null,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(
                                  conversationId: conv['conversation_id'],
                                  otherUsername: other?['username'] ?? 'Chat',
                                ),
                              ),
                            ).then((_) => _fetchInbox()),
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      }
      return '${dt.day}/${dt.month}';
    } catch (_) { return ''; }
  }
}

class ChatDetailScreen extends StatefulWidget {
  final int conversationId;
  final String otherUsername;
  const ChatDetailScreen({super.key, required this.conversationId, required this.otherUsername});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  List<dynamic> _messages = [];
  bool _isLoading = true;
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  String? _currentUsername;
  bool _otherIsCompany = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    final api = Provider.of<ApiClient>(context, listen: false);
    _currentUsername = api.currentUser?['username'];
    try {
      final response = await api.get(
        'chat/${widget.conversationId}/',
        queryParameters: {'other_user': widget.otherUsername},
      );
      if (mounted) {
        final otherUser = response.data['other_user'] as Map? ?? {};
        setState(() {
          _messages = response.data['messages'] ?? [];
          _otherIsCompany = otherUser['is_company'] == true;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _msgController.clear();
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final response = await api.post(
        'chat/${widget.conversationId}/send/',
        data: {'content': text, 'other_user': widget.otherUsername},
      );
      if (mounted && response.data['success'] == true) {
        setState(() => _messages.add(response.data['message']));
        _scrollToBottom();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _otherIsCompany
                    ? CandidateRecruiterView(username: widget.otherUsername, recruiterName: widget.otherUsername)
                    : ProfileScreen(username: widget.otherUsername),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.divider,
                child: Icon(Icons.person, size: 16, color: Colors.white54),
              ),
              const SizedBox(width: 10),
              Text(widget.otherUsername, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender'] == _currentUsername;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                          decoration: BoxDecoration(
                            color: isMe ? AppTheme.neonPurple.withValues(alpha: 0.18) : AppTheme.cardBg,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                            border: isMe ? null : Border.all(color: AppTheme.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(msg['content'] ?? '', style: const TextStyle(fontSize: 14, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(msg['timestamp']),
                                style: const TextStyle(fontSize: 10, color: Colors.white30),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.divider)),
              color: AppTheme.surface,
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    fillColor: AppTheme.cardBg,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppTheme.neonPurple),
                onPressed: _sendMessage,
              ),
            ]),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return ''; }
  }
}

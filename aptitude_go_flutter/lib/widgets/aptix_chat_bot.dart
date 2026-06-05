import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../core/hive_database.dart';
import '../core/local_data.dart';

class AptixChatBotSheet extends StatefulWidget {
  const AptixChatBotSheet({super.key});

  @override
  State<AptixChatBotSheet> createState() => _AptixChatBotSheetState();
}

class _AptixChatBotSheetState extends State<AptixChatBotSheet> {
  final List<Map<String, String>> _messages = [
    {'role': 'bot', 'content': 'Hello! I am Aptix, your AI Aptitude mentor. 🧠 Ask me any concepts, but I won\'t give direct answers to live questions! 😉'}
  ];
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  void _loadChatHistory() {
    final cached = HiveDatabase.instance.getCachedChatMessages();
    if (cached.isNotEmpty) {
      setState(() {
        _messages.addAll(cached);
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    // Capture context-dependent objects BEFORE any async gaps
    final api = Provider.of<ApiClient>(context, listen: false);
    final aptixUrl = api.baseUrl.replaceAll('/api/', '/api/aptix/');

    _msgController.clear();
    final Map<String, String> userMsg = {'role': 'user', 'content': text};
    setState(() {
      _messages.add(userMsg);
      _isSending = true;
    });
    _scrollToBottom();

    // Cache the user message immediately in Hive database
    await HiveDatabase.instance.saveChatMessage(userMsg);

    try {
      final response = await api.post(aptixUrl, data: {'message': text});
      if (mounted) {
        setState(() {
          _isSending = false;
          if (response.statusCode == 200 && response.data['success'] == true) {
            final Map<String, String> botMsg = {
              'role': 'bot',
              'content': response.data['response'].toString()
            };
            _messages.add(botMsg);
            HiveDatabase.instance.saveChatMessage(botMsg);
          } else {
            _messages.add({'role': 'bot', 'content': 'Sorry, I encountered an issue. Please try again. 😞'});
          }
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        final localReply = LocalDataProvider.instance.getAptixResponse(text);
        final Map<String, String> botMsg = {
          'role': 'bot',
          'content': localReply,
        };
        setState(() {
          _isSending = false;
          _messages.add(botMsg);
        });
        HiveDatabase.instance.saveChatMessage(botMsg);
        _scrollToBottom();
      }
    }
  }

  void _clearChatHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Clear conversation?"),
        content: const Text("This will permanently delete all chat history with Aptix from this device."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text("Clear"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HiveDatabase.instance.clearChatHistory();
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.add({
            'role': 'bot',
            'content': 'Hello! I am Aptix, your AI Aptitude mentor. 🧠 Ask me any concepts, but I won\'t give direct answers to live questions! 😉'
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewInsets.bottom;

    return Container(
      height: mq.size.height * 0.65 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.neonPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt, color: AppTheme.neonPurple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Aptix",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        "AI Aptitude Mentor",
                        style: TextStyle(color: Colors.white30, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white30),
                  tooltip: "Clear Conversation",
                  onPressed: _clearChatHistory,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const Divider(color: AppTheme.divider),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildLoadingBubble();
                }

                final msg = _messages[index];
                final isBot = msg['role'] == 'bot';
                
                return _buildMessageBubble(
                  isBot: isBot,
                  content: msg['content']!,
                );
              },
            ),
          ),

          // Message input bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Ask Aptix a concept question...",
                      hintStyle: const TextStyle(color: Colors.white30),
                      fillColor: AppTheme.cardBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppTheme.neonPurple),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({required bool isBot, required String content}) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isBot ? AppTheme.cardBg : AppTheme.neonPurple.withValues(alpha: 0.15),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isBot ? 4 : 16),
            bottomRight: Radius.circular(isBot ? 16 : 4),
          ),
          border: isBot ? Border.all(color: AppTheme.divider) : null,
        ),
        child: Text(
          content,
          style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: const SizedBox(
          width: 24,
          height: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DotAnimation(delay: 0),
              _DotAnimation(delay: 150),
              _DotAnimation(delay: 300),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotAnimation extends StatefulWidget {
  final int delay;
  const _DotAnimation({required this.delay});

  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 5,
          height: 5,
          margin: EdgeInsets.only(bottom: _animation.value * 6),
          decoration: const BoxDecoration(
            color: Colors.white54,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_state.dart';
import '../models/character.dart';
import '../models/message.dart';
import '../models/chat.dart';
import '../routes/route_constants.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? chatId;

  const ChatScreen({super.key, this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Character? _selectedCharacter;
  Chat? _currentChat;
  bool _isSendingMessage = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final appState = ref.read(appStateProvider);
    if (!appState.isAuthenticated) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.login);
      }
      return;
    }

    await ref.read(appStateProvider.notifier).loadCharacters();
    if (ref.read(appStateProvider).characters.isNotEmpty) {
      setState(() {
        _selectedCharacter = ref.read(appStateProvider).characters.first;
      });
      
      if (_selectedCharacter != null) {
        final chat = await ref.read(appStateProvider.notifier).createChat(_selectedCharacter!.id);
        if (chat != null) {
          setState(() {
            _currentChat = chat;
          });
          await ref.read(appStateProvider.notifier).loadChatMessages(chat.id);
        }
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_currentChat == null) return;
    
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSendingMessage = true;
    });

    try {
      _messageController.clear();
      await ref.read(appStateProvider.notifier).sendMessage(_currentChat!.id, message);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  Future<void> _createNewChat() async {
    if (_selectedCharacter == null) return;

    setState(() {
      _isSendingMessage = true;
    });

    try {
      final chat = await ref.read(appStateProvider.notifier).createChat(_selectedCharacter!.id);
      if (chat != null) {
        setState(() {
          _currentChat = chat;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create chat: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentChat?.characterName ?? 'Chat'),
      ),
      body: appState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentChat == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No chat selected'),
                      if (_selectedCharacter != null)
                        ElevatedButton(
                          onPressed: _isSendingMessage ? null : _createNewChat,
                          child: const Text('Start New Chat'),
                        ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: appState.chatMessages[_currentChat!.id]?.length ?? 0,
                        itemBuilder: (context, index) {
                          final messages = appState.chatMessages[_currentChat!.id] ?? [];
                          final message = messages[index];
                          return _MessageBubble(
                            message: message,
                            showAvatar: !message.isUser,
                            avatarUrl: _currentChat?.characterAvatar,
                          );
                        },
                      ),
                    ),
                    if (_isSendingMessage)
                      const LinearProgressIndicator(),
                    _buildMessageInput(),
                  ],
                ),
    );
  }

  Widget _buildMessageInput() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.2),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                    fillColor: Colors.white70,
                    filled: true,
                  ),
                  onSubmitted: (_) => _isSendingMessage ? null : _sendMessage(),
                  enabled: !_isSendingMessage,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.purple),
                onPressed: _isSendingMessage ? null : _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;
  final String? avatarUrl;

  const _MessageBubble({
    required this.message,
    this.showAvatar = false,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && showAvatar) ...[
            CircleAvatar(
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

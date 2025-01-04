import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_state.dart';
import '../models/message.dart';
import '../models/chat.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/audio_message_bubble.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String characterId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.characterId,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSendingMessage = false;
  String? _activeChatId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final appState = ref.read(appStateProvider.notifier);
      
      // First load characters
      await appState.loadCharacters();
      
      // Verify character exists or use first available
      final character = ref.read(appStateProvider).characters.firstWhere(
        (c) => c.id == widget.characterId,
        orElse: () {
          debugPrint('Character ${widget.characterId} not found, using first available character');
          return ref.read(appStateProvider).characters.first;
        },
      );
      
      // Create a new chat if needed
      if (widget.chatId.isEmpty || widget.chatId == 'new') {
        debugPrint('Creating new chat with character: ${character.name} (${character.id})');
        final chat = await appState.createChat(character.id);
        if (chat != null) {
          setState(() {
            _activeChatId = chat.id;
          });
          debugPrint('Chat created successfully: ${chat.id}');
        } else {
          throw Exception('Failed to create chat');
        }
      } else {
        setState(() {
          _activeChatId = widget.chatId;
        });
      }
      
      // Load messages for the active chat
      if (_activeChatId != null) {
        await appState.loadChatMessages(_activeChatId!);
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error in chat setup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Character not found')
                ? 'Character not found. Please try again.'
                : 'Failed to setup chat. Please try again.',
            ),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_activeChatId == null) return;
    
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSendingMessage = true;
    });

    final appState = ref.read(appStateProvider.notifier);
    try {
      await appState.sendMessage(_activeChatId!, message);
      _messageController.clear();
      await appState.loadChatMessages(_activeChatId!);
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final appState = ref.watch(appStateProvider);
          if (appState.isLoading || appState.characters.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFF1A1A1A),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1A1A1A),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

          final character = appState.characters.firstWhere(
          (c) => c.id == widget.characterId,
          orElse: () {
            // If character not found after loading, go back to chat list
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pop(context);
            });
          return appState.characters.first; // Temporary return
          },
        );

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: character.avatarOrImageUrl.isNotEmpty
                      ? NetworkImage(character.avatarOrImageUrl)
                      : null,
                  backgroundColor: Colors.grey[800],
                  child: character.avatarOrImageUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  character.name,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                      child: appState.isLoading || _activeChatId == null
                      ? const LoadingIndicator()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: appState.chatMessages[_activeChatId!]?.length ?? 0,
                          itemBuilder: (context, index) {
                            final messages = appState.chatMessages[_activeChatId!];
                            if (messages == null || index >= messages.length) {
                              debugPrint('No messages found for chat $_activeChatId');
                              return const SizedBox.shrink();
                            }
                            final message = messages[index];
                            debugPrint('=== Message Debug ===');
                            debugPrint('Message ID: ${message.id}');
                            debugPrint('Message content: ${message.content}');
                            debugPrint('Message type: ${message.type}');
                            debugPrint('Is user message: ${message.isUser}');
                            debugPrint('Media URL: ${message.mediaUrl}');
                            debugPrint('====================');
                            if (message.isUser) {
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        message.content,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return AudioMessageBubble(
                                message: message,
                                isUser: false,
                              );
                            }
                          },
                        ),
                ),
                if (_isSendingMessage)
                  const LinearProgressIndicator(),
                _buildMessageInput(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _isSendingMessage ? null : _sendMessage(),
              enabled: !_isSendingMessage && _activeChatId != null,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: _isSendingMessage || _activeChatId == null
                  ? Colors.grey[600]
                  : Colors.white,
            ),
            onPressed: _isSendingMessage || _activeChatId == null
                ? null
                : _sendMessage,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

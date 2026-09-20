import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/deepseek_service.dart';
import '../../../data/models/savings_goal_model.dart';
import '../../../providers/auth_provider.dart';

class SavingsGoalChatSheet extends StatefulWidget {
  final SavingsGoalModel goal;

  const SavingsGoalChatSheet({super.key, required this.goal});

  @override
  State<SavingsGoalChatSheet> createState() => _SavingsGoalChatSheetState();
}

class _SavingsGoalChatSheetState extends State<SavingsGoalChatSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DeepSeekService _aiService = DeepSeekService();
  
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    final user = context.read<AuthProvider>().currentUser;
    final income = user?.monthlyIncome ?? 0.0;

    final systemPrompt = '''
You are a helpful and encouraging financial Savings Coach.
The user is trying to save for a goal: "${widget.goal.name}".
Target Amount: ₹${widget.goal.targetAmount}
Currently Saved: ₹${widget.goal.currentAmount}
Deadline: ${widget.goal.targetDate?.toString().split(' ')[0] ?? 'No deadline'}
Days Remaining: ${widget.goal.daysRemaining != null ? '${widget.goal.daysRemaining} days' : 'No deadline set'}
User's Monthly Income: ₹$income

Your first message should be an encouraging greeting and a brief 2-3 sentence strategy to help them reach this specific goal based on their current progress and income. Keep your responses concise, friendly, and practical. Do not use markdown headers, just plain text.
''';

    _messages.add({'role': 'system', 'content': systemPrompt});
    
    // Automatically trigger the first response from the AI
    _sendMessage(isInitial: true);
  }

  Future<void> _sendMessage({bool isInitial = false}) async {
    String userText = _messageController.text.trim();
    if (!isInitial && userText.isEmpty) return;

    if (!isInitial) {
      setState(() {
        _messages.add({'role': 'user', 'content': userText});
        _messageController.clear();
      });
      _scrollToBottom();
    }

    setState(() => _isLoading = true);

    try {
      final response = await _aiService.chatWithSavingsCoach(_messages);
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': response});
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter out system message for UI
    final displayMessages = _messages.where((m) => m['role'] != 'system').toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'AI Savings Coach',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          
          // Chat List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: displayMessages.length,
              itemBuilder: (context, index) {
                final msg = displayMessages[index];
                final isUser = msg['role'] == 'user';
                return _buildChatBubble(msg['content']!, isUser, isDark);
              },
            ),
          ),
          
          // Loading Indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
            
          // Input Area
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask for tips...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(isDark ? 0.2 : 0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isLoading ? null : () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser, bool isDark) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryColor : Colors.grey.withOpacity(isDark ? 0.3 : 0.2),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

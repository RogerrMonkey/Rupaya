import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  final String selectedLanguage;

  const ChatbotScreen({super.key, required this.selectedLanguage});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text: _getText('welcomeMessage'),
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF46EC13),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Color(0xFF46EC13),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pocket Saathi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getText('aiAssistant'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _clearChat,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggested Questions
          if (_messages.length == 1) _buildSuggestedQuestions(),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuestions() {
    final questions = [
      _getText('question1'),
      _getText('question2'),
      _getText('question3'),
      _getText('question4'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getText('suggestedQuestions'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: questions.map((question) {
              return GestureDetector(
                onTap: () => _sendMessage(question),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF46EC13).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF46EC13).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    question,
                    style: const TextStyle(
                      color: Color(0xFF46EC13),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF46EC13),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF46EC13)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF46EC13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 200)),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF46EC13).withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Voice Input Button
            IconButton(
              onPressed: _startVoiceInput,
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? const Color(0xFF46EC13) : Colors.grey,
                size: 28,
              ),
            ),

            // Text Input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextFormField(
                  controller: _messageController,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: _getText('typeMessage'),
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onFieldSubmitted: (text) => _sendMessage(text),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send Button
            GestureDetector(
              onTap: () => _sendMessage(_messageController.text),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF46EC13),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: _generateResponse(text),
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  String _generateResponse(String question) {
    // Simple mock responses - replace with actual AI integration
    final responses = {
      'hi': {
        'spending': 'इस महीने आपने ₹18,500 खर्च किए हैं। सबसे ज्यादा खर्च भोजन पर (₹7,200) हुआ है।',
        'debt': 'आपको ₹5,000 चुकाने हैं और ₹3,200 वापस मिलने हैं।',
        'save': 'अगर आप रोज ₹50 बचाएं, तो 100 दिन में ₹5,000 जमा हो जाएंगे!',
        'default': 'मैं आपके पैसे की जानकारी में मदद कर सकता हूं। कोई खास सवाल है?',
      },
      'mr': {
        'spending': 'या महिन्यात तुम्ही ₹18,500 खर्च केले आहेत। सर्वाधिक खर्च जेवणावर (₹7,200) झाला आहे।',
        'debt': 'तुम्हाला ₹5,000 फेडायचे आहेत आणि ₹3,200 परत मिळायचे आहेत।',
        'save': 'जर तुम्ही रोज ₹50 बचत केली, तर 100 दिवसात ₹5,000 जमा होतील!',
        'default': 'मी तुमच्या पैशाच्या माहितीत मदत करू शकतो. काही विशेष प्रश्न आहे का?',
      },
      'en': {
        'spending': 'This month you spent ₹18,500. Highest spending was on food (₹7,200).',
        'debt': 'You owe ₹5,000 and are owed ₹3,200.',
        'save': 'If you save ₹50 daily, you\'ll have ₹5,000 in 100 days!',
        'default': 'I can help you with your money information. Any specific questions?',
      },
    };

    final lang = widget.selectedLanguage;
    final langResponses = responses[lang] ?? responses['en']!;

    if (question.toLowerCase().contains('spend') || question.contains('खर्च') || question.contains('खर्च')) {
      return langResponses['spending']!;
    } else if (question.toLowerCase().contains('debt') || question.contains('कर्ज') || question.contains('कर्ज')) {
      return langResponses['debt']!;
    } else if (question.toLowerCase().contains('save') || question.contains('बचत') || question.contains('बचत')) {
      return langResponses['save']!;
    } else {
      return langResponses['default']!;
    }
  }

  void _startVoiceInput() {
    setState(() {
      _isListening = true;
    });

    // Simulate voice input - replace with actual speech-to-text
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isListening = false;
      });
      _sendMessage(_getText('voiceQuestion'));
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _addWelcomeMessage();
    });
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

  String _getText(String key) {
    final texts = {
      'hi': {
        'aiAssistant': 'AI सहायक',
        'welcomeMessage': 'नमस्ते! मैं आपका पॉकेट साथी हूं। आपके पैसों के बारे में कुछ भी पूछिए।',
        'suggestedQuestions': 'सुझावित सवाल:',
        'question1': 'इस महीने कितना खर्च हुआ?',
        'question2': 'मेरा कर्ज कितना है?',
        'question3': 'सबसे ज्यादा कहां खर्च हुआ?',
        'question4': 'पैसे कैसे बचाऊं?',
        'typeMessage': 'अपना सवाल लिखें...',
        'voiceQuestion': 'इस महीने कितना खर्च हुआ?',
      },
      'mr': {
        'aiAssistant': 'AI सहाय्यक',
        'welcomeMessage': 'नमस्कार! मी तुमचा पॉकेट साथी आहे. तुमच्या पैशाबद्दल काहीही विचारा.',
        'suggestedQuestions': 'सुचवलेले प्रश्न:',
        'question1': 'या महिन्यात किती खर्च झाला?',
        'question2': 'माझे कर्ज किती आहे?',
        'question3': 'सर्वाधिक कुठे खर्च झाला?',
        'question4': 'पैसे कसे बचवावे?',
        'typeMessage': 'तुमचा प्रश्न लिहा...',
        'voiceQuestion': 'या महिन्यात किती खर्च झाला?',
      },
      'en': {
        'aiAssistant': 'AI Assistant',
        'welcomeMessage': 'Hello! I\'m your Pocket Saathi. Ask me anything about your money.',
        'suggestedQuestions': 'Suggested questions:',
        'question1': 'How much did I spend this month?',
        'question2': 'What\'s my debt?',
        'question3': 'Where did I spend the most?',
        'question4': 'How to save money?',
        'typeMessage': 'Type your question...',
        'voiceQuestion': 'How much did I spend this month?',
      },
    };

    return texts[widget.selectedLanguage]?[key] ?? texts['en']![key]!;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

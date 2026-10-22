import 'package:flutter/material.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final List<Map<String, String>> _helplines = [
    {
      'number': '112',
      'title': 'National Emergency Number',
      'subtitle': 'All-in-one emergency dispatch (Police, Fire, Ambulance)',
      'color': '0xFFD32F2F',
    },
    {
      'number': '1091',
      'title': 'Women Helpline (24x7)',
      'subtitle': 'Immediate protection and emergency assistance for women',
      'color': '0xFF7B1FA2',
    },
    {
      'number': '1930',
      'title': 'National Cyber Crime Helpline',
      'subtitle': 'Report financial fraud, cyber stalking, and online abuse',
      'color': '0xFF1976D2',
    },
    {
      'number': '181',
      'title': 'Women Distress Line',
      'subtitle': 'Support for domestic violence and legal guidance',
      'color': '0xFFC2185B',
    },
    {
      'number': '100',
      'title': 'Police Control Room',
      'subtitle': 'Direct link to local police dispatch cells',
      'color': '0xFF388E3C',
    },
  ];

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How does the Emergency SOS Trigger work?',
      'answer': 'You can activate SOS via a double-tap/long-press on the floating button, triple-pressing power button, or saying your custom voice phrase (e.g. "Box Box"). A 5-second cancel timer runs before alerting guardians and responders with live GPS coordinates.',
    },
    {
      'question': 'How does Cab & Travel Guardian keep me safe?',
      'answer': 'Cab Guardian monitors your route in real-time. If the cab strays off route by more than 30 meters or makes unauthorized stops, the system automatically elevates the Risk Index and prompts an emergency check.',
    },
    {
      'question': 'What is the Cryptographic Evidence Vault?',
      'answer': 'All audio, video, and snapshot evidence captured during an SOS trigger is hashed using SHA-256 encryption before uploading. This guarantees evidence remains tamper-proof and legally admissible.',
    },
    {
      'question': 'Can I send SOS alerts without internet connectivity?',
      'answer': 'Yes! SHE SHIELD includes an SMS Fallback protocol. When mobile data is unavailable, emergency SMS messages containing cached GPS coordinates are sent directly to your linked guardians.',
    },
    {
      'question': 'How do I connect smart wearables or BLE buttons?',
      'answer': 'Head to the Wearables section in the app to pair your Bluetooth smart watch, band, or panic button. Once paired, pressing the hardware button instantly triggers an SOS broadcast.',
    },
  ];

  void _callNumber(String number) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dialing Emergency Helpline: $number...'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _openSupportChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.purple,
                        child: Icon(Icons.support_agent, color: Colors.white),
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SHE SHIELD Support Assist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Online | 24/7 AI Security Desk', style: TextStyle(fontSize: 11, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildChatBubble('Hello! How can I assist you with your safety settings or emergency protocols today?', false),
                    _buildChatBubble('How do I add a new guardian to my emergency network?', true),
                    _buildChatBubble('To add a guardian, tap "Guardian Link" on the home dashboard, type their email and relation, and send a pairing request.', false),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Type message to support desk...',
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.purple),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Message sent to 24/7 Support Desk.')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.purple : Colors.purple.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: const BoxConstraints(maxWidth: 280),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.purple.shade900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6FE),
      appBar: AppBar(
        title: const Text('Help & Support Center'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Emergency Banner
            Card(
              color: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.phone_in_talk, size: 40, color: Colors.white),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency SOS Helplines',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tap any helpline below for immediate toll-free connection.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Emergency Numbers List
            const Text(
              'TOLL-FREE EMERGENCY NUMBERS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple, letterSpacing: 1.1),
            ),
            const SizedBox(height: 10),

            Column(
              children: _helplines.map((item) {
                final colorVal = int.parse(item['color']!);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 1.5,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(colorVal).withValues(alpha: 0.15),
                      child: Text(
                        item['number']!,
                        style: TextStyle(color: Color(colorVal), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(item['subtitle']!, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(colorVal),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _callNumber(item['number']!),
                      icon: const Icon(Icons.call, size: 14, color: Colors.white),
                      label: Text(item['number']!, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // FAQs Expansion List
            const Text(
              'FREQUENTLY ASKED QUESTIONS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple, letterSpacing: 1.1),
            ),
            const SizedBox(height: 10),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: _faqs.map((faq) {
                  return ExpansionTile(
                    leading: const Icon(Icons.help_outline, color: Colors.purple),
                    title: Text(
                      faq['question']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Text(
                          faq['answer']!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Support Chat Launch Button
            Card(
              color: Colors.purple.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.purple.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.purple,
                      radius: 24,
                      child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Need Personal Assistance?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('Chat with our 24/7 AI & Human Security Support Desk.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: _openSupportChat,
                      child: const Text('Live Chat'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

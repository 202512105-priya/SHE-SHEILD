import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'auth_screens.dart';

class SafetyArticlesScreen extends StatefulWidget {
  const SafetyArticlesScreen({super.key});

  @override
  State<SafetyArticlesScreen> createState() => _SafetyArticlesScreenState();
}

class _SafetyArticlesScreenState extends State<SafetyArticlesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final List<Map<String, dynamic>> _articles = const [
    {
      "id": "art-1",
      "title": "Cyber Safety 101",
      "category": "Cyber Threat & Digital Defense",
      "icon": Icons.security,
      "color": Colors.purple,
      "readTime": "4 min read",
      "summary": "Essential guide on handling online harassment, blackmail, digital extortion, securing passwords, and preserving legal screenshot evidence.",
      "content": """
1. Immediate Isolation: Block offender accounts immediately on WhatsApp, Instagram, Telegram, or email. Do not engage in further chat.
2. Evidence Preservation: Take uncropped screenshots displaying timestamps, handle names, full message text, and profile URLs.
3. Zero Coercion Policy: Never submit to monetary demands or blackmail payments. Extorters will request further funds once paid.
4. Report via SHE SHIELD: File an instant report using the AI Cyber Assistant to trigger automated ISP takedown notices and police evidence vault logging.
5. Account Hardening: Enable 2-Factor Authentication (2FA) via authenticator apps on all linked social and banking accounts.
""",
    },
    {
      "id": "art-2",
      "title": "Self Defense Guidelines",
      "category": "Physical Protection Tactics",
      "icon": Icons.fitness_center,
      "color": Colors.redAccent,
      "readTime": "5 min read",
      "summary": "Key physical safety tactics, proper pepper spray deployment, escape strategies, situational awareness, and vulnerable target points.",
      "content": """
1. Situational Awareness: Keep your head up, avoid total earphone isolation while walking alone, and maintain safe 6-foot clearance from strangers.
2. Pepper Spray Technique: Hold the spray canisters with your dominant thumb on the trigger button (not index finger) to prevent accidental drop or misfire.
3. Vulnerable Points Target: Aim strikes or pepper spray at eyes, nasal bridge, throat, solar plexus, and groin for maximum escape opportunity.
4. Voice De-escalation & Alarm: Shout "FIRE" or "STOP" firmly using your diaphragm to attract public attention and disorient the attacker.
5. Quick Escape: Your goal in self-defense is creating space to escape to a well-lit, populated area, NOT lingering to fight.
""",
    },
    {
      "id": "art-3",
      "title": "Scam Alert",
      "category": "Fraud & Phishing Prevention",
      "icon": Icons.warning_amber_rounded,
      "color": Colors.orange,
      "readTime": "3 min read",
      "summary": "Spotting mock UPI payment verification links, fake banking calls, identity spoofing, and immediate financial freeze steps.",
      "content": """
1. UPI Payment Principle: Remember that entering your UPI PIN is ONLY required to SEND money or PAY, NEVER to RECEIVE money.
2. Mock Support Calls: Banks, RBI, and police officers will NEVER ask for your OTP, CVV, or PIN over phone calls or WhatsApp messages.
3. Phishing Link Inspection: Avoid clicking short links (bit.ly, tinyurl) claiming to verify account details or clear urgent tax/electricity bills.
4. Immediate Action: If scammed, dial Cyber Financial Crime Helpline 1930 immediately within the golden hour to freeze transacted balances.
""",
    },
    {
      "id": "art-4",
      "title": "Emergency Preparedness",
      "category": "Crisis Response Protocols",
      "icon": Icons.error_outline,
      "color": Colors.pink,
      "readTime": "6 min read",
      "summary": "Setting up hardware SOS hotkeys, offline SMS triggers, background GPS location tracking, and guardian network response sync.",
      "content": """
1. Wearable & Power Hotkeys: Configure double or triple power button press on your smartphone for rapid silent SOS triggers.
2. Offline SMS Fallback: Enable SHE SHIELD offline SMS cache so emergency coordinates broadcast even when cellular internet data is disabled.
3. Trusted Guardians Sync: Keep 2+ verified primary contacts linked with phone call permissions enabled for emergency automated calls.
4. Safe Route Deviations: Turn on Travel Guardian mode when boarding taxis or walking late to trigger automated deviation alerts if your vehicle veers off path.
""",
    },
  ];

  void _openArticleDetail(BuildContext context, Map<String, dynamic> article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: (article['color'] as Color).withValues(alpha: 0.15),
                    child: Icon(article['icon'] as IconData, color: article['color'] as Color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article['title'],
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: article['color'] as Color),
                        ),
                        Text(
                          "${article['category']} • ${article['readTime']}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (article['color'] as Color).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          article['summary'],
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        article['content'],
                        style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Article '${article['title']}' saved to offline safety handbook.")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: article['color'] as Color,
                ),
                icon: const Icon(Icons.bookmark),
                label: const Text("Bookmark for Offline Reading"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var filteredArticles = _articles.where((art) {
      String q = _searchQuery.toLowerCase();
      return art['title'].toString().toLowerCase().contains(q) ||
          art['category'].toString().toLowerCase().contains(q) ||
          art['summary'].toString().toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Awareness Hub'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.pink.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: "Search safety guidelines, scam alerts...",
                      prefixIcon: Icon(Icons.search, color: Colors.purple),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),

              // Article Cards Grid / List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredArticles.length,
                  itemBuilder: (context, index) {
                    var item = filteredArticles[index];
                    Color cardColor = item['color'] as Color;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _openArticleDetail(context, item),
                        borderRadius: BorderRadius.circular(20),
                        child: GlassCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: cardColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(item['icon'] as IconData, color: cardColor, size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'],
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: cardColor,
                                          ),
                                        ),
                                        Text(
                                          item['category'],
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    label: Text(item['readTime'], style: const TextStyle(fontSize: 10, color: Colors.purple)),
                                    backgroundColor: Colors.purple.shade50,
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item['summary'],
                                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "Read Full Guide",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cardColor),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios, size: 12, color: cardColor),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Alias class to ensure compatibility with AwarenessHubScreen references
class AwarenessHubScreen extends StatelessWidget {
  const AwarenessHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafetyArticlesScreen();
  }
}

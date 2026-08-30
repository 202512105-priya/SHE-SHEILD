import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'auth_screens.dart';

class GuardianLinkingScreen extends StatefulWidget {
  const GuardianLinkingScreen({super.key});

  @override
  State<GuardianLinkingScreen> createState() => _GuardianLinkingScreenState();
}

class _GuardianLinkingScreenState extends State<GuardianLinkingScreen> {
  final _emailController = TextEditingController();
  final _relationController = TextEditingController();
  bool _loading = false;

  Future<void> _sendRequest() async {
    if (_emailController.text.isEmpty || _relationController.text.isEmpty) return;
    setState(() => _loading = true);

    var db = Provider.of<DatabaseService>(context, listen: false);
    await db.sendGuardianRequest(_emailController.text, _relationController.text);

    setState(() => _loading = false);
    _emailController.clear();
    _relationController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Link request sent to Guardian. Pending user/guardian approval.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    var db = Provider.of<DatabaseService>(context);
    
    // Get all requests sent by this user or received by this user
    var requests = db.getCollection("GuardianRequests")
        .where((r) => r['userId'] == db.currentUse
<truncated 5440 bytes>
                        ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Confirmed Guardians network list
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Active Safe Contacts Network",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple),
                      ),
                      const SizedBox(height: 12),
                      if (guardians.isEmpty)
                        const Center(child: Text("No active safe contacts linked yet."))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: guardians.length,
                          itemBuilder: (context, i) {
                            var g = guardians[i];
                            return ListTile(
                              leading: const Icon(Icons.verified_user, color: Colors.green),
                              title: Text(g['name']),
                              subtitle: Text("${g['relation']} • ${g['phone']}"),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

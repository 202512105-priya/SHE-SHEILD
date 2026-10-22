import 'package:flutter/material.dart';

/// Reusable Jira Backlog Modal for Sprint 2/3 Modules in Viva Prototype Mode
class JiraBacklogDialog extends StatelessWidget {
  final String ticketId;
  final String title;
  final String description;
  final String priority;
  final String estimatedSprint;
  final String route;
  final List<String> plannedFeatures;

  const JiraBacklogDialog({
    super.key,
    required this.ticketId,
    required this.title,
    required this.description,
    required this.route,
    this.priority = 'HIGH',
    this.estimatedSprint = 'Sprint 3 (Jira Backlog)',
    this.plannedFeatures = const [],
  });

  static Future<void> show(
    BuildContext context, {
    required String ticketId,
    required String title,
    required String description,
    required String route,
    String priority = 'HIGH',
    String estimatedSprint = 'Sprint 3 (Jira Backlog)',
    List<String> plannedFeatures = const [],
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => JiraBacklogDialog(
        ticketId: ticketId,
        title: title,
        description: description,
        route: route,
        priority: priority,
        estimatedSprint: estimatedSprint,
        plannedFeatures: plannedFeatures,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(22.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Jira Header Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmark_rounded, size: 14, color: Colors.blue.shade800),
                        const SizedBox(width: 4),
                        Text(
                          ticketId.toUpperCase(),
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      'JIRA BACKLOG',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Feature Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 6),

              // Sprint Badge
              Row(
                children: [
                  const Icon(Icons.av_timer, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Scheduled for $estimatedSprint',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Scope Description
              const Text(
                'Sprint Scope & Specifications:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),

              if (plannedFeatures.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Planned Deliverables:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                ...plannedFeatures.map(
                  (feat) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16, color: Colors.purple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feat,
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              // Meta info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "PRIORITY",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Text(
                          priority,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "STATUS",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Text(
                          "In Progress (Sprint 2/3)",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, route); // Override preview
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Preview Module'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

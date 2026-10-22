import 'package:flutter/material.dart';

class ComplaintFlowScreen extends StatefulWidget {
  const ComplaintFlowScreen({super.key});

  @override
  State<ComplaintFlowScreen> createState() => _ComplaintFlowScreenState();
}

class _ComplaintFlowScreenState extends State<ComplaintFlowScreen> {
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("File Cybercrime Complaint"), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Incident Details",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.attach_file),
              label: const Text("Attach Cryptographic Evidence"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text("Submit Complaint"),
            ),
          ],
        ),
      ),
    );
  }
}

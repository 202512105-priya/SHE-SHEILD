import 'package:flutter/material.dart';

class AdminZoneTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const AdminZoneTile({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.admin_panel_settings, color: Colors.purple),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}

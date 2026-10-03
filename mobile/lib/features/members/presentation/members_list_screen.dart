import 'package:flutter/material.dart';

class MembersListScreen extends StatelessWidget {
  const MembersListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: const Center(child: Text('Phase 5')),
    );
  }
}
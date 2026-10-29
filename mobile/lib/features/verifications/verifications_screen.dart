import 'package:flutter/material.dart';

class VerificationsScreen extends StatelessWidget {
  const VerificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity Verifications'),
      ),
      body: const Center(
        child: Text('Approval Requests & Identity Verifications'),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/secuirity/biometric_service.dart';
import '../case_controller.dart';
import 'create_case_screen.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _isUnlocked = false;

  Future<void> _unlockCases() async {
    final authenticated = await _biometricService.authenticate(
      localizedReason: 'Authenticate to access private counselling cases',
    );
    if (mounted) {
      setState(() => _isUnlocked = authenticated);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Cases')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Cases are locked for your privacy'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock with Biometrics'),
                onPressed: _unlockCases,
              ),
            ],
          ),
        ),
      );
    }

    final cases = context.watch<CaseController>().cases;

    return Scaffold(
      appBar: AppBar(title: const Text('My Cases')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CreateCaseScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: cases.isEmpty
          ? const Center(child: Text('No active cases found.'))
          : ListView.builder(
              itemCount: cases.length,
              itemBuilder: (context, index) {
                final item = cases[index];
                return ListTile(
                  title: Text('${item.category} (${item.pseudonym})'),
                  subtitle: Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Chip(
                    label: Text(item.status.name.toUpperCase()),
                  ),
                );
              },
            ),
    );
  }
}
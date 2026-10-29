import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

import 'case_controller.dart';

class CasesListScreen extends StatefulWidget {
  const CasesListScreen({super.key});

  @override
  State<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends State<CasesListScreen> {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<void> _authenticateAndOpenCase(dynamic caseItem) async {
    try {
      final bool canAuthenticate =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        _openCaseDetails(caseItem);
        return;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate with Face ID or Touch ID to view this case',
      );

      if (didAuthenticate) {
        _openCaseDetails(caseItem);
      }
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      _openCaseDetails(caseItem);
    }
  }

  void _openCaseDetails(dynamic caseItem) {
    Navigator.pushNamed(
      context,
      '/cases/details',
      arguments: caseItem,
    );
  }

  @override
  Widget build(BuildContext context) {
    final caseController = context.watch<CaseController>();
    final casesList = caseController.cases;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cases'),
      ),
      body: casesList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No cases found'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/cases/create');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Case'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: casesList.length,
              itemBuilder: (context, index) {
                final caseItem = casesList[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.folder_open),
                    ),
                    title: Text('Case #${index + 1}'),
                    subtitle: Text(caseItem.toString()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _authenticateAndOpenCase(caseItem),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/cases/create');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
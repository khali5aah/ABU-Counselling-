import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../core/api/api_exception.dart';
import '../auth/auth_controller.dart';
import 'sample_cases.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(BuildContext context) async {
    final controller = context.read<AuthController>();
    try {
      await controller.refreshUser();
    } on ApiException catch (exception) {
      if (!context.mounted) return;
      if (exception.code == 'token_invalid' ||
          exception.code == 'not_authenticated') {
        await controller.logout();
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.welcome,
          (_) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your session has expired. Please log in again.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(exception.message)),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out of CHDC E-Counselling?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthController>().logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.welcome,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('CHDC E-Counselling'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Log out',
              onPressed: () => _logout(context),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Consumer<AuthController>(
                  builder: (context, controller, _) {
                    // Show only the username; no personal registration details.
                    final username = controller.user?.username ?? '';
                    return Text(
                      'Welcome, $username',
                      style: Theme.of(context).textTheme.headlineSmall,
                    );
                  },
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sample data — real case features arrive in a later milestone.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your cases',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final sampleCase in sampleCases)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(sampleCase.color),
                        child: Text(
                          sampleCase.alias.substring(0, 1),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(sampleCase.alias),
                      subtitle: const Text('Sample case · not real data'),
                      trailing: const Chip(label: Text('Sample')),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Case details arrive in a later milestone.',
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

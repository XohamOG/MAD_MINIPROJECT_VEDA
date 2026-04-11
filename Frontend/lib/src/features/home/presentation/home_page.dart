import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ashray Home'),
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<AuthController>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You are logged in',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      auth.user?.email ?? 'Session restored from saved token.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

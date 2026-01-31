import 'package:flutter/material.dart';

import '../shared/app_routes.dart';
import '../storage/app_settings.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Welcome to Meetup Check In QR',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Create an event, show the QR code, and scan attendees as they arrive.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _StepCard(
                icon: Icons.event,
                title: '1. Create an event',
                description: 'Add the title, location, and time.',
              ),
              const SizedBox(height: 12),
              _StepCard(
                icon: Icons.qr_code,
                title: '2. Show the QR code',
                description: 'Display the event QR on your device.',
              ),
              const SizedBox(height: 12),
              _StepCard(
                icon: Icons.qr_code_scanner,
                title: '3. Scan attendees',
                description: 'Check people in quickly from the scanner.',
              ),
              const SizedBox(height: 12),
              _StepCard(
                icon: Icons.share,
                title: '4. Export attendance',
                description: 'Share a CSV file when you’re done.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await AppSettings.setOnboardingSeen(true);
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                  },
                  child: const Text('Get started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _StepCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(description, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

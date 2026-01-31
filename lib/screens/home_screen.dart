import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/event.dart';
import '../shared/date_format.dart';
import '../storage/hive_setup.dart';
import '../shared/app_routes.dart';
import '../shared/snackbars.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeScreen extends StatelessWidget {
    const HomeScreen({super.key});

    @override
    Widget build(BuildContext context) {
        final box = Hive.box(HiveSetup.eventsBoxName);

        return Scaffold(
        appBar: AppBar(
            title: const Text('Events'),
            actions: [
                IconButton(
                    onPressed: () async {
                        await Navigator.pushNamed(context, AppRoutes.settings);
                    },
                    icon: const Icon(Icons.settings),
                ),
            ],
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: () async {
                final created = await Navigator.pushNamed(
                    context,
                    AppRoutes.createEvent,
                );
                if (!context.mounted) return;
                if (created == true) {
                    showSuccessSnackBar(context, 'Event created.');
                }
            },
            child: const Icon(Icons.add),
        ),
        body: ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box box, _) {
                if (box.isEmpty) {
                    return Center(
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    const Icon(Icons.event_busy, size: 48),
                                    const SizedBox(height: 12),
                                    Text(
                                        'No events yet',
                                        style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                        'Tap + to create your first event.',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                        onPressed: () async {
                                            final created = await Navigator.pushNamed(
                                                context,
                                                AppRoutes.createEvent,
                                            );
                                            if (!context.mounted) return;
                                            if (created == true) {
                                                showSuccessSnackBar(
                                                    context,
                                                    'Event created.',
                                                );
                                            }
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text('Create event'),
                                    ),
                                ],
                            ),
                        ),
                    );
                }

                final events = box.values
                    .map((e) => Event.fromMap(Map<dynamic, dynamic>.from( e as Map)))
                    .toList()
                   ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

                return ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                        final event = events[index];
                        return ListTile(
                            title: Text(event.title),
                            subtitle: Text(
                                '${formatDateTime(event.dateTime)} · ${event.location}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  AppRoutes.eventDetail,
                                  arguments: event.id,
                                );
                            },
                        );
                    },
                );
            },
        ),
      );
    }

}

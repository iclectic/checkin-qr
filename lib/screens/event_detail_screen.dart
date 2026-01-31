import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/check_in.dart';
import '../models/event.dart';
import '../shared/app_routes.dart';
import '../shared/attendance_export.dart';
import '../shared/date_format.dart';
import '../shared/snackbars.dart';
import '../storage/check_in_repository.dart';
import '../storage/event_repository.dart';
import '../storage/hive_setup.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EventDetailScreen extends StatefulWidget {
    final String eventId;

    const EventDetailScreen({super.key, required this.eventId});

    @override
    State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
    bool _exporting = false;

    @override
    Widget build(BuildContext context) {
        final eventsBox = Hive.box(HiveSetup.eventsBoxName);
        final checkInsBox = Hive.box(HiveSetup.checkInsBoxName);

        return ValueListenableBuilder(
            valueListenable: eventsBox.listenable(keys: [widget.eventId]),
            builder: (context, Box _, __) {
                final raw = eventsBox.get(widget.eventId);
                if (raw == null) {
                    return Scaffold(
                        appBar: AppBar(title: const Text('Event')),
                        body: const Center(child: Text('Event not found')),
                    );
                }

                final event = Event.fromMap(Map<dynamic, dynamic>.from(raw as Map));

                return ValueListenableBuilder(
                    valueListenable: checkInsBox.listenable(),
                    builder: (context, Box _, __) {
                        final checkInRepo = CheckInRepository();
                        final checkInCount = checkInRepo.countByEvent(event.id);
                        final recent = checkInRepo.listByEvent(event.id).take(3).toList();

                        return Scaffold(
                            appBar: AppBar(
                                title: Text(event.title),
                                actions: [
                                    IconButton(
                                        onPressed: () async {
                                            await Navigator.pushNamed(
                                                context,
                                                AppRoutes.attendance,
                                                arguments: event.id,
                                            );
                                        },
                                        icon: const Icon(Icons.list),
                                    ),
                                    IconButton(
                                        onPressed: _exporting
                                            ? null
                                            : () async {
                                                setState(() => _exporting = true);
                                                final checkIns =
                                                    CheckInRepository().listByEvent(
                                                        event.id,
                                                    );
                                                try {
                                                    await AttendanceCsvExporter.share(
                                                        event,
                                                        checkIns,
                                                    );
                                                    if (context.mounted) {
                                                        showSuccessSnackBar(
                                                            context,
                                                            'Export ready to share.',
                                                        );
                                                    }
                                                } catch (_) {
                                                    if (!context.mounted) return;
                                                    showErrorSnackBar(
                                                        context,
                                                        'Failed to export CSV.',
                                                    );
                                                } finally {
                                                    if (mounted) {
                                                        setState(() => _exporting = false);
                                                    }
                                                }
                                            },
                                        icon: _exporting
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                ),
                                            )
                                            : const Icon(Icons.share),
                                    ),
                                    IconButton(
                                        onPressed: () async {
                                            final saved = await Navigator.pushNamed(
                                                context,
                                                AppRoutes.scanner,
                                                arguments: event.id,
                                            );
                                            if (!context.mounted) return;
                                            if (saved == true) {
                                                showSuccessSnackBar(
                                                    context,
                                                    'Check-in saved.',
                                                );
                                            }
                                        },
                                        icon: const Icon(Icons.qr_code_scanner),
                                    ),
                                    IconButton(
                                        onPressed: () async {
                                            final saved = await Navigator.pushNamed(
                                                context,
                                                AppRoutes.manualCheckIn,
                                                arguments: event.id,
                                            );
                                            if (!context.mounted) return;
                                            if (saved == true) {
                                                showSuccessSnackBar(
                                                    context,
                                                    'Check-in saved.',
                                                );
                                            }
                                        },
                                        icon: const Icon(Icons.person_add),
                                    ),
                                    IconButton(
                                        onPressed: () async {
                                            final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (context) {
                                                    return AlertDialog(
                                                        title: const Text('Delete event?'),
                                                        content: const Text(
                                                            'This will permanently remove the event and all associated check-ins.',
                                                        ),
                                                        actions: [
                                                            TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        context,
                                                                        false,
                                                                    ),
                                                                child: const Text('Cancel'),
                                                            ),
                                                            ElevatedButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        context,
                                                                        true,
                                                                    ),
                                                                child: const Text('Delete'),
                                                            ),
                                                        ],
                                                    );
                                                },
                                            );

                                            if (confirmed != true) return;

                                            final checkIns = CheckInRepository();
                                            final events = EventRepository();
                                            await checkIns.deleteAllForEvent(event.id);
                                            await events.deleteEvent(event.id);
                                            if (context.mounted) Navigator.pop(context);
                                        },
                                        icon: const Icon(Icons.delete),
                                    ),
                                ],
                            ),
                            body: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text(
                                            event.location,
                                            style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                            formatDateTime(event.dateTime),
                                            style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                            'Check-ins: $checkInCount',
                                            style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        if (recent.isNotEmpty)
                                            ...recent.map(
                                                (CheckIn c) => Text(
                                                    '${c.attendeeName ?? 'Anonymous'} · ${formatDateTime(c.timestamp)}',
                                                ),
                                            )
                                        else
                                            Row(
                                                children: [
                                                    const Icon(Icons.group_outlined),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                        'No check-ins yet.',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium,
                                                    ),
                                                ],
                                            ),
                                        const SizedBox(height: 20),
                                        Center(
                                            child: Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                    border: Border.all(width: 1),
                                                    borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: QrImageView(
                                                    data: event.qrPayload(),
                                                    size: 240,
                                                ),
                                            ),
                                        ),
                                        const SizedBox(height: 12),
                                        Center(
                                            child: Text(
                                                'Payload: ${event.qrPayload()}',
                                                textAlign: TextAlign.center,
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                        );
                    },
                );
            },
        );
    }
}

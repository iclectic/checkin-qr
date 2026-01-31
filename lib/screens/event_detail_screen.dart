import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/check_in.dart';
import '../models/event.dart';
import '../shared/app_config.dart';
import '../shared/app_routes.dart';
import '../shared/attendance_export.dart';
import '../shared/date_format.dart';
import '../shared/self_check_in_link.dart';
import '../shared/snackbars.dart';
import '../storage/app_settings.dart';
import '../storage/check_in_repository.dart';
import '../storage/cloud_check_in_repository.dart';
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
    bool _syncing = false;
    bool _cloudExporting = false;

    @override
    Widget build(BuildContext context) {
        final eventsBox = Hive.box(HiveSetup.eventsBoxName);
        final checkInsBox = Hive.box(HiveSetup.checkInsBoxName);
        final settingsBox = Hive.box(HiveSetup.settingsBoxName);

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
                        return ValueListenableBuilder(
                            valueListenable: settingsBox.listenable(),
                            builder: (context, Box _, __) {
                                final theme = Theme.of(context);
                                final checkInRepo = CheckInRepository();
                                final checkInCount = checkInRepo.countByEvent(event.id);
                                final recent =
                                    checkInRepo.listByEvent(event.id).take(3).toList();
                                final selfCheckInUrl = SelfCheckInLink.build(event);
                                final cloudConfigured = AppConfig.supabaseConfigured;

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
                                child: SingleChildScrollView(
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Text(
                                                event.location,
                                                style: theme.textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                                formatDateTime(event.dateTime),
                                                style: theme.textTheme.bodyMedium,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                                'Check-ins: $checkInCount',
                                                style: theme.textTheme.titleMedium,
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
                                                            style: theme
                                                                .textTheme
                                                                .bodyMedium,
                                                        ),
                                                    ],
                                                ),
                                            const SizedBox(height: 20),
                                            Text(
                                                'Organizer QR',
                                                style: theme.textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 8),
                                            Center(
                                                child: Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                        border: Border.all(width: 1),
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                    ),
                                                    child: QrImageView(
                                                        data: event.qrPayload(),
                                                        size: 220,
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
                                            const SizedBox(height: 24),
                                            Text(
                                                'Attendee self check-in',
                                                style: theme.textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 8),
                                            if (selfCheckInUrl == null)
                                                Row(
                                                    children: [
                                                        const Icon(Icons.link_off),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                            child: Text(
                                                                'Set SELF_CHECKIN_BASE_URL to enable the attendee check-in QR.',
                                                                style: theme.textTheme
                                                                    .bodyMedium,
                                                            ),
                                                        ),
                                                    ],
                                                )
                                            else
                                                Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 1,
                                                            color: theme
                                                                .colorScheme
                                                                .outlineVariant,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                    ),
                                                    child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.center,
                                                        children: [
                                                            Text(
                                                                'Attendees can scan this QR to open the hosted check-in form.',
                                                                textAlign: TextAlign.center,
                                                                style: theme
                                                                    .textTheme
                                                                    .bodyMedium,
                                                            ),
                                                            const SizedBox(height: 12),
                                                            QrImageView(
                                                                data: selfCheckInUrl,
                                                                size: 200,
                                                            ),
                                                            const SizedBox(height: 12),
                                                            SelectableText(
                                                                selfCheckInUrl,
                                                                textAlign: TextAlign.center,
                                                                style: theme.textTheme.bodySmall,
                                                            ),
                                                            const SizedBox(height: 12),
                                                            Wrap(
                                                                spacing: 8,
                                                                runSpacing: 8,
                                                                alignment:
                                                                    WrapAlignment.center,
                                                                children: [
                                                                    OutlinedButton.icon(
                                                                        onPressed: () =>
                                                                            _copyLink(
                                                                                selfCheckInUrl,
                                                                            ),
                                                                        icon: const Icon(
                                                                            Icons.copy,
                                                                        ),
                                                                        label: const Text(
                                                                            'Copy link',
                                                                        ),
                                                                    ),
                                                                    OutlinedButton.icon(
                                                                        onPressed: () =>
                                                                            _shareLink(
                                                                                selfCheckInUrl,
                                                                            ),
                                                                        icon: const Icon(
                                                                            Icons.share,
                                                                        ),
                                                                        label: const Text(
                                                                            'Share link',
                                                                        ),
                                                                    ),
                                                                ],
                                                            ),
                                                        ],
                                                    ),
                                                ),
                                            const SizedBox(height: 24),
                                            Text(
                                                'Cloud sync',
                                                style: theme.textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 8),
                                            if (!cloudConfigured)
                                                Row(
                                                    children: [
                                                        const Icon(Icons.cloud_off),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                            child: Text(
                                                                'Set SUPABASE_URL and SUPABASE_ANON_KEY to enable cloud sync.',
                                                                style: theme.textTheme
                                                                    .bodyMedium,
                                                            ),
                                                        ),
                                                    ],
                                                )
                                            else if (!AppSettings.cloudSyncEnabled)
                                                Row(
                                                    children: [
                                                        const Icon(Icons.cloud_queue),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                            child: Text(
                                                                'Enable cloud sync in Settings to pull attendee check-ins.',
                                                                style: theme.textTheme
                                                                    .bodyMedium,
                                                            ),
                                                        ),
                                                    ],
                                                )
                                            else
                                                Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                        Text(
                                                            'Sync check-ins from the hosted form and keep cloud exports up to date.',
                                                            style: theme.textTheme.bodyMedium,
                                                        ),
                                                        const SizedBox(height: 12),
                                                        Wrap(
                                                            spacing: 8,
                                                            runSpacing: 8,
                                                            children: [
                                                                ElevatedButton.icon(
                                                                    onPressed: _syncing
                                                                        ? null
                                                                        : () => _syncCloud(
                                                                            event,
                                                                        ),
                                                                    icon: _syncing
                                                                        ? const SizedBox(
                                                                            width: 18,
                                                                            height: 18,
                                                                            child:
                                                                                CircularProgressIndicator(
                                                                                    strokeWidth:
                                                                                        2,
                                                                                ),
                                                                        )
                                                                        : const Icon(
                                                                            Icons.sync,
                                                                        ),
                                                                    label: Text(
                                                                        _syncing
                                                                            ? 'Syncing...'
                                                                            : 'Sync now',
                                                                    ),
                                                                ),
                                                                OutlinedButton.icon(
                                                                    onPressed:
                                                                        _cloudExporting
                                                                            ? null
                                                                            : () =>
                                                                                _exportCloud(
                                                                                    event,
                                                                                ),
                                                                    icon: _cloudExporting
                                                                        ? const SizedBox(
                                                                            width: 18,
                                                                            height: 18,
                                                                            child:
                                                                                CircularProgressIndicator(
                                                                                    strokeWidth:
                                                                                        2,
                                                                                ),
                                                                        )
                                                                        : const Icon(
                                                                            Icons.cloud_download,
                                                                        ),
                                                                    label: Text(
                                                                        _cloudExporting
                                                                            ? 'Exporting...'
                                                                            : 'Export cloud CSV',
                                                                    ),
                                                                ),
                                                            ],
                                                        ),
                                                    ],
                                                ),
                                        ],
                                    ),
                                ),
                            ),
                                );
                            },
                        );
                    },
                );
            },
        );
    }

    Future<void> _copyLink(String url) async {
        await Clipboard.setData(ClipboardData(text: url));
        if (!mounted) return;
        showSuccessSnackBar(context, 'Link copied to clipboard.');
    }

    Future<void> _shareLink(String url) async {
        await Share.share(url, subject: 'Event check-in link');
    }

    Future<void> _syncCloud(Event event) async {
        if (_syncing) return;
        if (!AppSettings.cloudSyncEnabled) {
            showErrorSnackBar(context, 'Enable cloud sync in Settings first.');
            return;
        }

        setState(() => _syncing = true);

        try {
            final localRepo = CheckInRepository();
            final localCheckIns = localRepo.listByEvent(event.id);
            final existingIds = localCheckIns.map((c) => c.id).toSet();

            final cloudRepo = CloudCheckInRepository();
            final uploaded = await cloudRepo.upsertAll(event, localCheckIns);
            final cloudCheckIns = await cloudRepo.listByEvent(event);

            var imported = 0;
            for (final checkIn in cloudCheckIns) {
                await localRepo.add(checkIn);
                if (!existingIds.contains(checkIn.id)) {
                    imported += 1;
                }
            }

            if (!mounted) return;
            showSuccessSnackBar(
                context,
                'Sync complete. Imported $imported, uploaded $uploaded.',
            );
        } on CloudSyncException catch (e) {
            if (!mounted) return;
            showErrorSnackBar(context, e.message);
        } catch (_) {
            if (!mounted) return;
            showErrorSnackBar(context, 'Failed to sync cloud check-ins.');
        } finally {
            if (mounted) {
                setState(() => _syncing = false);
            }
        }
    }

    Future<void> _exportCloud(Event event) async {
        if (_cloudExporting) return;
        if (!AppSettings.cloudSyncEnabled) {
            showErrorSnackBar(context, 'Enable cloud sync in Settings first.');
            return;
        }

        setState(() => _cloudExporting = true);
        try {
            final cloudRepo = CloudCheckInRepository();
            final cloudCheckIns = await cloudRepo.listByEvent(event);
            await AttendanceCsvExporter.share(event, cloudCheckIns);
            if (!mounted) return;
            showSuccessSnackBar(context, 'Cloud export ready to share.');
        } on CloudSyncException catch (e) {
            if (!mounted) return;
            showErrorSnackBar(context, e.message);
        } catch (_) {
            if (!mounted) return;
            showErrorSnackBar(context, 'Failed to export cloud CSV.');
        } finally {
            if (mounted) {
                setState(() => _cloudExporting = false);
            }
        }
    }
}

import 'package:flutter/material.dart';

import '../models/check_in.dart';
import '../shared/date_format.dart';
import '../shared/snackbars.dart';
import '../storage/check_in_repository.dart';

class AttendanceListScreen extends StatefulWidget {
  final String eventId;

  const AttendanceListScreen({super.key, required this.eventId});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = CheckInRepository();
    final all = repo.listByEvent(widget.eventId);

    final query = _searchCtrl.text.trim().toLowerCase();
    final items = query.isEmpty
        ? all
        : all.where((c) => (c.attendeeName ?? '').toLowerCase().contains(query)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            onPressed: () => _confirmClearAttendance(context),
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Search by name',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'No check-ins yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Scan or add attendees to see them here.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final CheckIn c = items[index];
                        return ListTile(
                          title: Text(c.attendeeName ?? 'Anonymous'),
                          subtitle: Text('${c.method} · ${formatDateTime(c.timestamp)}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearAttendance(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear attendance?'),
          content: const Text(
            'This will remove all check-ins for this event from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final repo = CheckInRepository();
    await repo.deleteAllForEvent(widget.eventId);

    if (!mounted) return;
    setState(() {});
    showSuccessSnackBar(context, 'Attendance cleared.');
  }
}

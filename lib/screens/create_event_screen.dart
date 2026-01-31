import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../shared/date_format.dart';
import '../shared/snackbars.dart';
import '../storage/event_repository.dart';

class CreateEventScreen extends StatefulWidget {
    const CreateEventScreen({super.key});

    @override
    State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
    final _formKey = GlobalKey<FormState>();
    final _titleCtrl = TextEditingController();
    final _locationCtrl = TextEditingController();
    DateTime _dateTime = DateTime.now().add(const Duration(hours: 1));
    bool _saving = false;

    @override
    void dispose() {
        _titleCtrl.dispose();
        _locationCtrl.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text('Create event')),
            body: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                    key: _formKey,
                    child: ListView(
                        children: [
                            TextFormField(
                                controller: _titleCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Event title',
                                    border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                    if ( v == null || v.trim().isEmpty) return 'Enter a title';
                                    return null;
                                },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                                controller: _locationCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Location',
                                    border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Enter a location';
                                    return null;
                                },
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Date and time'),
                                subtitle: Text(formatDateTime(_dateTime)),
                                trailing: const Icon(Icons.edit_calendar),
                                onTap: _pickDateTime,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                                onPressed: _saving ? null : _save,
                                child: _saving
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                            SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                ),
                                            ),
                                            SizedBox(width: 12),
                                            Text('Saving...'),
                                        ],
                                    )
                                    : const Text('Save event'),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }

    Future<void> _pickDateTime() async {
        final date = await showDatePicker(
            context: context,
            initialDate: _dateTime,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
        );
        if (date == null) return;

        final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_dateTime),
        );
        if (time == null) return;

        setState(() {
            _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
    }

    Future<void> _save() async {
        final ok = _formKey.currentState?.validate() ?? false;
        if (!ok) return;

        setState(() => _saving = true);

        try {
            final id = const Uuid().v4();
            final code = _generateCode(5);

            final event = Event(
                id: id,
                title: _titleCtrl.text.trim(),
                dateTime: _dateTime,
                location: _locationCtrl.text.trim(),
                eventCode: code,
                createdAt: DateTime.now(),
            );

            final repo = EventRepository();
            await repo.saveEventMap(id, event.toMap());

            if (!mounted) return;
            Navigator.pop(context, true);
        } catch (_) {
            if (!mounted) return;
            showErrorSnackBar(context, 'Failed to save event.');
            setState(() => _saving = false);
        }
    }

    String _generateCode(int length) {
        const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
        final rand = Random.secure();
        return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
    }

}

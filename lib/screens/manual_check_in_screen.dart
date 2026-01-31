import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/check_in.dart';
import '../shared/attendee_input.dart';
import '../shared/snackbars.dart';
import '../storage/app_settings.dart';
import '../storage/check_in_repository.dart';
import '../storage/hive_setup.dart';

class ManualCheckInScreen extends StatefulWidget {
  final String eventId;

  const ManualCheckInScreen({super.key, required this.eventId});

  @override
  State<ManualCheckInScreen> createState() => _ManualCheckInScreenState();
}

class _ManualCheckInScreenState extends State<ManualCheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  bool _showExtras = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual check-in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder(
          valueListenable: Hive.box(HiveSetup.settingsBoxName).listenable(),
          builder: (context, Box _, __) {
            final enableNameCapture = AppSettings.enableNameCapture;

            return Form(
              key: _formKey,
              child: Column(
                children: [
                  if (enableNameCapture) ...[
                    TextFormField(
                      controller: _nameCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Attendee name (optional)'),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        if (value.trim().isEmpty) {
                          return 'Enter a name or clear the field.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Add email and company'),
                      value: _showExtras,
                      onChanged: (value) => setState(() => _showExtras = value),
                    ),
                    if (_showExtras) ...[
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email (optional)'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _companyCtrl,
                        decoration: const InputDecoration(labelText: 'Company (optional)'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ] else ...[
                    Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Name capture is disabled in Settings. '
                            'This check-in will be anonymous.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text('Saving...'),
                              ],
                            )
                          : const Text('Add check-in'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _saving = true);

    try {
      final enableNameCapture = AppSettings.enableNameCapture;
      final attendeeName =
          enableNameCapture ? sanitizeAttendeeName(_nameCtrl.text) : null;

      final checkIn = CheckIn(
        id: const Uuid().v4(),
        eventId: widget.eventId,
        timestamp: DateTime.now(),
        attendeeName: attendeeName,
        attendeeEmail: enableNameCapture && _showExtras
            ? sanitizeOptionalField(_emailCtrl.text)
            : null,
        attendeeCompany: enableNameCapture && _showExtras
            ? sanitizeOptionalField(_companyCtrl.text)
            : null,
        method: 'manual',
      );

      final repo = CheckInRepository();
      await repo.add(checkIn);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to save check-in.');
      setState(() => _saving = false);
    }
  }
}

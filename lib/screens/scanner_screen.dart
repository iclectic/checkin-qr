import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../models/check_in.dart';
import '../shared/attendee_input.dart';
import '../shared/snackbars.dart';
import '../shared/qr_payload.dart';
import '../storage/app_settings.dart';
import '../storage/check_in_repository.dart';
import '../storage/event_repository.dart';

class ScannerScreen extends StatefulWidget {
  final String eventId;

  const ScannerScreen({super.key, required this.eventId});

  static const Duration duplicateWindow = Duration(minutes: 2);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
        actions: [
          IconButton(
            onPressed: _isProcessing ? null : () => _promptForManualEntry(context),
            icon: const Icon(Icons.keyboard),
            tooltip: 'Enter QR payload',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleDetect,
            errorBuilder: (context, error, child) {
              return _ScannerErrorView(
                message: _scannerErrorMessage(error),
                onManualEntry: () => _promptForManualEntry(context),
              );
            },
          ),
          const _ScannerOverlay(hint: 'Point at a QR code to scan'),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Processing scan...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    await _processPayload(raw.trim());
  }

  Future<void> _processPayload(String raw) async {
    setState(() => _isProcessing = true);

    try {
      final payload = QrPayload.parse(raw);

      final eventRepo = EventRepository();
      if (payload.eventId != widget.eventId) {
        throw QrPayloadException('This QR code is for a different event.');
      }

      final event = eventRepo.getById(widget.eventId);
      if (event == null) {
        throw QrPayloadException('Event not found on this device.');
      }

      payload.validateAgainstEvent(event);

      final checkInRepo = CheckInRepository();
      final existing = checkInRepo.listByEvent(event.id);
      final now = DateTime.now();
      final recentlyCheckedIn = existing.any(
        (c) => now.difference(c.timestamp).abs() <= ScannerScreen.duplicateWindow,
      );

      if (recentlyCheckedIn) {
        final behavior = AppSettings.duplicateScanBehavior;
        if (behavior == DuplicateScanBehavior.block) {
          throw QrPayloadException(
            'Duplicate scan detected. Try again in a moment.',
          );
        }
        if (behavior == DuplicateScanBehavior.warn) {
          if (context.mounted) {
            showErrorSnackBar(
              context,
              'Duplicate scan detected. Saving anyway.',
            );
          }
        }
      }

      final enableNameCapture = AppSettings.enableNameCapture;
      final details =
          enableNameCapture ? await _promptForAttendeeDetails(context) : null;
      if (!mounted) return;

      final checkIn = CheckIn(
        id: const Uuid().v4(),
        eventId: event.id,
        timestamp: now,
        attendeeName: details?.name,
        attendeeEmail: details?.email,
        attendeeCompany: details?.company,
        method: 'scan',
      );

      await checkInRepo.add(checkIn);

      if (context.mounted) Navigator.pop(context, true);
    } on QrPayloadException catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, e.message);
      }
    } catch (_) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Failed to process QR code.');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _scannerErrorMessage(MobileScannerException error) {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Camera permission denied. You can enter the QR payload manually.';
      case MobileScannerErrorCode.unsupported:
        return 'Camera scanning is not supported on this device.';
      default:
        return 'Camera unavailable. You can enter the QR payload manually.';
    }
  }

  Future<void> _promptForManualEntry(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter QR payload'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'QR payload',
              hintText: 'MCQ|1|EVENT|...',
            ),
            maxLines: 2,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                controller.text.trim(),
              ),
              child: const Text('Process'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null || result.isEmpty) return;
    await _processPayload(result);
  }
  Future<_AttendeeDetails?> _promptForAttendeeDetails(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    var showExtras = false;

    final result = await showDialog<_AttendeeDetails>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add attendee name'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Attendee name',
                        ),
                        textCapitalization: TextCapitalization.words,
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Add email and company'),
                        value: showExtras,
                        onChanged: (value) =>
                            setDialogState(() => showExtras = value),
                      ),
                      if (showExtras) ...[
                        TextFormField(
                          controller: emailCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Email (optional)'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: companyCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Company (optional)'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final ok = formKey.currentState?.validate() ?? false;
                    if (!ok) return;

                    final name = sanitizeAttendeeName(nameCtrl.text);
                    if (name == null) return;

                    Navigator.pop(
                      context,
                      _AttendeeDetails(
                        name: name,
                        email: showExtras ? sanitizeOptionalField(emailCtrl.text) : null,
                        company:
                            showExtras ? sanitizeOptionalField(companyCtrl.text) : null,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    emailCtrl.dispose();
    companyCtrl.dispose();

    return result;
  }
}

class _AttendeeDetails {
  final String name;
  final String? email;
  final String? company;

  const _AttendeeDetails({
    required this.name,
    this.email,
    this.company,
  });
}

class _ScannerErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onManualEntry;

  const _ScannerErrorView({
    required this.message,
    required this.onManualEntry,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onManualEntry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                icon: const Icon(Icons.keyboard),
                label: const Text('Enter payload'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  final String? hint;

  const _ScannerOverlay({this.hint});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.7;
        final left = (constraints.maxWidth - size) / 2;
        final top = (constraints.maxHeight - size) / 2 - 40;

        return Stack(
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: top + size + 24,
              child: Text(
                hint ?? 'Point at a QR code to scan',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

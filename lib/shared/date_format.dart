import '../storage/app_settings.dart';

String formatDateTime(DateTime dt) {
  final two = (int n) => n.toString().padLeft(2, '0');

  switch (AppSettings.dateFormatOption) {
    case DateFormatOption.mdy:
      return '${two(dt.month)}/${two(dt.day)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
    case DateFormatOption.ymd:
    default:
      return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

String formatDateForFilename(DateTime dt) {
  final two = (int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
}

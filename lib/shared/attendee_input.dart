String? sanitizeAttendeeName(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final words = trimmed.split(RegExp(r'\s+'));
  final titled = words.map(_titleCaseWord).join(' ');
  return titled;
}

String? sanitizeOptionalField(String raw) {
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _titleCaseWord(String word) {
  if (word.isEmpty) return word;
  final lower = word.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}

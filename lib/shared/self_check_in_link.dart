import '../models/event.dart';
import 'app_config.dart';

class SelfCheckInLink {
  static String? build(Event event) {
    final base = AppConfig.selfCheckInBaseUrl.trim();
    if (base.isEmpty) return null;

    final baseUri = Uri.tryParse(base);
    if (baseUri == null) return null;

    final query = Map<String, String>.from(baseUri.queryParameters);
    query.addAll({
      'eventId': event.id,
      'eventCode': event.eventCode,
    });

    return baseUri.replace(queryParameters: query).toString();
  }
}

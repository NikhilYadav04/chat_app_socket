import 'package:intl/intl.dart';

String formatMongoDate(dynamic mongoDate) {
  if (mongoDate == null) return "00:00";

  try {
    DateTime dateTime;

    if (mongoDate is String) {
      // If MongoDB returns an ISO8601 string
      dateTime = DateTime.parse(mongoDate).toLocal();
    } else if (mongoDate is DateTime) {
      // If the driver already converted it to a Dart DateTime
      dateTime = mongoDate.toLocal();
    } else {
      return "00:00";
    }

    // Format: 'hh' is 12-hour, 'mm' is minutes, 'a' is AM/PM
    return DateFormat('hh:mm a').format(dateTime);
  } catch (e) {
    return "00:00";
  }
}

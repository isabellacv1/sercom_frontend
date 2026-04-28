import 'package:intl/intl.dart';

Object? readValue(Map<String, dynamic> data, Iterable<String> keys) {
  for (final key in keys) {
    if (data.containsKey(key) && data[key] != null) {
      return data[key];
    }
  }
  return null;
}

String? readStringValue(Map<String, dynamic> data, Iterable<String> keys) {
  final value = readValue(data, keys);
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int? readIntValue(Map<String, dynamic> data, Iterable<String> keys) {
  final value = readValue(data, keys);
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? readDoubleValue(Map<String, dynamic> data, Iterable<String> keys) {
  final value = readValue(data, keys);
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

List<String> readStringListValue(
  Map<String, dynamic> data,
  Iterable<String> keys,
) {
  final value = readValue(data, keys);
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  final text = value?.toString().trim();
  return text == null || text.isEmpty ? const [] : [text];
}

String formatCurrencyCop(num value) {
  return NumberFormat.currency(
    locale: 'es_CO',
    symbol: r'$',
    decimalDigits: 0,
  ).format(value);
}

String formatShortDate(String? rawDate) {
  final value = rawDate?.trim();
  if (value == null || value.isEmpty) return '';

  final date = DateTime.tryParse(value);
  if (date == null) return value;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final parsedDay = DateTime(date.year, date.month, date.day);

  if (parsedDay == today) return 'Hoy';
  return DateFormat('dd/MM/yyyy').format(date);
}

String formatTimeValue(String? rawTime) {
  final value = rawTime?.trim();
  if (value == null || value.isEmpty) return '';

  final dateTime = DateTime.tryParse(value);
  if (dateTime != null) {
    return DateFormat('HH:mm').format(dateTime);
  }

  return value.length >= 5 ? value.substring(0, 5) : value;
}

String formatAvailabilityLabel({
  String? date,
  String? from,
  String? to,
  String fallback = 'Fecha por confirmar',
}) {
  final dateLabel = formatShortDate(date);
  final fromLabel = formatTimeValue(from);
  final toLabel = formatTimeValue(to);

  final timeLabel = fromLabel.isNotEmpty && toLabel.isNotEmpty
      ? '$fromLabel - $toLabel'
      : fromLabel.isNotEmpty
          ? fromLabel
          : toLabel;

  if (dateLabel.isNotEmpty && timeLabel.isNotEmpty) {
    return '$dateLabel, $timeLabel';
  }

  if (dateLabel.isNotEmpty) return dateLabel;
  if (timeLabel.isNotEmpty) return timeLabel;

  return fallback;
}

import 'package:intl/intl.dart';

final NumberFormat _tzsFormat = NumberFormat.currency(
  locale: 'en_TZ',
  symbol: 'TZS ',
  decimalDigits: 0,
);

final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm');

String formatTsh(num amount) => _tzsFormat.format(amount);

String formatDate(DateTime date) => _dateFormat.format(date);

import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat("#,##0", "en_US");

  static String format(double amount) {
    return _formatter.format(amount);
  }
}

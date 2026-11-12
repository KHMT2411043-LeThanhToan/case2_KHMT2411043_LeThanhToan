
class DateFormatter {
  // Định dạng ngày: dd/MM/yyyy
  static String formatDate(
      DateTime? date, {
        String emptyText = 'Chưa thiết lập',
      }) {
    if (date == null) return emptyText;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  // Định dạng ngày và giờ: dd/MM/yyyy HH:mm
  static String formatDateTime(
      DateTime? date, {
        String emptyText = 'Không có thông tin',
      }) {
    if (date == null) return emptyText;

    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  // Chuyển dữ liệu ngày nhận từ API thành DateTime và định dạng
  static String formatDateTimeValue(
      dynamic value, {
        String emptyText = 'Không có thông tin',
      }) {
    if (value == null) return emptyText;

    final date = DateTime.tryParse(value.toString());

    if (date == null) return value.toString();

    return formatDateTime(date, emptyText: emptyText);
  }
}

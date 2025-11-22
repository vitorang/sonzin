String plural(int value, String singular, String plural) {
  return value == 1 ? singular : plural;
}

String formatTime(double seconds) {
  var duration = Duration(seconds: seconds.toInt());
  var h = duration.inHours;
  var m = duration.inMinutes.remainder(60).toString().padLeft(h > 0 ? 2 : 1, '0');
  var s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

  if (duration.inHours > 0) return '$h:$m:$s';
  return '$m:$s';
}

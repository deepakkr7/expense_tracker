import 'package:flutter_timezone/flutter_timezone.dart';

void main() async {
  var tz = await FlutterTimezone.getLocalTimezone();
  print(tz.runtimeType);
  print(tz);
}

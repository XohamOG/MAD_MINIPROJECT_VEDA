import 'package:flutter/widgets.dart';
import 'package:veda_app/src/core/services/notification_service.dart';
import 'package:veda_app/src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(const VedaApp());
}

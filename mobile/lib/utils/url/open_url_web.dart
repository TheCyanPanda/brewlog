import 'package:web/web.dart' as web;

Future<bool> openUrl(String url) async {
  web.window.open(url, '_blank');
  return true;
}

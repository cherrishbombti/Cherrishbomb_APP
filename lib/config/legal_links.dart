import 'package:url_launcher/url_launcher.dart';

/// 스토어 심사·법령상 앱 안에서 바로 열 수 있어야 하는 문서 주소.
class LegalLinks {
  LegalLinks._();

  static const String privacyPolicy = 'https://cat-zenith-8df.notion.site/3faa1e17134e81ef8a69d336df0f652c';
  static const String support = 'https://cat-zenith-8df.notion.site/3faa1e17134e8103b3c6cf68dcda97e4';

  /// 앱 안 브라우저(Safari View Controller / Custom Tabs)로 연다.
  static Future<bool> open(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
  }
}

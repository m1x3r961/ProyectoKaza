import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../app/theme/kaza_theme.dart';
import '../utils/open_url_stub.dart' if (dart.library.html) '../utils/open_url_web.dart';

/// Public page served from mobile/web/privacidad.html (required by Google Play).
const kPrivacyPolicyUrl = 'https://proyecto-kaza.vercel.app/privacidad.html';

/// Bottom sheet with the policy link: open it or copy the address.
void showPrivacyPolicySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: KazaTheme.coralKaza.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.privacy_tip_outlined, color: KazaTheme.coralKaza, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Política de privacidad',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: KazaTheme.azulKaza)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Cómo KAZA recopila, usa y protege tus datos, y cómo pedir la eliminación de tu cuenta.',
              style: TextStyle(fontSize: 14, height: 1.45, color: KazaTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: KazaTheme.azulKaza.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KazaTheme.azulKaza.withValues(alpha: 0.08)),
              ),
              child: const SelectableText(
                kPrivacyPolicyUrl,
                style: TextStyle(fontSize: 13, color: KazaTheme.azulKaza, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KazaTheme.azulKaza,
                      side: BorderSide(color: KazaTheme.azulKaza.withValues(alpha: 0.15)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copiar enlace', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () async {
                      await Clipboard.setData(const ClipboardData(text: kPrivacyPolicyUrl));
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Enlace copiado'),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KazaTheme.coralKaza,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Abrir', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (!openInNewTab(kPrivacyPolicyUrl)) {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _PolicyWebView()));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _PolicyWebView extends StatefulWidget {
  const _PolicyWebView();

  @override
  State<_PolicyWebView> createState() => _PolicyWebViewState();
}

class _PolicyWebViewState extends State<_PolicyWebView> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.disabled)
    ..loadRequest(Uri.parse(kPrivacyPolicyUrl));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de privacidad'),
        backgroundColor: Colors.white,
        foregroundColor: KazaTheme.azulKaza,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Copiar enlace',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: kPrivacyPolicyUrl));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace copiado')));
            },
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

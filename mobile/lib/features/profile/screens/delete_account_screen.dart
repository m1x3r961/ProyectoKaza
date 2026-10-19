import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/account_api.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  final AccountApi? api;
  const DeleteAccountScreen({super.key, this.api});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool _deleting = false;

  Future<void> _showDeactivateUnavailable() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar cuenta'),
        content: const Text(
            'La desactivación temporal todavía no está disponible. Si solo quieres tomar un descanso, '
            'cierra sesión: tus datos se conservan. Si quieres borrar tus datos, usa «Eliminar cuenta».'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendido')),
        ],
      ),
    );
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteConfirmationDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await (widget.api ?? AccountApi()).deleteAccount();
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      messenger.showSnackBar(SnackBar(content: Text('No se pudo eliminar la cuenta: $e')));
      return;
    }
    // The login no longer exists on the server; drop the local session too.
    try {
      await SupabaseConfig.client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}
    await ref.read(kazaAuthProvider.notifier).logout();
    if (!mounted) return;
    context.go('/map');
    messenger.showSnackBar(const SnackBar(content: Text('Tu cuenta fue eliminada.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Eliminar o desactivar cuenta', style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOptionCard(
              icon: Icons.pause_circle_outline,
              title: 'Desactivar cuenta',
              subtitle: 'Próximamente. Por ahora puedes cerrar sesión para tomar un descanso.',
              onTap: _deleting ? null : _showDeactivateUnavailable,
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              icon: Icons.delete_outline,
              title: 'Eliminar cuenta',
              subtitle: 'Se eliminarán tus datos personales y se retirarán tus publicaciones. No podrás recuperarlos.',
              iconColor: Colors.redAccent,
              titleColor: Colors.redAccent,
              onTap: _deleting ? null : _confirmAndDelete,
              busy: _deleting,
            ),

            const Spacer(),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Antes de eliminar tu cuenta:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14)),
                  const SizedBox(height: 8),
                  _buildWarningBullet('Si necesitas una copia de tus datos, pídela antes a sczkaza@gmail.com.'),
                  const SizedBox(height: 4),
                  _buildWarningBullet('Las conversaciones conservan los mensajes de la otra persona.'),
                  const SizedBox(height: 4),
                  _buildWarningBullet('Si solo tomarás un descanso, basta con cerrar sesión.'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color iconColor = KazaTheme.textPrimary,
    Color titleColor = KazaTheme.textPrimary,
    bool busy = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: KazaTheme.glassBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: titleColor)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: KazaTheme.textSecondary)),
                ],
              ),
            ),
            busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right, color: KazaTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
      ],
    );
  }
}

class _DeleteConfirmationDialog extends StatefulWidget {
  const _DeleteConfirmationDialog();

  @override
  State<_DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _controller.text.trim() == kDeleteAccountConfirmation;
    return AlertDialog(
      title: const Text('¿Eliminar tu cuenta?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'Se borrarán tus datos personales, se retirarán tus publicaciones y se cerrará tu acceso. '
              'Esta acción no se puede deshacer.'),
          const SizedBox(height: 16),
          const Text('Escribe $kDeleteAccountConfirmation para confirmar:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            key: const Key('delete-account-confirmation'),
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: kDeleteAccountConfirmation),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        TextButton(
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
          child: const Text('Eliminar cuenta'),
        ),
      ],
    );
  }
}

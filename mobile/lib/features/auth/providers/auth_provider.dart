import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
import '../../auth/screens/login_screen.dart';

class KazaAuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final String? fullName;
  final String activeWorkspaceName;
  final bool isOrganization;

  KazaAuthState({
    this.isAuthenticated = false,
    this.userId,
    this.email,
    this.fullName,
    this.activeWorkspaceName = 'Personal Workspace',
    this.isOrganization = false,
  });

  KazaAuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? email,
    String? fullName,
    String? activeWorkspaceName,
    bool? isOrganization,
  }) {
    return KazaAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      activeWorkspaceName: activeWorkspaceName ?? this.activeWorkspaceName,
      isOrganization: isOrganization ?? this.isOrganization,
    );
  }
}

class KazaAuthNotifier extends StateNotifier<KazaAuthState> {
  KazaAuthNotifier() : super(KazaAuthState()) {
    _initSupabaseAuth();
  }

  void _initSupabaseAuth() {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user != null) {
        _setUser(user);
      }
      SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
        final sessionUser = data.session?.user;
        if (sessionUser != null) {
          _setUser(sessionUser);
        } else if (data.event == AuthChangeEvent.signedOut) {
          logout();
        }
      });
    } catch (_) {}
  }

  Future<void> _setUser(User user) async {
    final name = user.userMetadata?['full_name'] ??
        user.userMetadata?['name'] ??
        user.email?.split('@').first ??
        'Usuario Verificado';
    final email = user.email ?? 'usuario@kaza.bo';

    state = state.copyWith(
      isAuthenticated: true,
      userId: user.id,
      email: email,
      fullName: name,
    );

    // Persistir usuario en la tabla profiles de Supabase DB mediante RPC SECURITY DEFINER
    try {
      await SupabaseConfig.client.rpc('fn_upsert_profile', params: {
        'p_email': email,
        'p_full_name': name,
        'p_role': 'USER',
      });
    } catch (_) {
      try {
        await SupabaseConfig.client.from('profiles').upsert({
          'email': email,
          'full_name': name,
          'role': 'USER',
        });
      } catch (_) {}
    }
  }

  Future<void> loginDemoUser({required String email, String? name}) async {
    final fullName = name ?? email.split('@').first;
    state = state.copyWith(
      isAuthenticated: true,
      userId: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: fullName,
    );

    // Persistir usuario en la tabla profiles de Supabase DB mediante RPC SECURITY DEFINER
    try {
      await SupabaseConfig.client.rpc('fn_upsert_profile', params: {
        'p_email': email,
        'p_full_name': fullName,
        'p_role': 'USER',
      });
    } catch (_) {
      try {
        await SupabaseConfig.client.from('profiles').upsert({
          'email': email,
          'full_name': fullName,
          'role': 'USER',
        });
      } catch (_) {}
    }
  }

  void switchWorkspace(String workspaceName, bool isOrg) {
    state = state.copyWith(
      activeWorkspaceName: workspaceName,
      isOrganization: isOrg,
    );
  }

  void logout() {
    try {
      SupabaseConfig.client.auth.signOut();
    } catch (_) {}
    state = KazaAuthState();
  }
}

final kazaAuthProvider = StateNotifierProvider<KazaAuthNotifier, KazaAuthState>((ref) {
  return KazaAuthNotifier();
});

/// Helper para Registro Progresivo Kaza Master v0.2
/// "Explora primero; regístrate cuando necesites conservar o avanzar."
void checkProgressiveAuth({
  required BuildContext context,
  required WidgetRef ref,
  required String actionName,
  required VoidCallback onAuthenticatedAction,
}) {
  final authState = ref.read(kazaAuthProvider);

  if (authState.isAuthenticated) {
    onAuthenticatedAction();
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: KazaTheme.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: KazaTheme.glassBorder, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: KazaTheme.primaryTealLight, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Registrarme para $actionName',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'En Kaza puedes explorar el mapa, filtros y propiedades libremente. La autenticación solo se requiere cuando deseas conservar o avanzar un trámite.',
              style: TextStyle(color: KazaTheme.textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KazaTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.login),
                label: const Text('Iniciar Sesión / Registrarme', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                  if (ref.read(kazaAuthProvider).isAuthenticated) {
                    onAuthenticatedAction();
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Seguir explorando sin cuenta', style: TextStyle(color: KazaTheme.textMuted)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
import '../providers/auth_provider.dart';

/// 🔐 U02 CREACIÓN DE CUENTA - Secuencia Wizard sin roles ni contraseña.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(kazaAuthProvider);
      if (authState.isAuthenticated) {
        if (_nameController.text.isEmpty && authState.fullName != null) {
          _nameController.text = authState.fullName!;
        }
        if (_pageController.hasClients && _pageController.page == 0) {
          _pageController.jumpToPage(1);
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleAuth() async {
    setState(() => _isLoading = true);
    try {
      final redirectUrl = kIsWeb ? Uri.base.origin : null;
      await SupabaseConfig.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
      // Tras la redirección, el stream de authStateChange de Supabase (en auth_provider)
      // detectará la sesión, actualizará el estado y disparará el ref.listen de abajo.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al conectar con Google: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBasicDataAndContinue() async {
    setState(() => _isLoading = true);
    final authState = ref.read(kazaAuthProvider);
    try {
      // Actualizamos el perfil usando el RPC existente pero le pasamos el teléfono adicional
      await SupabaseConfig.client.rpc('fn_upsert_profile', params: {
        'p_email': authState.email ?? '',
        'p_full_name': _nameController.text.trim(),
        'p_system_role': 'USER',
        'p_is_agent': false,
        'p_phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      });
      _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar datos: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios de autenticación para avanzar al paso 2 (Datos Básicos)
    ref.listen<KazaAuthState>(kazaAuthProvider, (previous, next) {
      if (next.isAuthenticated && (previous?.isAuthenticated != true)) {
        // Pre-llenar el nombre si lo tenemos de Google
        if (_nameController.text.isEmpty && next.fullName != null) {
          _nameController.text = next.fullName!;
        }
        // Avanzar a la pantalla de datos básicos
        if (_pageController.hasClients && _pageController.page == 0) {
          _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Autenticación Kaza'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Evitar swipe manual
        children: [
          _buildStep1Welcome(),
          _buildStep2BasicData(),
          _buildStep3Success(),
        ],
      ),
    );
  }

  // PASO 01: BIENVENIDA Y ELEGIR MÉTODO
  Widget _buildStep1Welcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.home, size: 80, color: KazaTheme.primaryTeal),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: KazaTheme.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: KazaTheme.glassBorder),
            ),
            child: Column(
              children: [
                const Text(
                  '¿Cómo quieres crear tu cuenta?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'KAZA utiliza identidad digital única y segura.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: KazaTheme.textMuted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 30),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _handleGoogleAuth,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.g_mobiledata, size: 32, color: Color(0xFF4285F4)),
                          SizedBox(width: 10),
                          Text(
                            'Continuar con Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'El método de registro será tu identificador principal. No se solicitarán contraseñas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: KazaTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // PASO 03: DATOS BÁSICOS
  Widget _buildStep2BasicData() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: KazaTheme.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: KazaTheme.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_outline, color: KazaTheme.primaryTealLight),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Datos Básicos',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Confirma tu información para completar tu Cuenta KAZA.',
                  style: TextStyle(color: KazaTheme.textMuted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre y Apellidos *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono de Contacto (Opcional)',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 28),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KazaTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _saveBasicDataAndContinue,
                      child: const Text('Confirmar y Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // PASO 07: CUENTA CREADA
  Widget _buildStep3Success() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: KazaTheme.primaryTealLight.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, size: 80, color: KazaTheme.primaryTealLight),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Cuenta Creada!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tu identidad digital única está lista. Ya puedes usar KAZA.',
            textAlign: TextAlign.center,
            style: TextStyle(color: KazaTheme.textMuted, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KazaTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // Navega al flujo de Onboarding U03 usando GoRouter
                context.go('/onboarding');
              },
              child: const Text('Comenzar a explorar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

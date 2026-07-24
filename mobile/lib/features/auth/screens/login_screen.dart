import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/kaza_theme.dart';
import '../providers/auth_provider.dart';

/// 🔐 LOGIN & REGISTRO PROGRESIVO - Screen oficial de Autenticación
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController(text: 'mi.cuenta@kaza.app');
  final TextEditingController _passwordController = TextEditingController(text: 'password123');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleAuthSubmit() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      ref.read(kazaAuthProvider.notifier).loginDemoUser(
        email: email,
        name: 'Usuario Kaza Pro',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Sesión iniciada exitosamente en Kaza'),
          backgroundColor: KazaTheme.primaryTeal,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autenticación Kaza'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: KazaTheme.primaryTealLight,
          labelColor: KazaTheme.primaryTealLight,
          unselectedLabelColor: KazaTheme.textMuted,
          tabs: const [
            Tab(text: 'Iniciar Sesión'),
            Tab(text: 'Crear Cuenta'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Iniciar Sesión
          _buildLoginForm(isRegister: false),
          // Tab 2: Crear Cuenta
          _buildLoginForm(isRegister: true),
        ],
      ),
    );
  }

  Widget _buildLoginForm({required bool isRegister}) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: KazaTheme.primaryTeal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: KazaTheme.primaryTealLight, width: 2),
            ),
            child: const Icon(Icons.home_work, color: KazaTheme.primaryTealLight, size: 36),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isRegister ? 'Crear tu Cuenta Kaza' : 'Bienvenido de nuevo a Kaza',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Explora primero; regístrate solo cuando desees conservar o avanzar.',
          textAlign: TextAlign.center,
          style: TextStyle(color: KazaTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 32),

        // Email field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo Electrónico o Teléfono',
            prefixIcon: Icon(Icons.email_outlined, color: KazaTheme.primaryTealLight),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Password field
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: Icon(Icons.lock_outline, color: KazaTheme.primaryTealLight),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 24),

        // Submit Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: KazaTheme.primaryTeal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _handleAuthSubmit,
          child: Text(
            isRegister ? 'Completar Registro' : 'Ingresar a mi Cuenta',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 24),
        const Row(
          children: [
            Expanded(child: Divider(color: KazaTheme.glassBorder)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('o continúa con', style: TextStyle(color: KazaTheme.textMuted, fontSize: 12)),
            ),
            Expanded(child: Divider(color: KazaTheme.glassBorder)),
          ],
        ),
        const SizedBox(height: 20),

        // Social Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                icon: const Icon(Icons.g_mobiledata, size: 24),
                label: const Text('Google'),
                onPressed: _handleAuthSubmit,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                icon: const Icon(Icons.apple, size: 24),
                label: const Text('Apple'),
                onPressed: _handleAuthSubmit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

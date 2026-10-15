import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
import '../../../core/utils/auth_url_cleanup_stub.dart'
    if (dart.library.html) '../../../core/utils/auth_url_cleanup_web.dart';
import '../providers/auth_provider.dart';

/// 🔐 U02 CREACIÓN DE CUENTA - Secuencia Alineada con Diseño
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _isLoading = false;
  bool _isLoginMode = false;
  bool _checkingAccount = false;
  int _page = 0;
  String? _notice;
  Uint8List? _avatarBytes;
  String? _avatarName;

  static const _registrationSteps = 4; // datos, cuenta creada, perfil, listo

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final p = _pageController.page?.round() ?? 0;
      if (p != _page) setState(() => _page = p);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveSignedInUser());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_pageController.hasClients) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _goTo(int page) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(page,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  /// Google sign-in creates the Auth user on first use, so a "login" with a
  /// new email silently becomes a signup. Decide by the profile instead:
  /// finished registration → welcome back; otherwise → registration form.
  Future<void> _resolveSignedInUser() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null || _checkingAccount || _page >= 2) return;
    _checkingAccount = true;
    final intent = takeAuthIntent();
    final authState = ref.read(kazaAuthProvider);

    if (_nameController.text.isEmpty && authState.fullName != null) {
      final parts = authState.fullName!.trim().split(RegExp(r'\s+'));
      _nameController.text = parts.first;
      if (parts.length > 1) _lastNameController.text = parts.sublist(1).join(' ');
    }
    if (_emailController.text.isEmpty) {
      _emailController.text = user.email ?? authState.email ?? '';
    }

    String? status;
    try {
      final row = await SupabaseConfig.client
          .from('profiles')
          .select('onboarding_status')
          .eq('id', user.id)
          .maybeSingle();
      status = row?['onboarding_status'] as String?;
    } catch (_) {}
    _checkingAccount = false;
    if (!mounted) return;

    if (status == 'COMPLETED' || status == 'SKIPPED') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(intent == 'signup'
            ? 'Ya tienes una cuenta KAZA con este correo. ¡Bienvenido de nuevo!'
            : '¡Bienvenido de nuevo a KAZA!'),
        backgroundColor: KazaTheme.azulKaza,
        behavior: SnackBarBehavior.floating,
      ));
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        context.go('/map');
      }
      return;
    }

    setState(() {
      _isLoginMode = false;
      _notice = intent == 'login'
          ? 'Aún no tienes una cuenta KAZA con ${_emailController.text}. Completa tu registro para continuar.'
          : null;
    });
    if (_pageController.hasClients) _pageController.jumpToPage(2);
  }

  Future<void> _handleGoogleAuth() async {
    setState(() => _isLoading = true);
    saveAuthIntent(_isLoginMode ? 'login' : 'signup');
    try {
      final redirectUrl = kIsWeb ? Uri.base.origin : null;
      await SupabaseConfig.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBasicDataAndContinue() async {
    if (_nameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Por favor completa tu nombre y apellidos'),
          backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final fullName =
          '${_nameController.text.trim()} ${_lastNameController.text.trim()}';
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      await SupabaseConfig.client.rpc('fn_upsert_profile', params: {
        'p_id': user.id,
        'p_email': _emailController.text.trim(),
        'p_full_name': fullName,
        'p_system_role': 'USER',
        'p_is_agent': false,
        'p_phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      });
      _nextPage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al guardar: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seleccionar foto de perfil',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: KazaTheme.textPrimary)),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: KazaTheme.primaryTeal.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child:
                    const Icon(Icons.camera_alt, color: KazaTheme.primaryTeal),
              ),
              title: const Text('Tomar foto con la cámara',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                _processImagePick(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: KazaTheme.azulKaza.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child:
                    const Icon(Icons.photo_library, color: KazaTheme.azulKaza),
              ),
              title: const Text('Elegir de la galería',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                _processImagePick(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _processImagePick(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _avatarBytes = bytes;
        _avatarName = pickedFile.name;
      });
    }
  }

  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      final response = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final road = address['road'] ??
              address['pedestrian'] ??
              address['suburb'] ??
              address['neighbourhood'] ??
              address['city_district'];
          final city = address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'];
          if (road != null && city != null) {
            return '$road, $city';
          } else if (road != null) {
            return road.toString();
          }
        }
        return data['display_name'] ?? '$lat, $lng';
      }
    } catch (_) {}
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  void _showLocationPicker() {
    LatLng currentCenter = const LatLng(-17.7833, -63.1821);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: KazaTheme.primaryTeal, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Selecciona tu ubicación',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: KazaTheme.textPrimary)),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.close, color: KazaTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                      'Mueve el mapa para ajustar tu ubicación pública principal. Esto nos ayudará a mostrarte resultados relevantes.',
                      style: TextStyle(
                          color: KazaTheme.textSecondary, fontSize: 14)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24)),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: currentCenter,
                            initialZoom: 13,
                            onPositionChanged: (position, hasGesture) {
                              if (position.center != null) {
                                currentCenter = position.center!;
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.kaza.app',
                            ),
                          ],
                        ),
                        const Icon(Icons.location_on,
                            color: KazaTheme.coralKaza, size: 48),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KazaTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        // Opcionalmente se podría mostrar un loader aquí, pero Nominatim es rápido
                        final address = await _getAddressFromCoordinates(
                            currentCenter.latitude, currentCenter.longitude);
                        setState(() {
                          _locationController.text = address;
                        });
                        if (context.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Confirmar Ubicación',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfileSettings() async {
    setState(() => _isLoading = true);
    try {
      String? avatarUrl;
      final authState = ref.read(kazaAuthProvider);
      final email = authState.email ?? _emailController.text.trim();

      if (_avatarBytes != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$_avatarName';
        final filePath = '$email/$fileName';

        await SupabaseConfig.client.storage.from('avatars').uploadBinary(
              filePath,
              _avatarBytes!,
              fileOptions:
                  const FileOptions(contentType: 'image/jpeg', upsert: true),
            );
        avatarUrl = SupabaseConfig.client.storage
            .from('avatars')
            .getPublicUrl(filePath);
      }

      await SupabaseConfig.client.rpc('fn_update_profile_settings', params: {
        'p_email': email,
        'p_avatar_url': avatarUrl,
        'p_biography': _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        'p_location': _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
      });

      _nextPage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al guardar ajustes: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── UI HELPERS ─────────────────────────────────────────────────────────────

  Widget _glow(Color color, double size, double alpha) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: KazaTheme.azulKaza.withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  /// Centers a step and keeps it readable on wide screens.
  Widget _stepScaffold(List<Widget> children, {bool center = false}) {
    return LayoutBuilder(builder: (context, c) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: center ? c.maxHeight - 40 : 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _stepHeader(IconData icon, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: KazaTheme.coralKaza.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: KazaTheme.coralKaza, size: 22),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: KazaTheme.azulKaza)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: const TextStyle(fontSize: 14, height: 1.45, color: KazaTheme.textSecondary)),
      ],
    );
  }

  InputDecoration _input(String label, IconData icon, {Widget? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: KazaTheme.textSecondary, fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: KazaTheme.grisMedio),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(KazaTheme.azulKaza.withValues(alpha: 0.1)),
      enabledBorder: border(KazaTheme.azulKaza.withValues(alpha: 0.1)),
      disabledBorder: border(KazaTheme.azulKaza.withValues(alpha: 0.06)),
      focusedBorder: border(KazaTheme.coralKaza, 1.5),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed, {IconData? icon}) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: KazaTheme.coralKaza,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _isLoading ? null : onPressed,
        child: _isLoading
            ? const SizedBox(
                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 20)],
                ],
              ),
      ),
    );
  }

  Widget _secondaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: KazaTheme.azulKaza,
          backgroundColor: Colors.white.withValues(alpha: 0.6),
          side: BorderSide(color: KazaTheme.azulKaza.withValues(alpha: 0.15)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Native OAuth finishes while this screen stays mounted.
    ref.listen<KazaAuthState>(kazaAuthProvider, (prev, next) {
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        _resolveSignedInUser();
      }
    });

    final inRegistration = _page >= 2;
    final progress = inRegistration ? (_page - 1) / _registrationSteps : 0.0;

    return Scaffold(
      backgroundColor: KazaTheme.grisClaro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: _page == 1 ? 'Volver' : 'Cerrar',
          icon: Icon(_page == 1 ? Icons.arrow_back_ios_new_rounded : Icons.close_rounded,
              color: KazaTheme.azulKaza, size: 22),
          onPressed: () {
            if (_page == 1) {
              _goTo(0);
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/map');
            }
          },
        ),
        title: inRegistration
            ? Text('Paso ${_page - 1} de $_registrationSteps',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: KazaTheme.textSecondary))
            : null,
        bottom: inRegistration
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: progress),
                          duration: const Duration(milliseconds: 300),
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            minHeight: 4,
                            color: KazaTheme.coralKaza,
                            backgroundColor: KazaTheme.azulKaza.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned(top: -140, right: -120, child: _glow(KazaTheme.coralKaza, 420, 0.22)),
          Positioned(bottom: -160, left: -140, child: _glow(KazaTheme.azulKaza, 480, 0.14)),
          Positioned(top: 260, left: -120, child: _glow(KazaTheme.accentGold, 320, 0.2)),
          Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + (inRegistration ? 4 : 0)),
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
              _buildStep01Bienvenida(),
              _buildStep02Metodo(),
              _buildStep03DatosBasicos(),
              _buildStep07CuentaCreada(),
              _buildStep09AjustesBasicos(),
              _buildStep10Listo(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE PASOS ---

  // PASO 01: BIENVENIDA
  Widget _buildStep01Bienvenida() {
    Widget benefit(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: KazaTheme.azulKaza.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: KazaTheme.azulKaza),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text,
                    style: const TextStyle(fontSize: 14, color: KazaTheme.azulKaza, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        );

    return _stepScaffold(center: true, [
      _glassCard(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset(
                'assets/images/kaza_logo_tagline.png',
                width: 170,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.home_rounded, size: 72, color: KazaTheme.coralKaza),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Tu próximo lugar empieza aquí',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: KazaTheme.azulKaza),
            ),
            const SizedBox(height: 8),
            const Text(
              'Una sola identidad KAZA, segura y sin contraseñas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.45, color: KazaTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            benefit(Icons.bookmark_border_rounded, 'Guarda y compara propiedades'),
            benefit(Icons.chat_bubble_outline_rounded, 'Habla directo con anunciantes'),
            benefit(Icons.lock_outline_rounded, 'Entras con Google, sin contraseñas'),
            const SizedBox(height: 12),
            _primaryButton('Crear cuenta', () {
              setState(() => _isLoginMode = false);
              _nextPage();
            }),
            const SizedBox(height: 12),
            _secondaryButton('Ya tengo cuenta · Iniciar sesión', () {
              setState(() => _isLoginMode = true);
              _nextPage();
            }),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Puedes seguir explorando el mapa sin cuenta.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: KazaTheme.textSecondary),
      ),
    ]);
  }

  // PASO 02: ELEGIR MÉTODO
  Widget _buildStep02Metodo() {
    return _stepScaffold(center: true, [
      _glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stepHeader(
              _isLoginMode ? Icons.login_rounded : Icons.person_add_alt_1_rounded,
              _isLoginMode ? 'Inicia sesión' : 'Crea tu cuenta',
              _isLoginMode
                  ? 'Entra con la cuenta de Google que usaste para registrarte. Si aún no tienes cuenta, te llevaremos al registro.'
                  : 'Usaremos tu cuenta de Google como identificador. No necesitas contraseña.',
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: KazaTheme.azulKaza,
                  side: BorderSide(color: KazaTheme.azulKaza.withValues(alpha: 0.15)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isLoading ? null : _handleGoogleAuth,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: KazaTheme.coralKaza))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('G',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF4285F4))),
                          SizedBox(width: 12),
                          Text('Continuar con Google',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 14, color: KazaTheme.textSecondary),
                    children: [
                      TextSpan(text: _isLoginMode ? '¿No tienes cuenta? ' : '¿Ya tienes cuenta? '),
                      TextSpan(
                        text: _isLoginMode ? 'Crear una' : 'Inicia sesión',
                        style: const TextStyle(color: KazaTheme.coralKaza, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, size: 14, color: KazaTheme.textSecondary),
          SizedBox(width: 6),
          Flexible(
            child: Text('Tu correo de Google será tu identificador en KAZA.',
                style: TextStyle(fontSize: 12, color: KazaTheme.textSecondary)),
          ),
        ],
      ),
    ]);
  }

  // PASO 03: DATOS BÁSICOS
  Widget _buildStep03DatosBasicos() {
    return _stepScaffold([
      const SizedBox(height: 12),
      if (_notice != null) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: KazaTheme.coralKaza.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: KazaTheme.coralKaza.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 20, color: KazaTheme.coralKaza),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_notice!,
                    style: const TextStyle(fontSize: 13, height: 1.4, color: KazaTheme.azulKaza)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
      _glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stepHeader(Icons.person_outline_rounded, 'Completa tus datos',
                'Así te verán los anunciantes cuando los contactes.'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _input('Nombre *', Icons.person_rounded),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lastNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _input('Apellidos *', Icons.badge_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailController,
              enabled: false, // Sólo lectura desde Google
              decoration: _input('Correo electrónico', Icons.mail_outline_rounded,
                  suffix: const Icon(Icons.lock_outline_rounded, size: 18, color: KazaTheme.grisMedio)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _input('Teléfono de contacto', Icons.phone_outlined),
            ),
            const SizedBox(height: 24),
            _primaryButton('Continuar', _saveBasicDataAndContinue, icon: Icons.arrow_forward_rounded),
          ],
        ),
      ),
    ]);
  }

  // PASO 07: CUENTA CREADA
  Widget _buildStep07CuentaCreada() {
    return _stepScaffold(center: true, [
      _glassCard(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: KazaTheme.verdeEntorno.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 48, color: KazaTheme.verdeEntorno),
              ),
            ),
            const SizedBox(height: 20),
            const Text('¡Cuenta creada!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: KazaTheme.azulKaza)),
            const SizedBox(height: 8),
            const Text('Tu identidad KAZA está lista. Un paso más para personalizar tu perfil.',
                textAlign: TextAlign.center,
                style: TextStyle(color: KazaTheme.textSecondary, fontSize: 14, height: 1.45)),
            const SizedBox(height: 28),
            _primaryButton('Continuar', _nextPage, icon: Icons.arrow_forward_rounded),
          ],
        ),
      ),
    ]);
  }

  // PASO 09: AJUSTES BÁSICOS
  Widget _buildStep09AjustesBasicos() {
    return _stepScaffold([
      const SizedBox(height: 12),
      _glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _stepHeader(Icons.tune_rounded, 'Completa tu perfil',
                      'Opcional. Puedes cambiarlo cuando quieras.'),
                ),
                TextButton(
                  onPressed: _nextPage,
                  child: const Text('Omitir',
                      style: TextStyle(color: KazaTheme.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: KazaTheme.azulKaza.withValues(alpha: 0.06),
                      backgroundImage: _avatarBytes != null ? MemoryImage(_avatarBytes!) : null,
                      child: _avatarBytes == null
                          ? const Icon(Icons.person_rounded, size: 40, color: KazaTheme.grisMedio)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: KazaTheme.coralKaza,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
                child: Text('Foto de perfil', style: TextStyle(fontSize: 12, color: KazaTheme.textSecondary))),
            const SizedBox(height: 22),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: _input('Biografía (opcional)', Icons.edit_note_rounded),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _showLocationPicker,
              child: AbsorbPointer(
                child: TextField(
                  controller: _locationController,
                  decoration: _input('Ubicación (opcional)', Icons.location_on_outlined,
                      suffix: const Icon(Icons.map_outlined, color: KazaTheme.coralKaza)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _primaryButton('Guardar', _saveProfileSettings),
          ],
        ),
      ),
    ]);
  }

  // PASO 10: LISTO
  Widget _buildStep10Listo() {
    return _stepScaffold(center: true, [
      _glassCard(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: KazaTheme.coralKaza.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.rocket_launch_rounded, size: 44, color: KazaTheme.coralKaza),
              ),
            ),
            const SizedBox(height: 20),
            const Text('¡Todo listo!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: KazaTheme.azulKaza)),
            const SizedBox(height: 8),
            const Text('Tu cuenta KAZA está lista para acompañarte.',
                textAlign: TextAlign.center,
                style: TextStyle(color: KazaTheme.textSecondary, fontSize: 14, height: 1.45)),
            const SizedBox(height: 28),
            _primaryButton('Explorar KAZA', () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/onboarding');
              }
            }, icon: Icons.arrow_forward_rounded),
          ],
        ),
      ),
    ]);
  }
}

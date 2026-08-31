import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
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
  Uint8List? _avatarBytes;
  String? _avatarName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(kazaAuthProvider);
      if (authState.isAuthenticated) {
        // Pre-llenar datos de Google
        if (_nameController.text.isEmpty && authState.fullName != null) {
          final parts = authState.fullName!.split(' ');
          _nameController.text = parts.first;
          if (parts.length > 1) {
            _lastNameController.text = parts.sublist(1).join(' ');
          }
        }
        if (_emailController.text.isEmpty && authState.email != null) {
          _emailController.text = authState.email!;
        }
        
        // Si tiene sesión activa y aterriza aquí, saltar a Datos Básicos (Paso 2)
        if (_pageController.hasClients && _pageController.page == 0) {
          _pageController.jumpToPage(2);
        }
      }
    });
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
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() => _isLoading = true);
    try {
      final redirectUrl = kIsWeb ? Uri.base.origin : null;
      await SupabaseConfig.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBasicDataAndContinue() async {
    if (_nameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa tu nombre y apellidos'), backgroundColor: Colors.redAccent)
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final fullName = '${_nameController.text.trim()} ${_lastNameController.text.trim()}';
      
      await SupabaseConfig.client.rpc('fn_upsert_profile', params: {
        'p_email': _emailController.text.trim(),
        'p_full_name': fullName,
        'p_system_role': 'USER',
        'p_is_agent': false,
        'p_phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      });
      _nextPage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _avatarBytes = bytes;
        _avatarName = pickedFile.name;
      });
    }
  }

  Future<void> _saveProfileSettings() async {
    setState(() => _isLoading = true);
    try {
      String? avatarUrl;
      final authState = ref.read(kazaAuthProvider);
      final email = authState.email ?? _emailController.text.trim();
      
      if (_avatarBytes != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$_avatarName';
        final filePath = '$email/$fileName';
        
        await SupabaseConfig.client.storage.from('avatars').uploadBinary(
          filePath,
          _avatarBytes!,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
        avatarUrl = SupabaseConfig.client.storage.from('avatars').getPublicUrl(filePath);
      }

      await SupabaseConfig.client.rpc('fn_update_profile_settings', params: {
        'p_email': email,
        'p_avatar_url': avatarUrl,
        'p_biography': _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        'p_location': _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      });
      
      _nextPage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar ajustes: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Creación de Cuenta KAZA'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: PageView(
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
    );
  }

  // --- WIDGETS DE PASOS ---

  // PASO 01: BIENVENIDA
  Widget _buildStep01Bienvenida() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.home, size: 100, color: KazaTheme.primaryTeal),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Más que un lugar.',
            style: TextStyle(fontSize: 16, color: KazaTheme.textMuted, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 60),
          const Text(
            '¡Crea tu cuenta!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'KAZA utiliza identidad digital única y segura. Sin roles ni planes, solo tú.',
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
              onPressed: _nextPage,
              child: const Text('Crear cuenta nueva', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // PASO 02: ELEGIR MÉTODO
  Widget _buildStep02Metodo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _handleGoogleAuth,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.g_mobiledata, size: 32, color: Color(0xFF4285F4)),
                          SizedBox(width: 10),
                          Text('Continuar con Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
  Widget _buildStep03DatosBasicos() {
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
                      child: Text('Completa tus datos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre *', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Apellidos *', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  enabled: false, // Sólo lectura desde Google
                  decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono de Contacto', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
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
                      child: const Text('Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
  Widget _buildStep07CuentaCreada() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: KazaTheme.primaryTealLight.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline, size: 80, color: KazaTheme.primaryTealLight),
          ),
          const SizedBox(height: 24),
          const Text('¡Cuenta Creada!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Tu identidad digital única está lista. Ya puedes usar KAZA.', textAlign: TextAlign.center, style: TextStyle(color: KazaTheme.textMuted, fontSize: 14, height: 1.4)),
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
              onPressed: _nextPage,
              child: const Text('Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // PASO 09: AJUSTES BÁSICOS
  Widget _buildStep09AjustesBasicos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _nextPage,
              child: const Text('Omitir', style: TextStyle(color: KazaTheme.textMuted)),
            ),
          ),
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
                    Icon(Icons.settings_outlined, color: KazaTheme.primaryTealLight),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Completa tu perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _avatarBytes != null ? MemoryImage(_avatarBytes!) : null,
                      child: _avatarBytes == null ? const Icon(Icons.camera_alt, color: Colors.grey) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(child: Text('Foto de perfil', style: TextStyle(fontSize: 12, color: KazaTheme.textMuted))),
                const SizedBox(height: 24),
                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Biografía (opcional)', prefixIcon: Icon(Icons.edit_note), border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Ubicación (opcional)', prefixIcon: Icon(Icons.location_on_outlined), border: OutlineInputBorder()),
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
                      onPressed: _saveProfileSettings,
                      child: const Text('Guardar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // PASO 10: LISTO
  Widget _buildStep10Listo() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rocket_launch, size: 80, color: KazaTheme.primaryTealLight),
          const SizedBox(height: 24),
          const Text('¡Listo!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Tu Cuenta KAZA está lista para acompañarte.', textAlign: TextAlign.center, style: TextStyle(color: KazaTheme.textMuted, fontSize: 14, height: 1.4)),
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
              onPressed: () => context.go('/onboarding'),
              child: const Text('Explorar KAZA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

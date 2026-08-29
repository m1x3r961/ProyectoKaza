import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/network/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';

/// U03 - ONBOARDING INICIAL
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _isLoading = false;

  // Preferences State
  final List<String> _selectedPropertyTypes = [];
  final List<String> _selectedGoals = [];
  final List<String> _selectedAreas = [];
  bool _notifNewProperties = true;
  bool _notifPriceChanges = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    // Avanzar a la pantalla de "Procesando" (Paso 6 visualmente)
    _pageController.animateToPage(5, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

    try {
      final authState = ref.read(kazaAuthProvider);
      await SupabaseConfig.client.rpc('fn_complete_onboarding', params: {
        'p_email': authState.email ?? '',
        'p_status': 'COMPLETED',
        'p_property_types': _selectedPropertyTypes,
        'p_goals': _selectedGoals,
        'p_areas': _selectedAreas,
        'p_notifications': {
          'new_properties': _notifNewProperties,
          'price_changes': _notifPriceChanges,
        },
      });
      // Esperar un poco para el efecto de carga
      await Future.delayed(const Duration(seconds: 2));
      // Avanzar a ¡LISTO!
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _skipOnboarding() async {
    // Guarda status como SKIPPED
    try {
      final authState = ref.read(kazaAuthProvider);
      await SupabaseConfig.client.rpc('fn_complete_onboarding', params: {
        'p_email': authState.email ?? '',
        'p_status': 'SKIPPED',
      });
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skipOnboarding,
                child: const Text('Omitir', style: TextStyle(color: KazaTheme.textMuted)),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep01Welcome(),
                  _buildStep02BasicPrefs(),
                  _buildStep03Areas(),
                  _buildStep04Notifications(),
                  _buildStep05Permissions(),
                  _buildStep06Processing(),
                  _buildStep07Done(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 01 BIENVENIDA
  Widget _buildStep01Welcome() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.waving_hand, size: 80, color: KazaTheme.primaryTealLight),
          const SizedBox(height: 24),
          const Text('Te damos la bienvenida', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            'Descubre, guarda y compara propiedades que encajan contigo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: KazaTheme.textMuted, fontSize: 16),
          ),
          const Spacer(),
          _buildPrimaryButton('Comenzar', _nextPage),
        ],
      ),
    );
  }

  // 02 PREFERENCIAS BÁSICAS
  Widget _buildStep02BasicPrefs() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿Qué te interesa?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Selecciona las categorías para personalizar tu búsqueda.', style: TextStyle(color: KazaTheme.textMuted)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFilterChip('Casa', _selectedPropertyTypes),
              _buildFilterChip('Departamento', _selectedPropertyTypes),
              _buildFilterChip('Terreno', _selectedPropertyTypes),
              _buildFilterChip('Local', _selectedPropertyTypes),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Fines de búsqueda', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFilterChip('Comprar', _selectedGoals),
              _buildFilterChip('Alquilar', _selectedGoals),
              _buildFilterChip('Invertir', _selectedGoals),
            ],
          ),
          const Spacer(),
          _buildPrimaryButton('Continuar', _nextPage),
        ],
      ),
    );
  }

  // 03 ÁREA DE INTERÉS
  Widget _buildStep03Areas() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿Dónde te interesa explorar?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar zonas, barrios...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (val) {
              if (val.isNotEmpty) {
                setState(() => _selectedAreas.add(val));
              }
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _selectedAreas.map((e) => Chip(
              label: Text(e),
              onDeleted: () => setState(() => _selectedAreas.remove(e)),
            )).toList(),
          ),
          const Spacer(),
          _buildPrimaryButton('Continuar', _nextPage),
        ],
      ),
    );
  }

  // 04 NOTIFICACIONES
  Widget _buildStep04Notifications() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿Qué notificaciones quieres recibir?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Nuevas propiedades'),
            subtitle: const Text('Que coincidan con tu búsqueda'),
            value: _notifNewProperties,
            onChanged: (val) => setState(() => _notifNewProperties = val),
          ),
          SwitchListTile(
            title: const Text('Cambios de precios'),
            subtitle: const Text('En propiedades guardadas'),
            value: _notifPriceChanges,
            onChanged: (val) => setState(() => _notifPriceChanges = val),
          ),
          const Spacer(),
          _buildPrimaryButton('Continuar', _nextPage),
        ],
      ),
    );
  }

  // 05 PERMISOS
  Widget _buildStep05Permissions() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Configura tus permisos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tú decides qué quieres conceder.', style: TextStyle(color: KazaTheme.textMuted)),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.location_on, color: KazaTheme.primaryTealLight),
            title: const Text('Ubicación'),
            subtitle: const Text('Para mostrar propiedades cercanas'),
            trailing: TextButton(onPressed: (){}, child: const Text('Permitir')),
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: KazaTheme.primaryTealLight),
            title: const Text('Notificaciones'),
            subtitle: const Text('Para mantenerte informado'),
            trailing: TextButton(onPressed: (){}, child: const Text('Permitir')),
          ),
          const Spacer(),
          _buildPrimaryButton('Continuar', _completeOnboarding),
        ],
      ),
    );
  }

  // 06 PROCESANDO
  Widget _buildStep06Processing() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: KazaTheme.primaryTealLight),
        const SizedBox(height: 24),
        const Text('Personalizando tu experiencia...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // 07 LISTO
  Widget _buildStep07Done() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 80, color: KazaTheme.primaryTeal),
          const SizedBox(height: 24),
          const Text('¡Listo!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Tu experiencia KAZA está lista.', textAlign: TextAlign.center, style: TextStyle(color: KazaTheme.textMuted)),
          const Spacer(),
          _buildPrimaryButton('Explorar KAZA', () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, List<String> list) {
    final isSelected = list.contains(label);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          if (val) list.add(label);
          else list.remove(label);
        });
      },
      selectedColor: KazaTheme.primaryTealLight.withOpacity(0.2),
      checkmarkColor: KazaTheme.primaryTealLight,
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: KazaTheme.primaryTeal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

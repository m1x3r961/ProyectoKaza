import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import 'saved_screen.dart';
import 'comparator_screen.dart';

/// ⚖️ COMPARE TAB SCREEN — "14 GUARDADOS Y COMPARAR"
/// Landing page for the Compare tab. Shows saved properties
/// and allows selecting 2-3 to compare side by side.
class CompareTabScreen extends ConsumerStatefulWidget {
  const CompareTabScreen({super.key});

  @override
  ConsumerState<CompareTabScreen> createState() => _CompareTabScreenState();
}

class _CompareTabScreenState extends ConsumerState<CompareTabScreen> {
  String _tier = 'FREE';
  bool _isLoadingTier = true;

  @override
  void initState() {
    super.initState();
    _fetchTier();
  }

  Future<void> _fetchTier() async {
    try {
      final auth = ref.read(kazaAuthProvider);
      if (auth.userId == null) {
        if (mounted) setState(() => _isLoadingTier = false);
        return;
      }
      final resp = await SupabaseConfig.client
          .from('profiles')
          .select('subscription_tier')
          .eq('id', auth.userId!)
          .maybeSingle();

      if (resp != null && resp['subscription_tier'] != null) {
        if (mounted) {
          setState(() {
            _tier = resp['subscription_tier'] as String;
            _isLoadingTier = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingTier = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTier = false);
    }
  }

  void _onComparePressed(List<Map<String, dynamic>> savedItems) {
    if (savedItems.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas al menos 2 propiedades para comparar.'),
          backgroundColor: KazaTheme.primaryCoral,
        ),
      );
      return;
    }

    // Regla V1: comparación cuantitativa principal = misma operación + misma tipología.
    // Buscamos 2 propiedades que coincidan en operacion y tipologia
    Map<String, dynamic>? p1;
    Map<String, dynamic>? p2;

    for (int i = 0; i < savedItems.length; i++) {
      final prop1 = savedItems[i]['properties'] as Map<String, dynamic>?;
      if (prop1 == null) continue;
      
      final op1 = prop1['operation']?.toString().toUpperCase();
      final type1 = prop1['property_type']?.toString().toUpperCase();

      for (int j = i + 1; j < savedItems.length; j++) {
        final prop2 = savedItems[j]['properties'] as Map<String, dynamic>?;
        if (prop2 == null) continue;

        final op2 = prop2['operation']?.toString().toUpperCase();
        final type2 = prop2['property_type']?.toString().toUpperCase();

        if (op1 == op2 && type1 == type2) {
          p1 = prop1;
          p2 = prop2;
          break;
        }
      }
      if (p1 != null) break;
    }

    if (p1 != null && p2 != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ComparatorScreen(prop1: p1!, prop2: p2!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay 2 propiedades guardadas de la misma operación y tipología para comparar.'),
          backgroundColor: KazaTheme.accentGold,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedAsyncValue = ref.watch(savedPropertiesProvider);
    final isBusiness = _tier == 'BUSINESS';
    
    // Limits logic
    final limitText = isBusiness 
        ? 'Plan BUSINESS: Máx. 10 propiedades' 
        : (_tier == 'PRO' ? 'Plan PRO: Máx. 5 propiedades' : 'Límite Plan Free: Máx. 3 propiedades');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Comparar',
          style: TextStyle(
            color: KazaTheme.azulKaza,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: KazaTheme.n000,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.compare_arrows_rounded,
                  size: 48,
                  color: KazaTheme.azulKaza,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isBusiness ? 'Compara múltiples propiedades\nen paralelo' : 'Compara hasta 3 propiedades\nen paralelo',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: KazaTheme.azulKaza,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Guarda propiedades desde el mapa y\nselecciona las que deseas comparar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: KazaTheme.grisMedio,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              if (!_isLoadingTier)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isBusiness ? KazaTheme.accentGold.withOpacity(0.15) : KazaTheme.n100,
                    borderRadius: BorderRadius.circular(20),
                    border: isBusiness ? Border.all(color: KazaTheme.accentGold.withOpacity(0.5)) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBusiness ? Icons.star : Icons.info_outline, 
                        size: 16, 
                        color: isBusiness ? KazaTheme.accentGold : KazaTheme.textMuted
                      ),
                      const SizedBox(width: 6),
                      Text(
                        limitText,
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: isBusiness ? KazaTheme.accentGold : KazaTheme.textMuted
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KazaTheme.azulKaza,
                    side: const BorderSide(color: KazaTheme.azulKaza),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    savedAsyncValue.whenData((savedItems) {
                      _onComparePressed(savedItems);
                    });
                  },
                  icon: const Icon(Icons.compare_arrows_rounded, size: 20),
                  label: const Text(
                    'Ver comparador',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

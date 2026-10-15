import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';
import '../../../core/widgets/kaza_logo_widget.dart';

/// 📊 MAP EMPTY STATES — "17 ESTADOS DE SISTEMA"
/// Three system states: No Results, Searching, No Connection

/// State: No results found
class MapNoResultsState extends StatelessWidget {
  final VoidCallback onModifySearch;

  const MapNoResultsState({super.key, required this.onModifySearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KazaTheme.n000,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: KazaTheme.grisMedio,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No encontramos\npropiedades aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KazaTheme.azulKaza,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KazaTheme.coralKaza,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onModifySearch,
                child: const Text(
                  'Modificar búsqueda',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// State: Searching / Loading
class MapSearchingState extends StatelessWidget {
  const MapSearchingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: const KazaSymbolLogo(size: 50),
            ),
            const SizedBox(height: 20),
            const Text(
              'Buscando\npropiedades...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KazaTheme.azulKaza,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Discreet pill shown under the filters while the visible area refreshes.
class MapUpdatingPill extends StatelessWidget {
  const MapUpdatingPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: KazaTheme.coralKaza),
          ),
          SizedBox(width: 8),
          Text(
            'Actualizando propiedades…',
            style: TextStyle(color: KazaTheme.azulKaza, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// State: No connection
class MapNoConnectionState extends StatelessWidget {
  final VoidCallback onRetry;

  const MapNoConnectionState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KazaTheme.n000,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: KazaTheme.grisMedio,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin conexión',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KazaTheme.azulKaza,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Revisa tu conexión\na internet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KazaTheme.grisMedio,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KazaTheme.azulKaza,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onRetry,
                child: const Text(
                  'Reintentar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../app/theme/kaza_theme.dart';

/// 🔍 BUSCAR — Search Screen (Tab 2)
/// Dedicated search screen for finding properties by keyword, zone, or reference
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<_SearchSuggestion> _recentSearches = [
    _SearchSuggestion(icon: Icons.history, text: 'Departamento en Equipetrol'),
    _SearchSuggestion(icon: Icons.history, text: 'Casa 3 ambientes'),
    _SearchSuggestion(icon: Icons.history, text: 'Terreno Urubó'),
  ];

  final List<_SearchSuggestion> _popularZones = [
    _SearchSuggestion(icon: Icons.location_on_outlined, text: 'Equipetrol'),
    _SearchSuggestion(icon: Icons.location_on_outlined, text: 'Plan 3000'),
    _SearchSuggestion(icon: Icons.location_on_outlined, text: 'Urubó'),
    _SearchSuggestion(icon: Icons.location_on_outlined, text: 'Centro'),
    _SearchSuggestion(icon: Icons.location_on_outlined, text: 'Radial 26'),
    _SearchSuggestion(icon: Icons.location_on_outlined, text: 'Av. Banzer'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: KazaTheme.n000,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(Icons.search_rounded, color: KazaTheme.grisMedio, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        autofocus: false,
                        style: const TextStyle(fontSize: 14, color: KazaTheme.azulKaza),
                        decoration: const InputDecoration(
                          hintText: 'Buscar barrio, dirección o zona',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.close, color: KazaTheme.grisMedio, size: 20),
                        ),
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recent searches
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'Búsquedas recientes',
                style: TextStyle(
                  color: KazaTheme.azulKaza,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...(_recentSearches.map((s) => _buildSuggestionTile(s))),

            const SizedBox(height: 24),

            // Popular zones
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'Zonas populares',
                style: TextStyle(
                  color: KazaTheme.azulKaza,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _popularZones.map((zone) {
                  return GestureDetector(
                    onTap: () {
                      _searchController.text = zone.text;
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: KazaTheme.n000,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(zone.icon, size: 16, color: KazaTheme.azulKaza),
                          const SizedBox(width: 6),
                          Text(
                            zone.text,
                            style: const TextStyle(
                              color: KazaTheme.azulKaza,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(_SearchSuggestion suggestion) {
    return GestureDetector(
      onTap: () {
        _searchController.text = suggestion.text;
        setState(() {});
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(suggestion.icon, size: 20, color: KazaTheme.grisMedio),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                suggestion.text,
                style: const TextStyle(
                  color: KazaTheme.azulKaza,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.north_west, size: 16, color: KazaTheme.grisMedio),
          ],
        ),
      ),
    );
  }
}

class _SearchSuggestion {
  final IconData icon;
  final String text;
  const _SearchSuggestion({required this.icon, required this.text});
}

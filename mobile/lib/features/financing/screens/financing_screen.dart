import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/kaza_theme.dart';
import '../models/financing_models.dart';
import '../models/fintech_models.dart';
import '../services/fintech_api_service.dart';
import '../widgets/entity_detail_sheet.dart';
import 'kyc_verification_sheet.dart';
import 'credit_simulator_sheet.dart';

/// 01 DASHBOARD FINANCIERO (Hackathon Banco Unión)
/// Muestra Wallet P2P, Kaza Score, KYC y Entidades
class FinancingScreen extends StatefulWidget {
  const FinancingScreen({super.key});

  @override
  State<FinancingScreen> createState() => _FinancingScreenState();
}

class _FinancingScreenState extends State<FinancingScreen> {
  final FintechApiService _apiService = FintechApiService();
  FintechProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _apiService.getProfile();
      setState(() => _profile = profile);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showKycVerification() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => KycVerificationSheet(
        apiService: _apiService,
        onVerified: _loadProfile,
      ),
    );
  }

  void _showCreditSimulator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreditSimulatorSheet(
        apiService: _apiService,
      ),
    );
  }

  void _showEntityDetail(FinancialEntity entity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EntityDetailSheet(entity: entity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KazaTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: KazaTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Mi Kaza Financiera',
          style: TextStyle(color: KazaTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: KazaTheme.textPrimary),
            onPressed: _loadProfile,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: KazaTheme.azulKaza))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: KazaTheme.azulKaza,
              child: CustomScrollView(
                slivers: [
                  // 1. DASHBOARD FINTECH (Wallet & Score)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWalletCard(),
                          const SizedBox(height: 20),
                          _buildKycAndScoreCard(),
                          const SizedBox(height: 20),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),

                  // 2. DIRECTORIO DE ENTIDADES
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: const Text(
                        'DIRECTORIO DE ENTIDADES',
                        style: TextStyle(color: KazaTheme.azulKaza, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildEntityCard(mockEntities[index]);
                        },
                        childCount: mockEntities.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
    );
  }

  Widget _buildWalletCard() {
    final balance = _profile?.wallet.balance ?? 0.0;
    final formatter = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [KazaTheme.azulKaza, Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kaza Wallet P2P',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Banco Unión (Demo)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatter.format(balance),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Disponible para reservas inmobiliarias',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildKycAndScoreCard() {
    final isVerified = _profile?.kycStatus == KycStatus.verified;
    final score = _profile?.kazaScore;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KazaTheme.glassBorder),
      ),
      child: Row(
        children: [
          // Kaza Score
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kaza Score', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      score?.toString() ?? '---',
                      style: TextStyle(
                        color: score != null ? (score >= 600 ? KazaTheme.semanticSuccess : KazaTheme.semanticWarning) : KazaTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('/ 850', style: TextStyle(color: KazaTheme.textMuted, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _profile?.scoreLabel ?? 'Sin evaluar',
                  style: const TextStyle(color: KazaTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 60, color: KazaTheme.glassBorder),
          const SizedBox(width: 20),
          // KYC Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Identidad ASFI', style: TextStyle(color: KazaTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                isVerified
                    ? Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: KazaTheme.semanticSuccess, size: 20),
                          const SizedBox(width: 8),
                          const Text('Verificada', style: TextStyle(color: KazaTheme.semanticSuccess, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      )
                    : OutlinedButton(
                        onPressed: _showKycVerification,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          side: const BorderSide(color: KazaTheme.coralKaza),
                        ),
                        child: const Text('Verificar ahora', style: TextStyle(color: KazaTheme.coralKaza, fontSize: 12)),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showCreditSimulator,
            icon: const Icon(Icons.calculate_rounded, size: 18),
            label: const Text('Simular Crédito'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KazaTheme.coralKaza,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntityCard(FinancialEntity entity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KazaTheme.glassBorder),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showEntityDetail(entity),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: entity.brandColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(Icons.account_balance, color: entity.brandColor, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entity.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KazaTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Tasa: ${entity.referenceRate.toStringAsFixed(2)}% | Máx: ${entity.maxTermYears} años', style: const TextStyle(color: KazaTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: KazaTheme.azulKaza),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

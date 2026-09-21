import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fintech_models.dart';

/// Servicio que conecta la app Flutter con el backend NestJS FinTech
/// En demo: usa datos simulados localmente si el backend no está disponible
class FintechApiService {
  // URL base del backend NestJS (cambiar en producción)
  static const String _baseUrl = 'http://localhost:3000';
  static const String _demoUserId = 'usr-demo-fintech-001';

  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'x-user-id': _demoUserId,
  };

  // ─── PERFIL FINANCIERO COMPLETO ────────────────────────────────────────────

  Future<FintechProfile> getProfile() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/fintech/profile'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseProfile(data);
      }
    } catch (_) {
      // Fallback a datos de demo si el backend no está disponible
    }
    return _mockProfile();
  }

  // ─── VERIFICACIÓN KYC ─────────────────────────────────────────────────────

  Future<KycResult> verifyKyc({
    required String idNumber,
    required String fullName,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/fintech/kyc/verify'),
            headers: _headers,
            body: jsonEncode({'idNumber': idNumber, 'fullName': fullName}),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return KycResult.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback demo
    }
    // Demo: simula aprobación si CI termina en impar
    final lastDigit = int.tryParse(idNumber.isNotEmpty ? idNumber[idNumber.length - 1] : '1') ?? 1;
    final approved = lastDigit % 2 != 0;
    return KycResult(
      success: approved,
      status: approved ? KycStatus.verified : KycStatus.rejected,
      message: approved
          ? '✅ Identidad verificada. Cumples con las normativas ASFI.'
          : '❌ Verificación rechazada. Revisa los datos e inténtalo de nuevo.',
      kazaScore: approved ? 680 + (lastDigit * 10) : null,
      processedAt: DateTime.now().toIso8601String(),
    );
  }

  // ─── SCORING DE CRÉDITO ───────────────────────────────────────────────────

  Future<CreditResult> evaluateCredit({
    required double monthlyIncome,
    required double monthlyExpenses,
    required int applicantAge,
    required double requestedAmount,
    required int termYears,
    String? listingId,
  }) async {
    final body = {
      'monthlyIncome': monthlyIncome,
      'monthlyExpenses': monthlyExpenses,
      'applicantAge': applicantAge,
      'requestedAmount': requestedAmount,
      'termYears': termYears,
      if (listingId != null) 'listingId': listingId,
    };
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/fintech/credit/score'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return CreditResult.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback demo
    }
    return _mockCreditResult(monthlyIncome, monthlyExpenses, requestedAmount, termYears);
  }

  // ─── TRANSFERENCIA P2P ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> transferP2P({
    required String receiverUserId,
    required double amount,
    String? concept,
    String? referenceListingId,
  }) async {
    final body = {
      'receiverUserId': receiverUserId,
      'amount': amount,
      if (concept != null) 'concept': concept,
      if (referenceListingId != null) 'referenceListingId': referenceListingId,
    };
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/fintech/wallet/transfer'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Fallback demo
    }
    // Demo exitoso
    return {
      'success': true,
      'message': '✅ Reserva de ${amount.toStringAsFixed(0)} Bs procesada exitosamente.',
      'transaction': {
        'id': 'txn-demo-${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
        'currency': 'BOB',
        'status': 'COMPLETED',
        'concept': concept ?? 'Reserva de propiedad Kaza',
        'timestamp': DateTime.now().toIso8601String(),
      },
      'blockchainRef':
          '0x4b617a61${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
      'processedBy': 'Kaza Wallet · Banco Unión P2P (Simulado)',
    };
  }

  // ─── HELPERS PRIVADOS ─────────────────────────────────────────────────────

  FintechProfile _parseProfile(Map<String, dynamic> data) {
    final walletData = data['wallet'] as Map<String, dynamic>? ?? {};
    final identityData = data['identity'] as Map<String, dynamic>? ?? {};
    final kycStr = identityData['kycStatus'] as String? ?? 'NOT_STARTED';
    KycStatus kycStatus;
    switch (kycStr) {
      case 'VERIFIED':
        kycStatus = KycStatus.verified;
        break;
      case 'REJECTED':
        kycStatus = KycStatus.rejected;
        break;
      case 'IN_REVIEW':
        kycStatus = KycStatus.inReview;
        break;
      case 'PENDING':
        kycStatus = KycStatus.pending;
        break;
      default:
        kycStatus = KycStatus.notStarted;
    }
    return FintechProfile(
      wallet: MockWallet(
        id: 'wallet-demo',
        userId: _demoUserId,
        balance: (walletData['balance'] as num?)?.toDouble() ?? 5000,
        currency: walletData['currency'] as String? ?? 'BOB',
      ),
      kycStatus: kycStatus,
      kazaScore: identityData['kazaScore'] as int?,
      scoreLabel: identityData['scoreLabel'] as String? ?? 'Sin evaluar',
      recentTransactions: data['recentTransactions'] as List<dynamic>? ?? [],
      creditApplications: data['creditApplications'] as List<dynamic>? ?? [],
    );
  }

  FintechProfile _mockProfile() => const FintechProfile(
        wallet: MockWallet(
          id: 'wallet-demo-001',
          userId: _demoUserId,
          balance: 5000,
          currency: 'BOB',
        ),
        kycStatus: KycStatus.notStarted,
        kazaScore: null,
        scoreLabel: 'Sin evaluar',
      );

  CreditResult _mockCreditResult(
    double income,
    double expenses,
    double amount,
    int years,
  ) {
    final net = income - expenses;
    final monthlyRate = 0.055 / 12;
    final months = years * 12;
    final fee = (amount * monthlyRate * ((1 + monthlyRate) * months)) /
        (((1 + monthlyRate) * months) - 1);
    final maxFee = net * 0.30;
    final approved = fee <= maxFee && income >= 3000;
    if (approved) {
      return CreditResult(
        success: true,
        status: CreditStatus.preApproved,
        message: '🎉 ¡Felicitaciones! Estás pre-aprobado.',
        kazaScore: 720,
        bankProduct: 'Crédito Vivienda Social Banco Unión',
        approvedAmount: amount,
        annualRate: '5.50%',
        termYears: years,
        monthlyFee: fee.round(),
        totalToPayback: (fee * months).round(),
        processedAt: DateTime.now().toIso8601String(),
      );
    }
    return CreditResult(
      success: false,
      status: CreditStatus.rejected,
      message: '❌ Pre-calificación no aprobada.',
      kazaScore: 540,
      rejectionReason: 'La cuota mensual supera tu capacidad de pago actual.',
      recommendations: [
        'Considera ampliar el plazo del crédito.',
        'Reduce el monto solicitado o aumenta ingresos demostrables.',
        'Agrega un co-deudor para mejorar tu calificación.',
      ],
      processedAt: DateTime.now().toIso8601String(),
    );
  }
}

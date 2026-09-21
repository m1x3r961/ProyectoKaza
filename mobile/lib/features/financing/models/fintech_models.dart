/// Modelos del módulo FinTech Mock (Banco Unión Hackathon)
/// Kaza x Incuba Union Tecnológico 3.0

// ─── ENUMS ───────────────────────────────────────────────────────────────────

enum KycStatus { notStarted, pending, inReview, verified, rejected }

enum CreditStatus { pending, preApproved, approved, rejected }

// ─── MODELOS ─────────────────────────────────────────────────────────────────

class MockWallet {
  final String id;
  final String userId;
  final double balance;
  final String currency;
  final bool isActive;

  const MockWallet({
    required this.id,
    required this.userId,
    required this.balance,
    this.currency = 'BOB',
    this.isActive = true,
  });

  factory MockWallet.fromJson(Map<String, dynamic> json) => MockWallet(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        balance: (json['balance'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'BOB',
        isActive: json['is_active'] as bool? ?? true,
      );
}

class MockTransaction {
  final String id;
  final double amount;
  final String currency;
  final String status;
  final String? concept;
  final String timestamp;

  const MockTransaction({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    this.concept,
    required this.timestamp,
  });

  factory MockTransaction.fromJson(Map<String, dynamic> json) => MockTransaction(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'BOB',
        status: json['status'] as String,
        concept: json['concept'] as String?,
        timestamp: json['timestamp'] as String,
      );
}

class KycResult {
  final bool success;
  final KycStatus status;
  final String message;
  final int? kazaScore;
  final String? rejectionReason;
  final String? processedAt;

  const KycResult({
    required this.success,
    required this.status,
    required this.message,
    this.kazaScore,
    this.rejectionReason,
    this.processedAt,
  });

  factory KycResult.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'PENDING';
    KycStatus s;
    switch (statusStr) {
      case 'VERIFIED':
        s = KycStatus.verified;
        break;
      case 'REJECTED':
        s = KycStatus.rejected;
        break;
      case 'IN_REVIEW':
        s = KycStatus.inReview;
        break;
      default:
        s = KycStatus.pending;
    }
    return KycResult(
      success: json['success'] as bool? ?? false,
      status: s,
      message: json['message'] as String? ?? '',
      kazaScore: json['kazaScore'] as int?,
      rejectionReason: json['rejectionReason'] as String?,
      processedAt: json['processedAt'] as String?,
    );
  }
}

class CreditResult {
  final bool success;
  final CreditStatus status;
  final String message;
  final int? kazaScore;
  final String? bankProduct;
  final double? approvedAmount;
  final String? annualRate;
  final int? termYears;
  final int? monthlyFee;
  final int? totalToPayback;
  final String? rejectionReason;
  final List<String> recommendations;
  final String? processedAt;

  const CreditResult({
    required this.success,
    required this.status,
    required this.message,
    this.kazaScore,
    this.bankProduct,
    this.approvedAmount,
    this.annualRate,
    this.termYears,
    this.monthlyFee,
    this.totalToPayback,
    this.rejectionReason,
    this.recommendations = const [],
    this.processedAt,
  });

  factory CreditResult.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'PENDING';
    CreditStatus s;
    switch (statusStr) {
      case 'PRE_APPROVED':
        s = CreditStatus.preApproved;
        break;
      case 'APPROVED':
        s = CreditStatus.approved;
        break;
      case 'REJECTED':
        s = CreditStatus.rejected;
        break;
      default:
        s = CreditStatus.pending;
    }
    final recs = (json['recommendations'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return CreditResult(
      success: json['success'] as bool? ?? false,
      status: s,
      message: json['message'] as String? ?? '',
      kazaScore: json['kazaScore'] as int?,
      bankProduct: json['bankProduct'] as String?,
      approvedAmount: (json['approvedAmount'] as num?)?.toDouble(),
      annualRate: json['annualRate'] as String?,
      termYears: json['termYears'] as int?,
      monthlyFee: json['monthlyFee'] as int?,
      totalToPayback: json['totalToPayback'] as int?,
      rejectionReason: json['rejectionReason'] as String?,
      recommendations: recs,
      processedAt: json['processedAt'] as String?,
    );
  }
}

class FintechProfile {
  final MockWallet wallet;
  final KycStatus kycStatus;
  final int? kazaScore;
  final String scoreLabel;
  final List<dynamic> recentTransactions;
  final List<dynamic> creditApplications;

  const FintechProfile({
    required this.wallet,
    required this.kycStatus,
    this.kazaScore,
    required this.scoreLabel,
    this.recentTransactions = const [],
    this.creditApplications = const [],
  });
}

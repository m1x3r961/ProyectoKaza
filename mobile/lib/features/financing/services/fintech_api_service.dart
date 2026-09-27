import '../../../core/network/api_client.dart';
import '../../../core/network/supabase_config.dart';
import '../models/fintech_models.dart';

class FintechApiService {
  final _api = ApiClient();
  Future<FintechProfile> getProfile() async => _parseProfile(
      Map<String, dynamic>.from(await _api.request('/api/fintech/profile')));
  Future<KycResult> verifyKyc(
          {required String idNumber, required String fullName}) async =>
      KycResult.fromJson(Map<String, dynamic>.from(await _api.request(
          '/api/fintech/kyc/verify',
          method: 'POST',
          body: {'idNumber': idNumber, 'fullName': fullName})));
  Future<CreditResult> evaluateCredit(
          {required double monthlyIncome,
          required double monthlyExpenses,
          required int applicantAge,
          required double requestedAmount,
          required int termYears,
          String? listingId}) async =>
      CreditResult.fromJson(Map<String, dynamic>.from(await _api
          .request('/api/fintech/credit/score', method: 'POST', body: {
        'monthlyIncome': monthlyIncome,
        'monthlyExpenses': monthlyExpenses,
        'applicantAge': applicantAge,
        'requestedAmount': requestedAmount,
        'termYears': termYears,
        if (listingId != null) 'listingId': listingId
      })));
  Future<Map<String, dynamic>> transferP2P(
          {required String receiverUserId,
          required double amount,
          String? concept,
          String? referenceListingId,
          required String idempotencyKey}) async =>
      Map<String, dynamic>.from(await _api.request(
          '/api/fintech/wallet/transfer',
          method: 'POST',
          key: idempotencyKey,
          body: {
            'receiverUserId': receiverUserId,
            'amount': amount,
            if (concept != null) 'concept': concept,
            if (referenceListingId != null)
              'referenceListingId': referenceListingId
          }));
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
        id: walletData['id'] as String,
        userId: SupabaseConfig.client.auth.currentUser!.id,
        balance: (walletData['balance'] as num).toDouble(),
        currency: walletData['currency'] as String? ?? 'BOB',
      ),
      kycStatus: kycStatus,
      kazaScore: identityData['kazaScore'] as int?,
      scoreLabel: identityData['scoreLabel'] as String? ?? 'Sin evaluar',
      recentTransactions: data['recentTransactions'] as List<dynamic>? ?? [],
      creditApplications: data['creditApplications'] as List<dynamic>? ?? [],
    );
  }
}

import '../../../core/network/api_client.dart';

/// Word the user must type; the backend rejects any other confirmation.
const kDeleteAccountConfirmation = 'ELIMINAR';

class AccountApi {
  final ApiClient _api;
  AccountApi({ApiClient? api}) : _api = api ?? ApiClient();

  /// Permanently deletes the signed-in account: the backend hides the user's
  /// listings, anonymizes the profile and closes the login.
  Future<void> deleteAccount() async {
    await _api.request('/api/account/delete',
        method: 'POST', body: {'confirm': kDeleteAccountConfirmation});
  }
}

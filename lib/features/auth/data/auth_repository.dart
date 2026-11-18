import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../../../core/storage/token_store.dart';
import '../domain/auth_user.dart';

class AuthRepository {
  AuthRepository({required this.api, required this.tokens});

  final ApiClient api;
  final TokenStore tokens;

  /// `POST /auth/login` with `{ phone, pin }`. The server normalises the phone
  /// number, so it is sent as typed.
  Future<ApiResult<AuthUser>> login({required String phone, required String pin}) =>
      _signIn('/auth/login', {'phone': phone.trim(), 'pin': pin});

  /// `POST /auth/otp` — sends a one-time code by SMS.
  Future<ApiResult<OtpIssue>> requestOtp(String phone, OtpPurpose purpose) {
    return api.post<OtpIssue>(
      '/auth/otp',
      body: {'phone': phone.trim(), 'purpose': purpose.wire},
      authRetry: false,
      parse: (d) {
        final m = d as Map<String, dynamic>;
        return OtpIssue(
          resendAfter: Duration(milliseconds: (m['resendAfterMs'] as num?)?.toInt() ?? 30000),
          devCode: m['devCode'] as String?,
        );
      },
    );
  }

  /// `POST /auth/register` — creates the account after the code is verified.
  Future<ApiResult<AuthUser>> register({
    required String phone,
    required String code,
    required String name,
    required String pin,
    required String language,
  }) =>
      _signIn('/auth/register', {
        'phone': phone.trim(),
        'code': code,
        'name': name.trim(),
        'pin': pin,
        'language': language,
      });

  /// `POST /auth/pin` — resets a forgotten PIN with a `reset_pin` code, and signs in.
  Future<ApiResult<AuthUser>> resetPin({required String phone, required String code, required String pin}) =>
      _signIn('/auth/pin', {'phone': phone.trim(), 'code': code, 'pin': pin});

  /// `POST /auth/login` with a code instead of a PIN: the recovery route for a
  /// forgotten PIN or a temporarily locked account.
  Future<ApiResult<AuthUser>> loginWithCode({required String phone, required String code}) =>
      _signIn('/auth/login', {'phone': phone.trim(), 'code': code});

  /// Posts to an endpoint that answers with `{ user, accessToken, refreshToken }`
  /// and stores the tokens. A 401-style failure here means a wrong code, not an
  /// expired session, so there is no refresh-and-retry.
  Future<ApiResult<AuthUser>> _signIn(String path, Map<String, Object?> body) async {
    final result = await api.post<_LoginData>(
      path,
      body: body,
      authRetry: false,
      parse: (d) => _LoginData.fromJson(d as Map<String, dynamic>),
    );
    switch (result) {
      case Ok<_LoginData>(:final data, :final requestId):
        await tokens.save(accessToken: data.accessToken, refreshToken: data.refreshToken);
        return Ok(data.user, requestId: requestId);
      case Err<_LoginData>():
        return result.cast<AuthUser>();
    }
  }

  /// Restores a session at app start. Returns null when signed out.
  ///
  /// `GET /auth/session` answers 200 `{authenticated:false}` rather than 401 when
  /// the access token is missing, so the access token is minted first.
  Future<ApiResult<AuthUser?>> restore() async {
    if (await tokens.readRefreshToken() == null) return const Ok(null);
    if (tokens.accessToken == null && !await api.refreshSession()) {
      // Either the session is gone (tokens were cleared) or we are offline.
      return await tokens.readRefreshToken() == null
          ? const Ok(null)
          : const Err(ErrorCodes.network, 'Offline');
    }
    return api.get<AuthUser?>('/auth/session', parse: (d) {
      final data = d as Map<String, dynamic>;
      if (data['authenticated'] != true) return null;
      return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    });
  }

  /// Revokes the session server-side (best effort), then wipes local tokens.
  Future<void> logout() async {
    final refresh = await tokens.readRefreshToken();
    if (refresh != null) {
      await api.delete<void>('/auth/session', body: {'refreshToken': refresh}, parse: (_) {});
    }
    await tokens.clear();
  }
}

/// Why a code is being requested; the server's `purpose` values.
enum OtpPurpose {
  register('register'),
  login('login'),
  resetPin('reset_pin');

  const OtpPurpose(this.wire);
  final String wire;
}

class OtpIssue {
  const OtpIssue({required this.resendAfter, this.devCode});

  /// How long before another code may be requested.
  final Duration resendAfter;

  /// Present only when the server runs with `OTP_DEV_ECHO`, so a flow can be
  /// completed without an SMS gateway. Never shown in release builds.
  final String? devCode;
}

class _LoginData {
  const _LoginData({required this.user, required this.accessToken, required this.refreshToken});

  final AuthUser user;
  final String accessToken;
  final String refreshToken;

  factory _LoginData.fromJson(Map<String, dynamic> json) => _LoginData(
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
        // Present only because the request carries `X-Client: mobile`.
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
}

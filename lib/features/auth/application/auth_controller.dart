import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/language.dart';
import '../../../core/network/api_result.dart';
import '../../../core/providers.dart';
import '../../../core/storage/app_cache.dart';
import '../domain/auth_user.dart';

/// Session state: loading while restoring, `null` when signed out.
///
/// The signed-in user is remembered on the phone, so a launch opens straight
/// into the app from that copy (no splash, no waiting on the network) while the
/// session is confirmed with the server behind it. Only the first launch after
/// an update, before anything is remembered, waits for the server.
class AuthController extends AsyncNotifier<AuthUser?> {
  static const _userKey = 'session:user';

  /// Set once this phone has recorded its session state, so "nothing
  /// remembered" can be trusted to mean "signed out".
  static const _trackedPref = 'session_tracked';

  AppCache get _cache => ref.read(appCacheProvider);

  @override
  FutureOr<AuthUser?> build() {
    final remembered = _remembered();
    if (remembered != null || _cache.pref(_trackedPref) == '1') {
      _confirm(remembered);
      return remembered;
    }
    return _restore();
  }

  Future<AuthUser?> _restore() async {
    final result = await ref.read(authRepositoryProvider).restore();
    // Offline at launch with nothing remembered: there is no user object to
    // show, so treat it as signed out but keep the refresh token (it is only
    // cleared on an explicit server rejection).
    return result.when(
      ok: (user) {
        _remember(user);
        return user;
      },
      err: (_) => null,
    );
  }

  /// Checks the remembered session with the server and applies the verdict,
  /// unless something else (sign-in, sign-out) changed the session meanwhile.
  void _confirm(AuthUser? shown) {
    ref.read(authRepositoryProvider).restore().then((result) {
      if (!ref.mounted || state.isLoading || !identical(state.value, shown)) return;
      switch (result) {
        case Ok<AuthUser?>(data: final user?):
          _remember(user);
          if (shown == null || !_same(shown, user)) state = AsyncData(user);
        case Ok<AuthUser?>():
          // The session is gone on the server: back to sign-in.
          if (shown != null) {
            _forget();
            state = const AsyncData(null);
          } else {
            _remember(null);
          }
        case Err<AuthUser?>():
          // Offline or the server is down: stay signed in with the remembered
          // user. The refresh token is only dropped on an explicit rejection.
          break;
      }
    }, onError: (Object _) {});
  }

  AuthUser? _remembered() {
    final raw = _cache.entry(_userKey)?.raw;
    if (raw is! Map<String, dynamic>) return null;
    try {
      return AuthUser.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  void _remember(AuthUser? user) {
    user == null ? _cache.remove(_userKey) : _cache.put(_userKey, user.toJson());
    _cache.setPref(_trackedPref, '1');
  }

  /// Signed out: nothing of this person stays on the phone.
  void _forget() {
    _cache.clearUserData();
    _remember(null);
  }

  static bool _same(AuthUser a, AuthUser b) => jsonEncode(a.toJson()) == jsonEncode(b.toJson());

  /// Every sign-in path ends the same way: on success the user becomes the
  /// session, and the router moves off the sign-in screens by itself.
  Future<ApiResult<AuthUser>> _adopt(Future<ApiResult<AuthUser>> attempt) async {
    final result = await attempt;
    if (result is Ok<AuthUser>) {
      _forget(); // Start clean: no copy of anyone else's data.
      _remember(result.data);
      state = AsyncData(result.data);
    }
    return result;
  }

  Future<ApiResult<AuthUser>> login({required String phone, required String pin}) =>
      _adopt(ref.read(authRepositoryProvider).login(phone: phone, pin: pin));

  Future<ApiResult<AuthUser>> register({
    required String phone,
    required String code,
    required String name,
    required String pin,
    required String language,
  }) =>
      _adopt(ref
          .read(authRepositoryProvider)
          .register(phone: phone, code: code, name: name, pin: pin, language: language));

  Future<ApiResult<AuthUser>> resetPin({required String phone, required String code, required String pin}) =>
      _adopt(ref.read(authRepositoryProvider).resetPin(phone: phone, code: code, pin: pin));

  Future<ApiResult<AuthUser>> loginWithCode({required String phone, required String code}) =>
      _adopt(ref.read(authRepositoryProvider).loginWithCode(phone: phone, code: code));

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    _forget();
    state = const AsyncData(null);
  }

  /// Called by the API client when the refresh token is rejected.
  void sessionExpired() {
    _forget();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);

/// UI language: the choice made on this phone, else the signed-in user's
/// preference, else Bangla.
final localeProvider = Provider<Locale>((ref) {
  final picked = ref.watch(languageProvider);
  final user = ref.watch(authControllerProvider).value;
  return Locale(picked ?? user?.language ?? 'bn');
});

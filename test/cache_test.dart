import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shebar_janala_app/core/network/api_client.dart';
import 'package:shebar_janala_app/core/network/api_result.dart';
import 'package:shebar_janala_app/core/network/cached.dart';
import 'package:shebar_janala_app/core/providers.dart';
import 'package:shebar_janala_app/core/storage/app_cache.dart';
import 'package:shebar_janala_app/core/storage/token_store.dart';
import 'package:shebar_janala_app/features/auth/application/auth_controller.dart';
import 'package:shebar_janala_app/features/auth/data/auth_repository.dart';
import 'package:shebar_janala_app/features/auth/domain/auth_user.dart';

import 'api_client_test.dart' as http show FakeAdapter, dioWith, fail, json, ok;

class MockAuthRepo extends Mock implements AuthRepository {}

const rahima = AuthUser(id: 'u1', name: 'Rahima', phone: '017', role: 'citizen', language: 'en');

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('sj_cache_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('AppCache', () {
    test('keeps entries across launches and reports changes', () async {
      final first = AppCache.at(dir);
      expect(first.put('api:/x?', {'n': 1}), isTrue);
      expect(first.put('api:/x?', {'n': 1}), isFalse, reason: 'same content is not a change');
      first.setPref('language', 'en');
      await first.flush();

      final second = AppCache.at(dir);
      expect(second.entry('api:/x?')!.raw, {'n': 1});
      expect(second.entry('api:/x?')!.fresh, isFalse, reason: 'not yet confirmed by the server this run');
      expect(second.pref('language'), 'en');
    });

    test('sign-out wipes the person\'s data but keeps preferences', () async {
      final cache = AppCache.at(dir);
      cache.put('session:user', {'id': 'u1'});
      cache.put('api:/saved?', {'items': []});
      cache.setPref('text_size', 'large');
      await cache.flush();

      cache.clearUserData();
      expect(cache.entry('session:user'), isNull);
      expect(cache.entry('api:/saved?'), isNull);

      final next = AppCache.at(dir);
      expect(next.entry('api:/saved?'), isNull);
      expect(next.pref('text_size'), 'large');
    });

    test('patch rewrites a stored answer in place', () async {
      final cache = AppCache.at(dir)..put('k', {'items': [1, 2, 3]});
      cache.patch('k', (raw) => {'items': ((raw as Map)['items'] as List).where((i) => i != 2).toList()});
      expect(cache.entry('k')!.raw, {'items': [1, 3]});
      await cache.flush();
      expect(AppCache.at(dir).entry('k')!.raw, {'items': [1, 3]});
    });
  });

  group('ApiClient cache', () {
    test('a cached GET is kept, peeked, and identical requests share one call', () async {
      final store = MemoryTokenStore();
      await store.save(accessToken: 'AT', refreshToken: 'RT');
      final gate = Completer<void>();
      final adapter = http.FakeAdapter((_) async {
        await gate.future;
        return http.json(http.ok({'n': 7}));
      });
      final api = ApiClient(tokens: store, dio: http.dioWith(adapter), refreshDio: http.dioWith(adapter), cache: AppCache.memory());
      int parse(dynamic d) => (d as Map)['n'] as int;

      expect(api.peek('/x', query: {'a': 1}, parse: parse), isNull);
      final a = api.get('/x', query: {'a': 1}, parse: parse, cached: true);
      final b = api.get('/x', query: {'a': 1}, parse: parse, cached: true);
      gate.complete();
      await Future.wait([a, b]);

      expect(adapter.calls, hasLength(1));
      expect(api.peek('/x', query: {'a': 1}, parse: parse)!.value, 7);
    });

    test('with no access token yet, the token is minted first instead of after a 401', () async {
      // A fresh launch: refresh token stored, no access token in memory.
      final launch = _LaunchTokens('RT1');
      final main = http.FakeAdapter((o) async =>
          o.headers['Authorization'] == 'Bearer NEW' ? http.json(http.ok(1)) : http.json(http.fail('UNAUTHENTICATED'), status: 401));
      final refresh = http.FakeAdapter((_) async => http.json(http.ok({'accessToken': 'NEW', 'refreshToken': 'RT2'})));
      final api = ApiClient(tokens: launch, dio: http.dioWith(main), refreshDio: http.dioWith(refresh));

      final results = await Future.wait([
        for (var i = 0; i < 3; i++) api.get<int>('/x$i', parse: (d) => d as int),
      ]);

      expect(results.every((r) => r is Ok<int>), isTrue);
      expect(refresh.calls, hasLength(1), reason: 'one shared refresh');
      expect(main.calls, hasLength(3), reason: 'no request was sent without a token');
    });
  });

  group('cachedFirst', () {
    test('serves the copy at once, then applies a changed answer', () async {
      // A copy from an earlier launch: not yet confirmed by the server.
      final earlier = AppCache.at(dir)..put('k', 1);
      await earlier.flush();
      final cache = AppCache.at(dir);
      var server = 2;
      final provider = FutureProvider<int>((ref) => cachedFirst(
            ref,
            id: 'test-k',
            peek: () {
              final e = cache.entry('k')!;
              return Cached(e.raw as int, version: e.changedAt, fresh: e.fresh);
            },
            fetch: () async {
              await Future<void>.delayed(const Duration(milliseconds: 5));
              cache.put('k', server);
              return server;
            },
          ));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final seen = <AsyncValue<int>>[];
      container.listen(provider, (_, next) => seen.add(next), fireImmediately: true);

      expect(seen.first, const AsyncData(1), reason: 'no loading state on the first frame');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(container.read(provider).value, 2);

      // Pull to refresh waits for the server.
      server = 3;
      expect(await container.refresh(provider.future), 3);
      await cache.flush();
    });
  });

  group('AuthController', () {
    test('opens with the remembered user and confirms it behind the scenes', () async {
      final cache = AppCache.memory()
        ..put('session:user', rahima.toJson())
        ..setPref('session_tracked', '1');
      final repo = MockAuthRepo();
      final gate = Completer<ApiResult<AuthUser?>>();
      when(repo.restore).thenAnswer((_) => gate.future);
      final container = ProviderContainer(overrides: [
        appCacheProvider.overrideWithValue(cache),
        authRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      container.listen(authControllerProvider, (_, _) {});

      expect(container.read(authControllerProvider).value?.name, 'Rahima');

      gate.complete(const Ok(null)); // The server says the session is gone.
      await Future<void>.delayed(Duration.zero);
      expect(container.read(authControllerProvider).value, isNull);
      expect(cache.entry('session:user'), isNull);
    });

    test('offline at launch keeps the remembered user signed in', () async {
      final cache = AppCache.memory()
        ..put('session:user', rahima.toJson())
        ..setPref('session_tracked', '1');
      final repo = MockAuthRepo();
      when(repo.restore).thenAnswer((_) async => const Err(ErrorCodes.network, 'Offline'));
      final container = ProviderContainer(overrides: [
        appCacheProvider.overrideWithValue(cache),
        authRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      container.listen(authControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authControllerProvider).value?.id, 'u1');
    });

    test('a known signed-out phone opens the sign-in screen without waiting', () {
      final cache = AppCache.memory()..setPref('session_tracked', '1');
      final repo = MockAuthRepo();
      when(repo.restore).thenAnswer((_) => Completer<ApiResult<AuthUser?>>().future);
      final container = ProviderContainer(overrides: [
        appCacheProvider.overrideWithValue(cache),
        authRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.value, isNull);
    });
  });
}

/// A launch: the refresh token is stored, the access token is not yet known.
class _LaunchTokens implements TokenStore {
  _LaunchTokens(this._refresh);
  String? _refresh;
  String? _access;

  @override
  String? get accessToken => _access;
  @override
  Future<String?> readRefreshToken() async => _refresh;
  @override
  Future<void> save({required String accessToken, required String refreshToken}) async {
    _access = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<void> clear() async => _access = _refresh = null;
}

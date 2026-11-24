import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// The phone's copy of what the app last showed: server answers, the signed-in
/// user and the display preferences.
///
/// Screens open from this copy at once (no skeleton, no splash) and are then
/// refreshed from the server. Nothing secret is kept here: tokens stay in the
/// platform keystore ([SecureTokenStore]).
///
/// Each entry is one small JSON file, read the first time it is asked for and
/// then kept in memory, so start-up reads only what the first screen needs.
/// Keys starting with `pref:` are preferences of the phone and survive sign-out;
/// every other key belongs to the signed-in person and is wiped with
/// [clearUserData].
class AppCache {
  AppCache._(this._root);

  /// A cache that lives in memory only (tests, or when storage is unavailable).
  AppCache.memory() : _root = null;

  /// A cache kept in [root], for tests.
  @visibleForTesting
  AppCache.at(Directory root) : _root = root {
    _dataDir.createSync(recursive: true);
    _prefDir.createSync(recursive: true);
  }

  /// Waits for pending writes, for tests.
  @visibleForTesting
  Future<void> flush() => Future.wait(_writes.values.toList());

  /// Opens the cache in the app's private storage. Never throws: if storage is
  /// unavailable the app runs on a memory-only cache.
  static Future<AppCache> open() async {
    try {
      final base = await getApplicationSupportDirectory();
      final root = Directory('${base.path}${Platform.pathSeparator}sj_cache');
      final cache = AppCache._(root);
      cache._dataDir.createSync(recursive: true);
      cache._prefDir.createSync(recursive: true);
      // Housekeeping off the start-up path.
      Timer(const Duration(seconds: 8), cache._prune);
      return cache;
    } catch (_) {
      return AppCache.memory();
    }
  }

  final Directory? _root;
  final _entries = <String, CacheEntry?>{};
  final _writes = <String, Future<void>>{};

  /// Bumped by [clearUserData]; a response that started before a sign-out
  /// must not write the previous person's data back.
  int get generation => _generation;
  var _generation = 0;

  static const _prefPrefix = 'pref:';
  static const _maxDataFiles = 400;

  Directory get _dataDir => Directory('${_root!.path}${Platform.pathSeparator}data');
  Directory get _prefDir => Directory('${_root!.path}${Platform.pathSeparator}prefs');

  /* -------------------------------------------------------------- entries */

  /// The stored entry for [key], or null.
  CacheEntry? entry(String key) {
    if (_entries.containsKey(key)) return _entries[key];
    final loaded = _readFile(key);
    _entries[key] = loaded;
    return loaded;
  }

  /// Stores [raw] (JSON-encodable) under [key]. Returns true if it differs
  /// from what was stored.
  bool put(String key, Object? raw) {
    final encoded = jsonEncode(raw);
    final now = DateTime.now().millisecondsSinceEpoch;
    final old = entry(key);
    if (old != null && old.encoded == encoded) {
      old.checkedAt = now;
      return false;
    }
    _entries[key] = CacheEntry._(raw, encoded, changedAt: now, checkedAt: now);
    _persist(key, encoded, now);
    return true;
  }

  /// Rewrites a stored entry in place, e.g. after a change the server accepted,
  /// so the next launch opens with it. Does nothing if [key] is not stored.
  void patch(String key, Object? Function(Object? raw) change) {
    final old = entry(key);
    if (old == null) return;
    try {
      final next = change(jsonDecode(old.encoded));
      final encoded = jsonEncode(next);
      if (encoded == old.encoded) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      _entries[key] = CacheEntry._(next, encoded, changedAt: now, checkedAt: old.checkedAt);
      _persist(key, encoded, now);
    } catch (_) {
      // The stored shape is not what the patch expects: drop it rather than lie.
      remove(key);
    }
  }

  void remove(String key) {
    _entries[key] = null;
    final file = _fileFor(key);
    if (file == null) return;
    _queue(key, () async {
      try {
        if (file.existsSync()) await file.delete();
      } catch (_) {}
    });
  }

  /// Forgets everything that belongs to the signed-in person; preferences stay.
  void clearUserData() {
    _generation++;
    _entries.removeWhere((key, _) => !key.startsWith(_prefPrefix));
    final root = _root;
    if (root == null) return;
    // Move the folder aside in one step so nothing stale can be read from it,
    // then delete it in the background.
    try {
      final data = _dataDir;
      if (data.existsSync()) {
        final trash = data.renameSync('${root.path}${Platform.pathSeparator}trash-${DateTime.now().microsecondsSinceEpoch}');
        unawaited(trash.delete(recursive: true).catchError((_) => trash));
      }
      data.createSync(recursive: true);
    } catch (_) {
      // Fall back to deleting file by file.
      try {
        for (final f in _dataDir.listSync()) {
          f.deleteSync(recursive: true);
        }
      } catch (_) {}
    }
  }

  /* ---------------------------------------------------------- preferences */

  String? pref(String name) {
    final raw = entry('$_prefPrefix$name')?.raw;
    return raw is String ? raw : null;
  }

  void setPref(String name, String? value) {
    final key = '$_prefPrefix$name';
    value == null ? remove(key) : put(key, value);
  }

  /* --------------------------------------------------------------- files */

  File? _fileFor(String key) {
    if (_root == null) return null;
    final dir = key.startsWith(_prefPrefix) ? _prefDir : _dataDir;
    return File('${dir.path}${Platform.pathSeparator}${_hash(key)}.json');
  }

  CacheEntry? _readFile(String key) {
    final file = _fileFor(key);
    if (file == null) return null;
    try {
      if (!file.existsSync()) return null;
      final stored = jsonDecode(file.readAsStringSync());
      if (stored is! Map || stored['k'] != key) return null;
      final raw = stored['v'];
      // checkedAt 0: read from the phone, not yet confirmed by the server.
      return CacheEntry._(raw, jsonEncode(raw), changedAt: (stored['c'] as num?)?.toInt() ?? 0, checkedAt: 0);
    } catch (_) {
      return null; // Torn or corrupt file: treat as missing.
    }
  }

  void _persist(String key, String encoded, int changedAt) {
    final file = _fileFor(key);
    if (file == null) return;
    final generation = _generation;
    _queue(key, () async {
      if (generation != _generation && !key.startsWith(_prefPrefix)) return;
      try {
        // Write then rename, so a process killed mid-write never leaves half a file.
        final tmp = File('${file.path}.tmp');
        await tmp.writeAsString('{"k":${jsonEncode(key)},"c":$changedAt,"v":$encoded}', flush: true);
        await tmp.rename(file.path);
      } catch (_) {
        // The copy is a convenience; the server stays the source of truth.
      }
    });
  }

  /// Writes to one file happen one after another, newest last.
  void _queue(String key, Future<void> Function() task) {
    final next = (_writes[key] ?? Future<void>.value()).then((_) => task());
    _writes[key] = next;
    unawaited(next.whenComplete(() {
      if (identical(_writes[key], next)) _writes.remove(key);
    }));
  }

  /// Keeps the folder bounded: the oldest programme pages go first.
  Future<void> _prune() async {
    try {
      final root = _root!;
      for (final e in root.listSync()) {
        if (e is Directory && e.path.contains('trash-')) unawaited(e.delete(recursive: true).catchError((_) => e));
      }
      final files = _dataDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();
      if (files.length <= _maxDataFiles) return;
      final dated = [for (final f in files) (f, f.statSync().modified)]..sort((a, b) => a.$2.compareTo(b.$2));
      for (final (f, _) in dated.take(files.length - _maxDataFiles)) {
        await f.delete();
      }
      // In-memory entries for deleted files simply stay until the next launch.
    } catch (_) {}
  }

  /// Two 32-bit FNV-1a hashes with different seeds: a stable, file-name-safe
  /// name for any key (String.hashCode is not stable between runs).
  static String _hash(String key) {
    final bytes = utf8.encode(key);
    String fnv(int seed) {
      var h = seed;
      for (final b in bytes) {
        h = ((h ^ b) * 0x01000193) & 0xFFFFFFFF;
      }
      return h.toRadixString(16).padLeft(8, '0');
    }

    return '${fnv(0x811c9dc5)}${fnv(0x050c5d1f)}';
  }

  @visibleForTesting
  static String hashForTest(String key) => _hash(key);
}

class CacheEntry {
  CacheEntry._(this.raw, this.encoded, {required this.changedAt, required this.checkedAt});

  /// The stored JSON value.
  final Object? raw;
  final String encoded;

  /// When the content last changed (milliseconds since epoch).
  final int changedAt;

  /// When the server last confirmed it in this run of the app; 0 if never.
  int checkedAt;

  /// Confirmed by the server a moment ago: no need to ask again yet.
  bool get fresh => checkedAt != 0 && DateTime.now().millisecondsSinceEpoch - checkedAt < 30000;
}

/// Replaced in `main` with the cache opened from storage.
final appCacheProvider = Provider<AppCache>((ref) => AppCache.memory());

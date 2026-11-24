import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A value read from the phone's copy of a server answer.
class Cached<T> {
  const Cached(this.value, {required this.version, required this.fresh});
  final T value;

  /// Changes whenever the stored content changes.
  final int version;

  /// The server confirmed it a moment ago, so there is no need to ask again.
  final bool fresh;

  Cached<R> map<R>(R Function(T value) convert) => Cached(convert(value), version: version, fresh: fresh);
}

final _selfRefresh = <Object>{};

/// Builds a provider from the phone's copy of its data when there is one: the
/// screen opens with content on its first frame instead of a skeleton, and the
/// copy is then checked with the server in the background.
///
/// * Nothing stored, or the person pulled to refresh / tapped Retry
///   (`ref.refresh`, `ref.invalidate`): waits for the server, as before.
/// * Stored: returns it at once, and if the server's answer differs calls
///   [onUpdate] with it and the value that was shown (or, when null, rebuilds
///   the provider from the updated copy).
///
/// [id] names the provider (and its argument) for that self-rebuild.
FutureOr<T> cachedFirst<T>(
  Ref ref, {
  required Object id,
  required Cached<T>? Function() peek,
  required Future<T> Function() fetch,
  void Function(T fresh, T shown)? onUpdate,
}) {
  final selfRefresh = _selfRefresh.remove(id);
  final cached = peek();
  if (cached == null || (ref.isRefresh && !selfRefresh)) return fetch();
  if (!cached.fresh) {
    fetch().then((value) {
      if (!ref.mounted) return;
      final now = peek();
      if (now == null || now.version == cached.version) return; // Unchanged: no rebuild.
      if (onUpdate != null) {
        onUpdate(value, cached.value);
      } else {
        _selfRefresh.add(id);
        ref.invalidateSelf();
      }
    }, onError: (Object _) {
      // Offline or the server is down: keep showing the copy.
    });
  }
  return cached.value;
}

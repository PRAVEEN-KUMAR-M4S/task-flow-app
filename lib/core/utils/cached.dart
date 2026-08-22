/// A value plus where it came from.
///
/// Reads that can be served from the Hive cache while offline return this so
/// the presentation layer can show a "showing saved data" banner instead of
/// silently presenting stale rows as live ones.
class Cached<T> {
  final T data;

  /// `true` when [data] came from the local cache rather than a fresh read.
  final bool isStale;

  const Cached.fresh(this.data) : isStale = false;
  const Cached.stale(this.data) : isStale = true;

  Cached<R> map<R>(R Function(T data) transform) =>
      isStale ? Cached.stale(transform(data)) : Cached.fresh(transform(data));
}

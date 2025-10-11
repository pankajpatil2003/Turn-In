// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 2. Feed State Notifier (Riverpod)

@ProviderFor(FeedNotifier)
const feedProvider = FeedNotifierProvider._();

/// 2. Feed State Notifier (Riverpod)
final class FeedNotifierProvider
    extends $NotifierProvider<FeedNotifier, FeedState> {
  /// 2. Feed State Notifier (Riverpod)
  const FeedNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedNotifierHash();

  @$internal
  @override
  FeedNotifier create() => FeedNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedState>(value),
    );
  }
}

String _$feedNotifierHash() => r'664493574274603cab60ce1410faad2f57a1552d';

/// 2. Feed State Notifier (Riverpod)

abstract class _$FeedNotifier extends $Notifier<FeedState> {
  FeedState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<FeedState, FeedState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FeedState, FeedState>,
              FeedState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for the PostService class.

@ProviderFor(postService)
const postServiceProvider = PostServiceProvider._();

/// Riverpod provider for the PostService class.

final class PostServiceProvider
    extends $FunctionalProvider<PostService, PostService, PostService>
    with $Provider<PostService> {
  /// Riverpod provider for the PostService class.
  const PostServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postServiceHash();

  @$internal
  @override
  $ProviderElement<PostService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PostService create(Ref ref) {
    return postService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostService>(value),
    );
  }
}

String _$postServiceHash() => r'f6b6ccedd6e8d05bce575081539855556e78c818';

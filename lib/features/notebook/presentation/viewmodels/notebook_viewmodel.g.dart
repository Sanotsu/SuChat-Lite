// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notebook_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notebookViewModelHash() => r'b469d53d6fe27d967489bd920d90604869b3f08c';

/// See also [NotebookViewModel].
@ProviderFor(NotebookViewModel)
final notebookViewModelProvider =
    AutoDisposeAsyncNotifierProvider<NotebookViewModel, List<Note>>.internal(
      NotebookViewModel.new,
      name: r'notebookViewModelProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$notebookViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NotebookViewModel = AutoDisposeAsyncNotifier<List<Note>>;
String _$noteCategoryViewModelHash() =>
    r'e2c3aa94d8033aadec0c779150063f8de8c274d5';

/// See also [NoteCategoryViewModel].
@ProviderFor(NoteCategoryViewModel)
final noteCategoryViewModelProvider = AutoDisposeAsyncNotifierProvider<
  NoteCategoryViewModel,
  List<NoteCategory>
>.internal(
  NoteCategoryViewModel.new,
  name: r'noteCategoryViewModelProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$noteCategoryViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NoteCategoryViewModel = AutoDisposeAsyncNotifier<List<NoteCategory>>;
String _$noteTagViewModelHash() => r'3ac89d287f7fd270aba054e1e9eecbb6a233dd6d';

/// See also [NoteTagViewModel].
@ProviderFor(NoteTagViewModel)
final noteTagViewModelProvider =
    AutoDisposeAsyncNotifierProvider<NoteTagViewModel, List<NoteTag>>.internal(
      NoteTagViewModel.new,
      name: r'noteTagViewModelProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$noteTagViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NoteTagViewModel = AutoDisposeAsyncNotifier<List<NoteTag>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

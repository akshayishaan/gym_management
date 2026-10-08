import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/member_repository.dart';
import '../domain/member.dart';

/// Controller state shared by the create / update / delete notifiers.
class MemberMutationState {
  const MemberMutationState({this.loading = false, this.lastError});
  final bool loading;
  final Object? lastError;

  MemberMutationState copyWith({bool? loading, Object? lastError}) {
    return MemberMutationState(
      loading: loading ?? this.loading,
      lastError: lastError,
    );
  }
}

/// `POST /members`. On success, invalidates the paginated list so the
/// new row appears immediately.
class MemberCreateController
    extends AutoDisposeNotifier<MemberMutationState> {
  @override
  MemberMutationState build() => const MemberMutationState();

  Future<Member> create(MemberCreateInput input) async {
    state = const MemberMutationState(loading: true);
    try {
      final result =
          await ref.read(memberRepositoryProvider).createMember(input);
      // Refresh the list so the new member appears at the top
      // (sorted by createdAt desc).
      ref.invalidate(memberListProvider);
      state = const MemberMutationState();
      return result.member;
    } catch (e) {
      state = MemberMutationState(lastError: e);
      rethrow;
    }
  }
}

final memberCreateControllerProvider =
    AutoDisposeNotifierProvider<MemberCreateController, MemberMutationState>(
  MemberCreateController.new,
);

/// `PUT /members/:id`. On success, invalidates the list AND the detail
/// provider for that id so the detail screen reflects the edit.
class MemberUpdateController
    extends AutoDisposeNotifier<MemberMutationState> {
  @override
  MemberMutationState build() => const MemberMutationState();

  Future<Member> update(String id, MemberUpdateInput input) async {
    state = const MemberMutationState(loading: true);
    try {
      final updated =
          await ref.read(memberRepositoryProvider).updateMember(id, input);
      ref.invalidate(memberListProvider);
      ref.invalidate(memberDetailProvider(id));
      state = const MemberMutationState();
      return updated;
    } catch (e) {
      state = MemberMutationState(lastError: e);
      rethrow;
    }
  }
}

final memberUpdateControllerProvider =
    AutoDisposeNotifierProvider<MemberUpdateController, MemberMutationState>(
  MemberUpdateController.new,
);

/// `DELETE /members/:id` (soft delete). On success, invalidates the
/// list and the detail provider so the row disappears immediately.
class MemberDeleteController
    extends AutoDisposeNotifier<MemberMutationState> {
  @override
  MemberMutationState build() => const MemberMutationState();

  Future<void> softDelete(String id) async {
    state = const MemberMutationState(loading: true);
    try {
      await ref.read(memberRepositoryProvider).softDeleteMember(id);
      ref.invalidate(memberListProvider);
      ref.invalidate(memberDetailProvider(id));
      state = const MemberMutationState();
    } catch (e) {
      state = MemberMutationState(lastError: e);
      rethrow;
    }
  }
}

final memberDeleteControllerProvider =
    AutoDisposeNotifierProvider<MemberDeleteController, MemberMutationState>(
  MemberDeleteController.new,
);
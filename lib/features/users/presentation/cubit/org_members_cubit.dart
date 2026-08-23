import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/users/domain/entities/org_member.dart';
import 'package:task_flow/features/users/domain/usecases/get_org_members_usecase.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class OrgMembersState extends Equatable {
  const OrgMembersState();
  @override
  List<Object?> get props => [];
}

class OrgMembersInitial extends OrgMembersState {
  const OrgMembersInitial();
}

class OrgMembersLoading extends OrgMembersState {
  const OrgMembersLoading();
}

class OrgMembersLoaded extends OrgMembersState {
  final List<OrgMember> members;
  const OrgMembersLoaded(this.members);
  @override
  List<Object?> get props => [members];
}

class OrgMembersError extends OrgMembersState {
  final Failure failure;
  const OrgMembersError(this.failure);
  @override
  List<Object?> get props => [failure];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

/// Loads org members for the current user's organization.
/// Shared by task form, assignee picker, and filter bar.
class OrgMembersCubit extends Cubit<OrgMembersState> {
  final GetOrgMembersUseCase _getOrgMembersUseCase;

  OrgMembersCubit({required GetOrgMembersUseCase getOrgMembersUseCase})
      : _getOrgMembersUseCase = getOrgMembersUseCase,
        super(const OrgMembersInitial());

  /// Reset state before loading new org members — singleton reuse.
  void reset() => emit(const OrgMembersInitial());

  Future<void> loadMembers(String orgId) async {
    emit(const OrgMembersLoading());
    final result = await _getOrgMembersUseCase(orgId);
    result.fold(
      (failure) => emit(OrgMembersError(failure)),
      (members) => emit(OrgMembersLoaded(members)),
    );
  }
}

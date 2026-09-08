import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/collaboration_models.dart';

class CollaborationState {
  final Collaboration? currentDraft;
  final bool isLoading;

  CollaborationState({this.currentDraft, this.isLoading = false});

  CollaborationState copyWith({Collaboration? currentDraft, bool? isLoading}) {
    return CollaborationState(
      currentDraft: currentDraft ?? this.currentDraft,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CollaborationNotifier extends StateNotifier<CollaborationState> {
  CollaborationNotifier() : super(CollaborationState());

  void startNewCollaboration(String propertyId, String title, double price) {
    state = state.copyWith(
      currentDraft: Collaboration(
        id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
        propertyId: propertyId,
        propertyTitle: title,
        propertyPrice: price,
        mode: CollaborationMode.coBrokerage,
        status: CollaborationStatus.draft,
        requiresAgreement: true,
        totalCommissionValue: price * 0.05, // Mock 5%
        members: [
          CollaborationMember(
            id: 'm1',
            userId: 'my_user_id',
            userName: 'Mi Usuario',
            userRoleTitle: 'Propietario',
            role: MemberRole.owner,
            status: MemberStatus.accepted,
            commissionPercentage: 100.0,
          )
        ],
      )
    );
  }

  void addInvitee(String userId, String name, String roleTitle) {
    if (state.currentDraft == null) return;
    final draft = state.currentDraft!;
    
    final newMember = CollaborationMember(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: name,
      userRoleTitle: roleTitle,
      role: MemberRole.collaborator,
      status: MemberStatus.pending,
      commissionPercentage: 0.0,
    );

    state = state.copyWith(
      currentDraft: Collaboration(
        id: draft.id,
        propertyId: draft.propertyId,
        propertyTitle: draft.propertyTitle,
        propertyPrice: draft.propertyPrice,
        mode: draft.mode,
        status: draft.status,
        scope: draft.scope,
        requiresAgreement: draft.requiresAgreement,
        totalCommissionValue: draft.totalCommissionValue,
        members: [...draft.members, newMember],
      )
    );
  }

  void setSplit(double mySplit, double theirSplit) {
    if (state.currentDraft == null || state.currentDraft!.members.length < 2) return;
    final draft = state.currentDraft!;

    final updatedMembers = List<CollaborationMember>.from(draft.members);
    // Asumimos index 0 es Owner, index 1 es Colaborador
    updatedMembers[0] = CollaborationMember(
      id: updatedMembers[0].id,
      userId: updatedMembers[0].userId,
      userName: updatedMembers[0].userName,
      userRoleTitle: updatedMembers[0].userRoleTitle,
      role: updatedMembers[0].role,
      status: updatedMembers[0].status,
      commissionPercentage: mySplit,
    );
    updatedMembers[1] = CollaborationMember(
      id: updatedMembers[1].id,
      userId: updatedMembers[1].userId,
      userName: updatedMembers[1].userName,
      userRoleTitle: updatedMembers[1].userRoleTitle,
      role: updatedMembers[1].role,
      status: updatedMembers[1].status,
      commissionPercentage: theirSplit,
    );

    state = state.copyWith(
      currentDraft: Collaboration(
        id: draft.id,
        propertyId: draft.propertyId,
        propertyTitle: draft.propertyTitle,
        propertyPrice: draft.propertyPrice,
        mode: draft.mode,
        status: draft.status,
        scope: draft.scope,
        requiresAgreement: draft.requiresAgreement,
        totalCommissionValue: draft.totalCommissionValue,
        members: updatedMembers,
      )
    );
  }

  void sendInvitation() {
    if (state.currentDraft == null) return;
    state = state.copyWith(
      currentDraft: Collaboration(
        id: state.currentDraft!.id,
        propertyId: state.currentDraft!.propertyId,
        propertyTitle: state.currentDraft!.propertyTitle,
        propertyPrice: state.currentDraft!.propertyPrice,
        mode: state.currentDraft!.mode,
        status: CollaborationStatus.invitationSent,
        scope: state.currentDraft!.scope,
        requiresAgreement: state.currentDraft!.requiresAgreement,
        totalCommissionValue: state.currentDraft!.totalCommissionValue,
        members: state.currentDraft!.members,
      )
    );
  }

  void acceptInvitationMock() {
    if (state.currentDraft == null) return;
    final draft = state.currentDraft!;
    
    final updatedMembers = List<CollaborationMember>.from(draft.members);
    if (updatedMembers.length > 1) {
      updatedMembers[1] = CollaborationMember(
        id: updatedMembers[1].id,
        userId: updatedMembers[1].userId,
        userName: updatedMembers[1].userName,
        userRoleTitle: updatedMembers[1].userRoleTitle,
        role: updatedMembers[1].role,
        status: MemberStatus.accepted,
        commissionPercentage: updatedMembers[1].commissionPercentage,
      );
    }

    state = state.copyWith(
      currentDraft: Collaboration(
        id: draft.id,
        propertyId: draft.propertyId,
        propertyTitle: draft.propertyTitle,
        propertyPrice: draft.propertyPrice,
        mode: draft.mode,
        status: CollaborationStatus.active,
        scope: draft.scope,
        requiresAgreement: draft.requiresAgreement,
        totalCommissionValue: draft.totalCommissionValue,
        members: updatedMembers,
      )
    );
  }

  void closeOperationMock() {
    if (state.currentDraft == null) return;
    state = state.copyWith(
      currentDraft: Collaboration(
        id: state.currentDraft!.id,
        propertyId: state.currentDraft!.propertyId,
        propertyTitle: state.currentDraft!.propertyTitle,
        propertyPrice: state.currentDraft!.propertyPrice,
        mode: state.currentDraft!.mode,
        status: CollaborationStatus.completed,
        scope: state.currentDraft!.scope,
        requiresAgreement: state.currentDraft!.requiresAgreement,
        totalCommissionValue: state.currentDraft!.totalCommissionValue,
        members: state.currentDraft!.members,
      )
    );
  }
}

final collaborationProvider = StateNotifierProvider<CollaborationNotifier, CollaborationState>((ref) {
  return CollaborationNotifier();
});

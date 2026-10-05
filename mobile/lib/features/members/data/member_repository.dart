import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/dio_client.dart';
import '../../gym/application/active_gym_controller.dart';
import '../domain/member.dart';
import '../domain/member_query.dart';

/// Result envelope for the paginated `GET /members` response.
class MemberListResult {
  const MemberListResult({
    required this.members,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<Member> members;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;
}

/// Plain Dart transport shape for `POST /members`. Server validates with
/// `memberCreateSchema` in `backend/src/members/member.schemas.ts`.
class MemberCreateInput {
  MemberCreateInput({
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.photo,
    this.dateOfBirth,
    this.gender,
    this.planId,
    this.membershipStart,
    this.notes,
    this.emergencyContact,
    this.amountPaid,
    this.paymentMethod,
    String? requestId,
  }) : requestId = requestId ?? const Uuid().v4();

  /// Client-generated UUID v4. The backend uses this to make the
  /// lifecycle mutation idempotent (see `runIdempotent` in
  /// `backend/src/lib/membershipLifecycle.ts`). Re-generated per call by
  /// default so the backend doesn't dedupe retries the user didn't make.
  final String requestId;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? photo;
  final String? dateOfBirth; // YYYY-MM-DD
  final String? gender; // 'male' | 'female' | 'other'
  final String? planId;
  final String? membershipStart; // YYYY-MM-DD
  final String? notes;
  final String? emergencyContact;
  final double? amountPaid;
  final String? paymentMethod; // 'cash' | 'card' | 'upi' | 'bank_transfer' | 'other'

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'name': name,
        'phone': phone,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (address != null && address!.isNotEmpty) 'address': address,
        if (photo != null && photo!.isNotEmpty) 'photo': photo,
        if (dateOfBirth != null && dateOfBirth!.isNotEmpty)
          'dateOfBirth': dateOfBirth,
        if (gender != null && gender!.isNotEmpty) 'gender': gender,
        if (planId != null && planId!.isNotEmpty) 'planId': planId,
        if (membershipStart != null && membershipStart!.isNotEmpty)
          'membershipStart': membershipStart,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (emergencyContact != null && emergencyContact!.isNotEmpty)
          'emergencyContact': emergencyContact,
        if (amountPaid != null) 'amountPaid': amountPaid,
        if (paymentMethod != null && paymentMethod!.isNotEmpty)
          'paymentMethod': paymentMethod,
      };
}

/// Plain Dart transport shape for `PUT /members/:id`. Mirrors
/// `memberUpdateSchema`.
class MemberUpdateInput {
  const MemberUpdateInput({
    this.name,
    this.email,
    this.phone,
    this.address,
    this.photo,
    this.dateOfBirth,
    this.gender,
    this.notes,
    this.emergencyContact,
    this.isActive,
  });

  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? photo;
  final String? dateOfBirth;
  final String? gender;
  final String? notes;
  final String? emergencyContact;
  final bool? isActive;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (photo != null) 'photo': photo,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (gender != null) 'gender': gender,
        if (notes != null) 'notes': notes,
        if (emergencyContact != null) 'emergencyContact': emergencyContact,
        if (isActive != null) 'isActive': isActive,
      };
}

/// Network access for the Members feature. Routes live in
/// `backend/src/members/member.controller.ts` and are scoped to the
/// selected gym via `RequireGymGuard` (the `X-Selected-Gym` header is
/// attached by `dio_client.dart`).
class MemberRepository {
  MemberRepository(this._dio);
  final Dio _dio;

  /// GET /members?search=&status=&page=&limit=
  Future<MemberListResult> getMembers(MemberListQuery query) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/members',
        queryParameters: {
          if (query.search != null && query.search!.isNotEmpty)
            'search': query.search,
          if (query.status != null && query.status!.isNotEmpty)
            'status': query.status,
          'page': query.page,
          'limit': query.limit,
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data!;
        final list = (data['members'] as List?) ?? const [];
        return MemberListResult(
          members: list
              .whereType<Map<String, dynamic>>()
              .map(Member.fromJson)
              .toList(),
          total: (data['total'] as num?)?.toInt() ?? list.length,
          page: (data['page'] as num?)?.toInt() ?? query.page,
          limit: (data['limit'] as num?)?.toInt() ?? query.limit,
        );
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// GET /members/:id
  Future<Member> getMember(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/members/$id');
      if (res.statusCode == 200 && res.data != null) {
        return Member.fromJson(res.data!);
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// POST /members — onboards a member, optionally with a Plan purchase
  /// and initial Payment. Backend uses `onboardMember` from
  /// `membershipLifecycle.ts` so the Member, Membership, and (optional)
  /// Payment writes commit in a single transaction.
  Future<MemberCreateResult> createMember(MemberCreateInput input) async {
    try {
      final res =
          await _dio.post<Map<String, dynamic>>('/members', data: input.toJson());
      if (res.statusCode == 201 && res.data != null) {
        final data = res.data!;
        final memberJson = data['member'];
        return MemberCreateResult(
          member: Member.fromJson(
            (memberJson as Map).cast<String, dynamic>(),
          ),
          payment: (data['payment'] is Map)
              ? (data['payment'] as Map).cast<String, dynamic>()
              : null,
          membershipId: data['membershipId'] as String?,
        );
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// PUT /members/:id — partial update (name/email/phone/etc + isActive).
  Future<Member> updateMember(String id, MemberUpdateInput input) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/members/$id',
        data: input.toJson(),
      );
      if (res.statusCode == 200 && res.data != null) {
        return Member.fromJson(res.data!);
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// DELETE /members/:id — soft delete (sets `isActive: false`).
  Future<void> softDeleteMember(String id) async {
    try {
      final res = await _dio.delete<dynamic>('/members/$id');
      if (res.statusCode == 200 || res.statusCode == 204) return;
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Object _badResponse(Response res) {
    return DioException(
      requestOptions: res.requestOptions,
      response: res,
      type: DioExceptionType.badResponse,
    );
  }
}

/// Decoded `POST /members` envelope. `payment` is the raw payment JSON
/// when an initial payment was taken; otherwise null. `membershipId` is
/// null when no plan was selected.
class MemberCreateResult {
  const MemberCreateResult({
    required this.member,
    this.payment,
    this.membershipId,
  });

  final Member member;
  final Map<String, dynamic>? payment;
  final String? membershipId;
}

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(ref.watch(dioProvider));
});

/// Paginated list of members for the active gym. Re-runs when the active
/// gym changes so switching tenants refreshes the data.
final memberListProvider =
    FutureProvider.autoDispose.family<MemberListResult, MemberListQuery>(
  (ref, query) {
    ref.watch(activeGymProvider);
    return ref.watch(memberRepositoryProvider).getMembers(query);
  },
);

/// Single-member detail. Watches the active gym so tenant switches
/// invalidate the open detail page.
final memberDetailProvider =
    FutureProvider.autoDispose.family<Member, String>((ref, id) {
  ref.watch(activeGymProvider);
  return ref.watch(memberRepositoryProvider).getMember(id);
});
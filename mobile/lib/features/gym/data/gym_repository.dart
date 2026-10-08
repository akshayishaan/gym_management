import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../domain/gym.dart';
import '../domain/gym_deletion_summary.dart';

/// Network access for Gym CRUD. Backend routes live in
/// `backend/src/gyms/gym.controller.ts` and are scoped to the staff's
/// accessible gymIds (no `RequireGymGuard` for the create endpoint).
class GymRepository {
  GymRepository(this._dio);
  final Dio _dio;

  /// GET /gyms — lists the staff's accessible gyms. The backend returns a
  /// bare JSON array, not a paginated envelope, so we decode as a list.
  Future<List<Gym>> listGyms() async {
    try {
      final res = await _dio.get<dynamic>('/gyms');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data;
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map(Gym.fromJson)
              .toList();
        }
        // Some NestJS controllers may wrap in { items: [...] }; tolerate.
        if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Gym.fromJson)
              .toList();
        }
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// GET /gyms/:id
  Future<Gym> getGym(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/gyms/$id');
      if (res.statusCode == 200 && res.data != null) {
        return Gym.fromJson(res.data!);
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// POST /gyms — creates a new Gym for this staff. The backend attaches
  /// the new gym to the creator's gymIds automatically (`ownerId` is set
  /// server-side). Currency / timezone / expiry defaults match the
  /// RepiX brand.
  Future<Gym> createGym({
    required String name,
    String? address,
    String? phone,
    String? email,
    String currency = 'INR',
    String timezone = 'Asia/Kolkata',
    String primaryColor = '#C5F23F',
    int expiryReminderDays = 7,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'primaryColor': primaryColor,
      'currency': currency,
      'timezone': timezone,
      'expiryReminderDays': expiryReminderDays,
      if (address != null && address.isNotEmpty) 'address': address,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
    };
    try {
      final res = await _dio.post<Map<String, dynamic>>('/gyms', data: payload);
      if (res.statusCode == 201 && res.data != null) {
        return Gym.fromJson(res.data!);
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// PUT /gyms/:id — partial update of gym settings.
  Future<Gym> updateGym(String id, Map<String, dynamic> patch) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/gyms/$id',
        data: patch,
      );
      if (res.statusCode == 200 && res.data != null) {
        return Gym.fromJson(res.data!);
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// GET /gyms/:id/deletion-summary — counts of what deleting would erase.
  Future<GymDeletionSummary> deletionSummary(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/gyms/$id/deletion-summary',
      );
      if (res.statusCode == 200 && res.data != null) {
        return GymDeletionSummary.fromJson(res.data!);
      }
      throw toApiException(_badResponse(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// DELETE /gyms/:id — permanently deletes the gym and all its data. The
  /// server requires the exact gym name and the caller's password.
  Future<void> deleteGym(
    String id, {
    required String confirmName,
    required String password,
  }) async {
    try {
      final res = await _dio.delete<dynamic>(
        '/gyms/$id',
        data: {'confirmName': confirmName, 'password': password},
      );
      if (res.statusCode == 200) return;
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

final gymRepositoryProvider = Provider<GymRepository>((ref) {
  return GymRepository(ref.watch(dioProvider));
});

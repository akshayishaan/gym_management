import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/core/api/api_exception.dart';
import 'package:gym_manager/core/api/dio_client.dart';
import 'package:gym_manager/features/members/data/member_repository.dart';
import 'package:gym_manager/features/members/domain/member.dart';
import 'package:gym_manager/features/members/presentation/member_detail_screen.dart';

/// Answers the three calls the History tab makes, and records the reversal.
class _FakeBackend implements HttpClientAdapter {
  final posts = <String>[];
  Object? reverseError;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    ResponseBody json(Object body, [int status = 200]) =>
        ResponseBody.fromString(
          jsonEncode(body),
          status,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
    if (options.method == 'POST' && options.path.endsWith('/reverse')) {
      posts.add(options.path);
      if (reverseError != null) {
        return json({
          'error': 'Reverse newer membership transactions first',
        }, 409);
      }
      return json({'membershipId': 'ms1'});
    }
    if (options.path == '/memberships') {
      return json({
        'memberships': [
          {
            '_id': 'ms1',
            'planName': 'Monthly',
            'startDate': '2026-10-13',
            'expiryDate': '2026-11-11',
            'status': 'active',
            'expiryStatus': 'active',
          },
        ],
      });
    }
    return json({'payments': []});
  }

  @override
  void close({bool force = false}) {}
}

const _member = Member(
  id: 'm1',
  gymId: 'g1',
  name: 'Akshay Kumar',
  phone: '8866325411',
);

Future<_FakeBackend> _open(WidgetTester tester) async {
  final backend = _FakeBackend();
  // Stand-in for the app's error mapper (private in dio_client.dart): turns a
  // 409 response into the ConflictException the screen reads its message from.
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = backend
    ..interceptors.add(
      InterceptorsWrapper(
        onError: (err, handler) => handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            type: DioExceptionType.badResponse,
            error: ConflictException(
              (err.response?.data as Map)['error'] as String,
            ),
          ),
        ),
      ),
    );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dioProvider.overrideWithValue(dio),
        memberDetailProvider('m1').overrideWith((ref) async => _member),
      ],
      child: const MaterialApp(home: MemberDetailScreen(id: 'm1')),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('History'));
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  testWidgets('Reverse Plan asks first, then posts the reversal', (
    tester,
  ) async {
    final backend = await _open(tester);

    await tester.tap(find.text('Reverse Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Reverse this plan?'), findsOneWidget);
    expect(backend.posts, isEmpty);

    await tester.tap(find.text('Reverse Plan').last);
    await tester.pumpAndSettle();
    expect(backend.posts, ['/memberships/ms1/reverse']);
    expect(find.text('Plan reversed'), findsOneWidget);
  });

  testWidgets('Keep closes the dialog without calling the backend', (
    tester,
  ) async {
    final backend = await _open(tester);

    await tester.tap(find.text('Reverse Plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();

    expect(find.text('Reverse this plan?'), findsNothing);
    expect(backend.posts, isEmpty);
  });

  testWidgets('shows the server message when the reversal is refused', (
    tester,
  ) async {
    final backend = await _open(tester);
    backend.reverseError = true;

    await tester.tap(find.text('Reverse Plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reverse Plan').last);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Reverse newer membership transactions first'),
      findsOneWidget,
    );
    expect(find.text('Plan reversed'), findsNothing);
  });
}

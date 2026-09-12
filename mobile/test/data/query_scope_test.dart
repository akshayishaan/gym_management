import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_api/gym_api.dart';
import 'package:gym_manager/core/api/dio_providers.dart';
import 'package:gym_manager/data/dashboard_providers.dart';
import 'package:gym_manager/data/filters.dart';
import 'package:gym_manager/data/member_providers.dart';
import 'package:gym_manager/data/query_scope.dart';

/// A minimal [HttpClientAdapter] that returns canned JSON and records every
/// request it serves.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._respond);

  final ResponseBody Function(RequestOptions options) _respond;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body) => ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );

const Map<String, dynamic> _dashboardBody = <String, dynamic>{
  'totalMembers': 10,
  'activeMembers': 8,
  'expiredMembers': 1,
  'expiringMembers': 1,
  'monthRevenue': 5000,
  'recentPayments': <dynamic>[],
  'expiringList': <dynamic>[],
};

const Map<String, dynamic> _membersBody = <String, dynamic>{
  'members': <dynamic>[],
  'total': 0,
  'page': 1,
  'limit': 20,
};

/// Invokes [invalidateGymScope] with a real [Ref], obtained by running a
/// throwaway provider (there is no other way to reach a [Ref] from a bare
/// [ProviderContainer]).
final Provider<void> _invalidateGymScopeTrigger = Provider<void>((ref) {
  invalidateGymScope(ref);
});

ProviderContainer _container(_FakeAdapter adapter) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
  dio.httpClientAdapter = adapter;
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      dioProvider.overrideWithValue(dio),
      selectedGymIdProvider.overrideWith((ref) => 'gym-1'),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ScopeLastFetch', () {
    test('isStale is true before the gym is ever touched', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final ScopeLastFetch notifier = container.read(
        scopeLastFetchProvider.notifier,
      );

      expect(notifier.isStale('gym-1', defaultStaleTime), isTrue);
    });

    test('isStale is false immediately after touch', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final ScopeLastFetch notifier = container.read(
        scopeLastFetchProvider.notifier,
      );
      notifier.touch('gym-1');

      expect(notifier.isStale('gym-1', defaultStaleTime), isFalse);
    });
  });

  group('invalidation', () {
    test('invalidateGymScope refetches the dashboard provider', () async {
      final _FakeAdapter adapter = _FakeAdapter((_) => _json(_dashboardBody));
      final ProviderContainer container = _container(adapter);

      // Keep the autoDispose provider alive so invalidate has a live instance
      // to mark dirty (rather than the read simply rebuilding after disposal).
      final ProviderSubscription<AsyncValue<DashboardResponse>> sub =
          container.listen(dashboardProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(dashboardProvider.future);
      expect(adapter.requests.length, 1);

      container.read(_invalidateGymScopeTrigger);

      final DashboardResponse second = await container.read(
        dashboardProvider.future,
      );
      expect(second.totalMembers, 10);
      expect(adapter.requests.length, 2);
    });

    test('bumping appResumeTickProvider refetches the dashboard provider',
        () async {
      final _FakeAdapter adapter = _FakeAdapter((_) => _json(_dashboardBody));
      final ProviderContainer container = _container(adapter);

      final ProviderSubscription<AsyncValue<DashboardResponse>> sub =
          container.listen(dashboardProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(dashboardProvider.future);
      expect(adapter.requests.length, 1);

      container.read(appResumeTickProvider.notifier).state++;

      final DashboardResponse second = await container.read(
        dashboardProvider.future,
      );
      expect(second.totalMembers, 10);
      expect(adapter.requests.length, 2);
    });

    test('members provider forwards only non-empty filters as query params',
        () async {
      final _FakeAdapter adapter = _FakeAdapter((_) => _json(_membersBody));
      final ProviderContainer container = _container(adapter);

      await container.read(
        membersProvider(const MemberFilters(search: 'ali', status: 'active'))
            .future,
      );

      expect(adapter.requests.length, 1);
      expect(adapter.requests.single.path, '/members');
      expect(adapter.requests.single.queryParameters, <String, dynamic>{
        'page': 1,
        'limit': 20,
        'search': 'ali',
        'status': 'active',
      });
    });

    test('members provider omits null and empty filters', () async {
      final _FakeAdapter adapter = _FakeAdapter((_) => _json(_membersBody));
      final ProviderContainer container = _container(adapter);

      await container.read(
        membersProvider(const MemberFilters(search: '')).future,
      );

      expect(adapter.requests.single.queryParameters, <String, dynamic>{
        'page': 1,
        'limit': 20,
      });
    });
  });

  group('gym selection', () {
    test('gym-scoped providers fail fast when no gym is selected', () async {
      final _FakeAdapter adapter = _FakeAdapter((_) => _json(_dashboardBody));
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          dioProvider.overrideWithValue(
            Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
              ..httpClientAdapter = adapter,
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(dashboardProvider.future),
        throwsA(isA<StateError>()),
      );
      expect(adapter.requests, isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/core/api/client_request_id.dart';

void main() {
  // 8-4-4-4-12 hex, version nibble `4`, variant nibble `8/9/a/b`.
  final RegExp uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('createRequestId returns a version 4 UUID', () {
    final String id = createRequestId();

    expect(uuidV4.hasMatch(id), isTrue, reason: 'got: $id');
    expect(id.toLowerCase(), id); // lowercase hex only
  });

  test('createRequestId returns unique values across many calls', () {
    final Set<String> ids = <String>{};
    for (int i = 0; i < 1000; i++) {
      ids.add(createRequestId());
    }

    expect(ids.length, 1000);
  });
}

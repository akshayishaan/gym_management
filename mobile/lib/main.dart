import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/api/dio_providers.dart';
import 'core/auth/token_storage.dart';
import 'data/app_lifecycle_refetch.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // The single app-wide TokenManager, backed by platform secure storage. The
  // bare `tokenManagerProvider` throws unless overridden here.
  final TokenManager tokenManager = TokenManager(SecureTokenStorage());

  runApp(
    ProviderScope(
      overrides: <Override>[
        tokenManagerProvider.overrideWithValue(tokenManager),
      ],
      child: const AppLifecycleRefetch(child: GymManagerApp()),
    ),
  );
}

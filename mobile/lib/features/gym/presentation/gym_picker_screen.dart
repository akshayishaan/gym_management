import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/spacing.dart';
import '../../auth/application/auth_controller.dart';
import '../data/gym_repository.dart';
import '../application/active_gym_controller.dart';
import '../domain/gym.dart';

/// Full-screen version of the gym picker. The Operations → My Gyms flow
/// reuses this; the modal bottom sheet uses the same widget in a sheet.
///
/// Posts the user's selection to the auth controller and routes home.
class GymPickerScreen extends ConsumerStatefulWidget {
  const GymPickerScreen({super.key});

  @override
  ConsumerState<GymPickerScreen> createState() => _GymPickerScreenState();
}

class _GymPickerScreenState extends ConsumerState<GymPickerScreen> {
  late final Future<List<Gym>> _gymsFuture;

  @override
  void initState() {
    super.initState();
    _gymsFuture = ref.read(gymRepositoryProvider).listGyms();
  }

  Future<void> _select(Gym gym) async {
    try {
      await ref
          .read(authControllerProvider.notifier)
          .onGymSelected(gym.id);
      if (!mounted) return;
      context.go('/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not switch: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Switch Active Gym'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/operations'),
        ),
      ),
      body: FutureBuilder<List<Gym>>(
        future: _gymsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            final err = snap.error;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  err is ApiException
                      ? err.message
                      : 'Could not load gyms.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }
          final gyms = snap.data ?? const [];
          final selectedId = ref.watch(selectedGymIdProvider);
          if (gyms.isEmpty) {
            return const Center(child: Text('No gyms available'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(LatoSpacing.lg),
            itemCount: gyms.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final g = gyms[i];
              final isActive = g.id == selectedId;
              return LatoCard(
                onTap: isActive ? null : () => _select(g),
                child: Row(
                  children: [
                    _GymAvatar(
                      name: g.name,
                      primaryColor: _parseHex(g.primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.name, style: theme.textTheme.titleMedium),
                          if (g.address != null && g.address!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              g.address!,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isActive)
                      Icon(Icons.check_circle, color: theme.colorScheme.primary)
                    else
                      Icon(Icons.chevron_right,
                          color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Avatar tile that shows the first letter of the gym name on a background
/// tinted with the gym's primary color. Falls back to the RepiX lime when
/// the brand color can't be parsed.
class _GymAvatar extends StatelessWidget {
  const _GymAvatar({required this.name, required this.primaryColor});
  final String name;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final letter =
        name.trim().isEmpty ? 'G' : name.trim().substring(0, 1).toUpperCase();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }
}

Color _parseHex(String hex) {
  final clean = hex.replaceFirst('#', '');
  final value = int.tryParse(clean, radix: 16);
  if (value == null) return const Color(0xFFC5F23F);
  if (clean.length == 6) return Color(0xFF000000 | value);
  if (clean.length == 8) return Color(value);
  return const Color(0xFFC5F23F);
}
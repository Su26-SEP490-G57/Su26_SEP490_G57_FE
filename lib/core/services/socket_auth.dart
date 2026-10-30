import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';

/// `setAuthFn` callback for `io.OptionBuilder()` — reads the current access
/// token fresh on every socket (re)connect, not just once at construction
/// time, so a token refresh mid-session is picked up on the next reconnect
/// instead of leaving the socket stuck with a stale token (Critical #1,
/// recommendations-2026-09-28.md). Shared by every realtime provider that
/// opens an authenticated socket.
void Function(void Function(Map auth) callback) socketAuthFn(Ref ref) {
  return (cb) => cb({'token': ref.read(authRepositoryProvider).getAccessToken()});
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Prefs keys ────────────────────────────────────────────────────────────────

const _kFirstRunDone = 'auth_first_run_done';
const _kOfflineMode  = 'auth_offline_mode';

Future<bool> getFirstRunDone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kFirstRunDone) ?? false;
}

Future<void> setFirstRunDone({required bool offline}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kFirstRunDone, true);
  await prefs.setBool(_kOfflineMode,  offline);
}

Future<bool> getOfflineMode() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOfflineMode) ?? false;
}

// ── State ─────────────────────────────────────────────────────────────────────

enum AuthStatus { loading, signedIn, signedOut, offline }

final class AppAuthState {
  const AppAuthState({
    required this.status,
    this.userId,
    this.email,
  });

  final AuthStatus status;
  final String?    userId;
  final String?    email;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<AppAuthState> {
  @override
  Future<AppAuthState> build() async {
    if (!await getFirstRunDone()) {
      return const AppAuthState(status: AuthStatus.signedOut);
    }

    final client = Supabase.instance.client;

    // Always subscribe to future auth changes once first-run is done.
    ref.onDispose(
      client.auth.onAuthStateChange.listen((data) {
        final user = data.session?.user;
        if (user != null) {
          state = AsyncData(AppAuthState(
            status: AuthStatus.signedIn,
            userId: user.id,
            email: user.email,
          ));
        } else {
          state = const AsyncData(AppAuthState(status: AuthStatus.signedOut));
        }
      }).cancel,
    );

    // Active session wins over the offline preference (handles sign-in from
    // Settings while the offline pref is still true).
    final current = client.auth.currentUser;
    if (current != null) {
      if (await getOfflineMode()) await setFirstRunDone(offline: false);
      return AppAuthState(
        status: AuthStatus.signedIn,
        userId: current.id,
        email: current.email,
      );
    }

    if (await getOfflineMode()) {
      return const AppAuthState(status: AuthStatus.offline);
    }
    return const AppAuthState(status: AuthStatus.signedOut);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      final resp = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);
      final user = resp.user;
      state = AsyncData(AppAuthState(
        status: user != null ? AuthStatus.signedIn : AuthStatus.signedOut,
        userId: user?.id,
        email: user?.email,
      ));
    } on AuthException catch (e) {
      state = AsyncError(e.message, StackTrace.current);
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.current);
    }
  }

  Future<void> signUp(String email, String password, String displayName) async {
    state = const AsyncLoading();
    try {
      final resp = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );
      final user = resp.user;
      state = AsyncData(AppAuthState(
        status: user != null ? AuthStatus.signedIn : AuthStatus.signedOut,
        userId: user?.id,
        email: user?.email,
      ));
    } on AuthException catch (e) {
      state = AsyncError(e.message, StackTrace.current);
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.current);
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    state = const AsyncData(AppAuthState(status: AuthStatus.signedOut));
  }

  Future<void> continueOffline() async {
    await setFirstRunDone(offline: true);
    state = const AsyncData(AppAuthState(status: AuthStatus.offline));
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AppAuthState>(AuthNotifier.new);

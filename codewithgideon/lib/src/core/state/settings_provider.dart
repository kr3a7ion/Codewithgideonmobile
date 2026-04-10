import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({required this.notifications, required this.darkMode});

  final bool notifications;
  final bool darkMode;

  AppSettings copyWith({bool? notifications, bool? darkMode}) {
    return AppSettings(
      notifications: notifications ?? this.notifications,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController()
    : super(const AppSettings(notifications: true, darkMode: false)) {
    _hydrate();
  }

  static const _notificationsKey = 'settings.notifications';
  static const _darkModeKey = 'settings.dark_mode';

  Future<void> _hydrate() async {
    final preferences = await SharedPreferences.getInstance();
    state = state.copyWith(
      notifications:
          preferences.getBool(_notificationsKey) ?? state.notifications,
      darkMode: preferences.getBool(_darkModeKey) ?? state.darkMode,
    );
  }

  void toggleNotifications() {
    state = state.copyWith(notifications: !state.notifications);
    _persist();
  }

  void toggleDarkMode() {
    state = state.copyWith(darkMode: !state.darkMode);
    _persist();
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_notificationsKey, state.notifications);
    await preferences.setBool(_darkModeKey, state.darkMode);
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, AppSettings>(
  (ref) {
    return SettingsController();
  },
);

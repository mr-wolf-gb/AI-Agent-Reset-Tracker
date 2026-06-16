class AppConstants {
  static const String appName = 'AgentVault';
  static const String appTagline = 'Your AI accounts, always in sync';
  static const String githubOwner = 'mr-wolf-gb';
  static const String githubRepo = 'AI-Agent-Reset-Tracker';
  static const String githubReleasesApiUrl =
      'https://api.github.com/repos/mr-wolf-gb/AI-Agent-Reset-Tracker/releases/latest';
  static const String defaultAiIdeListUrl =
      'https://raw.githubusercontent.com/mr-wolf-gb/AI-Agent-Reset-Tracker/main/assets/data/ai_ides.json';
  static const String localAiIdeListPath = 'assets/data/ai_ides.json';

  // Hive box names
  static const String aiIdesBox = 'ai_ides';
  static const String accountsBox = 'accounts';
  static const String settingsBox = 'app_settings';
  static const String settingsKey = 'settings';

  // Secure storage keys
  static const String accountPasswordPrefix = 'account_pw_';
  static const String appPinKey = 'app_pin';

  // Notification channel
  static const String notificationChannelId = 'agent_vault_resets';
  static const String notificationChannelName = 'Account Resets';
  static const String notificationChannelDesc =
      'Notifications for upcoming account resets';
}

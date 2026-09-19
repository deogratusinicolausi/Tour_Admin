class AdminSettingsModel {
  final bool emailNotifications;
  final bool pushNotifications;
  final bool bookingAlerts;
  final bool newUserAlerts;
  final bool reviewAlerts;
  final bool chatAlerts;
  final bool paymentAlerts;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool darkMode;
  final bool autoRefresh;
  final String language;
  final String currency;
  final String timezone;
  final int refreshInterval;

  AdminSettingsModel({
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.bookingAlerts = true,
    this.newUserAlerts = true,
    this.reviewAlerts = true,
    this.chatAlerts = true,
    this.paymentAlerts = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.darkMode = false,
    this.autoRefresh = true,
    this.language = 'English',
    this.currency = 'USD',
    this.timezone = 'Africa/Dar_es_Salaam',
    this.refreshInterval = 30,
  });

  factory AdminSettingsModel.fromMap(Map<String, dynamic> map) {
    return AdminSettingsModel(
      emailNotifications: map['emailNotifications'] ?? true,
      pushNotifications: map['pushNotifications'] ?? true,
      bookingAlerts: map['bookingAlerts'] ?? true,
      newUserAlerts: map['newUserAlerts'] ?? true,
      reviewAlerts: map['reviewAlerts'] ?? true,
      chatAlerts: map['chatAlerts'] ?? true,
      paymentAlerts: map['paymentAlerts'] ?? true,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      darkMode: map['darkMode'] ?? false,
      autoRefresh: map['autoRefresh'] ?? true,
      language: map['language'] ?? 'English',
      currency: map['currency'] ?? 'USD',
      timezone: map['timezone'] ?? 'Africa/Dar_es_Salaam',
      refreshInterval: map['refreshInterval'] ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'bookingAlerts': bookingAlerts,
      'newUserAlerts': newUserAlerts,
      'reviewAlerts': reviewAlerts,
      'chatAlerts': chatAlerts,
      'paymentAlerts': paymentAlerts,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'darkMode': darkMode,
      'autoRefresh': autoRefresh,
      'language': language,
      'currency': currency,
      'timezone': timezone,
      'refreshInterval': refreshInterval,
    };
  }

  AdminSettingsModel copyWith({
    bool? emailNotifications,
    bool? pushNotifications,
    bool? bookingAlerts,
    bool? newUserAlerts,
    bool? reviewAlerts,
    bool? chatAlerts,
    bool? paymentAlerts,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? darkMode,
    bool? autoRefresh,
    String? language,
    String? currency,
    String? timezone,
    int? refreshInterval,
  }) {
    return AdminSettingsModel(
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      bookingAlerts: bookingAlerts ?? this.bookingAlerts,
      newUserAlerts: newUserAlerts ?? this.newUserAlerts,
      reviewAlerts: reviewAlerts ?? this.reviewAlerts,
      chatAlerts: chatAlerts ?? this.chatAlerts,
      paymentAlerts: paymentAlerts ?? this.paymentAlerts,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      darkMode: darkMode ?? this.darkMode,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      refreshInterval: refreshInterval ?? this.refreshInterval,
    );
  }
}
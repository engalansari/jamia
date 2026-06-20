import 'package:flutter/material.dart';

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  bool get isArabic => locale.languageCode == 'ar';

  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  String get appName => isArabic ? '\u062c\u0645\u0639\u064a\u0629' : 'Jamia';
  String get languageTooltip =>
      isArabic ? 'English' : '\u0627\u0644\u0639\u0631\u0628\u064a\u0629';
  String get notifications => isArabic
      ? '\u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062a'
      : 'Notifications';
  String get searchAndLogs => isArabic
      ? '\u0627\u0644\u0628\u062d\u062b \u0648\u0627\u0644\u0633\u062c\u0644'
      : 'Search and logs';
  String get admin =>
      isArabic ? '\u0627\u0644\u0625\u062f\u0627\u0631\u0629' : 'Admin';
  String get signOut => isArabic
      ? '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062e\u0631\u0648\u062c'
      : 'Sign out';

  String get homeTitle => isArabic
      ? '\u062c\u0645\u0639\u064a\u0629 \u0627\u0644\u0628\u064a\u062a'
      : 'Home co-op';
  String get homeSubtitle => isArabic
      ? '\u0625\u062f\u0627\u0631\u0629 \u0637\u0644\u0628\u0627\u062a \u0627\u0644\u0645\u0642\u0627\u0636\u064a \u0628\u064a\u0646 \u0623\u0641\u0631\u0627\u062f \u0627\u0644\u0645\u0646\u0632\u0644'
      : 'Manage grocery requests between household members';
  String get noOpenRound => isArabic
      ? '\u0644\u0627 \u062a\u0648\u062c\u062f \u062c\u0648\u0644\u0629 \u0645\u0641\u062a\u0648\u062d\u0629 \u062d\u0627\u0644\u064a\u0627'
      : 'No open round right now';
  String get currentRequests => isArabic
      ? '\u0627\u0644\u0637\u0644\u0628\u0627\u062a \u0627\u0644\u062d\u0627\u0644\u064a\u0629'
      : 'Current requests';
  String get neededItems => isArabic
      ? '\u0627\u0644\u0623\u0635\u0646\u0627\u0641 \u0627\u0644\u0645\u0637\u0644\u0648\u0628\u0629'
      : 'Needed items';
  String get timeRemaining => isArabic
      ? '\u0627\u0644\u0648\u0642\u062a \u0627\u0644\u0645\u062a\u0628\u0642\u064a'
      : 'Time remaining';
  String get addRequest => isArabic
      ? '\u0625\u0636\u0627\u0641\u0629 \u0637\u0644\u0628'
      : 'Add request';
  String get createRequest => isArabic
      ? '\u0625\u0646\u0634\u0627\u0621 \u0637\u0644\u0628'
      : 'Create request';
  String get favorites =>
      isArabic ? '\u0627\u0644\u0645\u0641\u0636\u0644\u0629' : 'Favorites';
  String get atCoop => isArabic
      ? '\u0623\u0646\u0627 \u0641\u064a \u0627\u0644\u062c\u0645\u0639\u064a\u0629'
      : 'I am at the co-op';
  String get purchased => isArabic
      ? '\u0627\u0644\u0645\u0637\u0644\u0648\u0628 \u0634\u0631\u0627\u0626\u0647'
      : 'Needed to buy';
  String get openRoundFirst => isArabic
      ? '\u0627\u0641\u062a\u062d \u062c\u0645\u0639\u064a\u0629 \u0623\u0648\u0644\u0627 \u0642\u0628\u0644 \u0625\u0636\u0627\u0641\u0629 \u0627\u0644\u0637\u0644\u0628\u0627\u062a.'
      : 'Open a round before adding requests.';
  String get newRoundOpened => isArabic
      ? '\u062a\u0645 \u0641\u062a\u062d \u062c\u0645\u0639\u064a\u0629 \u062c\u062f\u064a\u062f\u0629.'
      : 'A new round was opened.';
  String get openRoundFailed => isArabic
      ? '\u062a\u0639\u0630\u0631 \u0641\u062a\u062d \u0627\u0644\u062c\u0645\u0639\u064a\u0629. \u062d\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062e\u0631\u0649.'
      : 'Could not open the round. Try again.';
  String get closeQuestion => isArabic
      ? '\u0645\u062a\u0649 \u064a\u062a\u0645 \u0625\u063a\u0644\u0627\u0642 \u0627\u0633\u062a\u0642\u0628\u0627\u0644 \u0627\u0644\u0637\u0644\u0628\u0627\u062a\u061f'
      : 'When should requests close?';
  String get acceptingRequests => isArabic
      ? '\u0627\u0633\u062a\u0642\u0628\u0627\u0644 \u0627\u0644\u0637\u0644\u0628\u0627\u062a \u0645\u0641\u062a\u0648\u062d'
      : 'Accepting requests';
  String get previewWhenRoundOpens => isArabic
      ? '\u0633\u062a\u0638\u0647\u0631 \u0647\u0646\u0627 \u0627\u0644\u0623\u0635\u0646\u0627\u0641 \u0627\u0644\u0645\u0637\u0644\u0648\u0628\u0629 \u0639\u0646\u062f \u0641\u062a\u062d \u062c\u0645\u0639\u064a\u0629 \u062c\u062f\u064a\u062f\u0629.'
      : 'Requested items will appear here when a new round opens.';
  String get noRequestsYet => isArabic
      ? '\u0627\u0644\u062c\u0645\u0639\u064a\u0629 \u0645\u0641\u062a\u0648\u062d\u0629\u060c \u0648\u0644\u0627 \u062a\u0648\u062c\u062f \u0637\u0644\u0628\u0627\u062a \u062d\u0627\u0644\u064a\u0627.'
      : 'The round is open, and there are no requests yet.';

  String get loginSubtitle => isArabic
      ? '\u062a\u0633\u062c\u064a\u0644 \u062f\u062e\u0648\u0644 \u0623\u0641\u0631\u0627\u062f \u0627\u0644\u0645\u0646\u0632\u0644'
      : 'Household member sign in';
  String get username => isArabic
      ? '\u0627\u0633\u0645 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645'
      : 'Username';
  String get password => isArabic
      ? '\u0627\u0644\u0631\u0642\u0645 \u0627\u0644\u0633\u0631\u064a'
      : 'Password';
  String get signIn => isArabic ? '\u062f\u062e\u0648\u0644' : 'Sign in';
  String get enterUsername => isArabic
      ? '\u0623\u062f\u062e\u0644 \u0627\u0633\u0645 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645'
      : 'Enter a username';
  String get enterPassword => isArabic
      ? '\u0623\u062f\u062e\u0644 \u0627\u0644\u0631\u0642\u0645 \u0627\u0644\u0633\u0631\u064a'
      : 'Enter a password';
  String get showPassword => isArabic
      ? '\u0625\u0638\u0647\u0627\u0631 \u0627\u0644\u0631\u0642\u0645 \u0627\u0644\u0633\u0631\u064a'
      : 'Show password';
  String get hidePassword => isArabic
      ? '\u0625\u062e\u0641\u0627\u0621 \u0627\u0644\u0631\u0642\u0645 \u0627\u0644\u0633\u0631\u064a'
      : 'Hide password';
  String get loginFailed => isArabic
      ? '\u062a\u0639\u0630\u0631 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644.'
      : 'Could not sign in.';
  String get accountNotReady => isArabic
      ? '\u0647\u0630\u0627 \u0627\u0644\u062d\u0633\u0627\u0628 \u063a\u064a\u0631 \u0645\u062c\u0647\u0632 \u062f\u0627\u062e\u0644 \u0627\u0644\u062a\u0637\u0628\u064a\u0642.'
      : 'This account is not ready inside the app.';
  String get accountDisabled => isArabic
      ? '\u062a\u0645 \u062a\u0639\u0637\u064a\u0644 \u0647\u0630\u0627 \u0627\u0644\u062d\u0633\u0627\u0628.'
      : 'This account has been disabled.';
  String get invalidCredentials => isArabic
      ? '\u0627\u0633\u0645 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645 \u0623\u0648 \u0627\u0644\u0631\u0642\u0645 \u0627\u0644\u0633\u0631\u064a \u063a\u064a\u0631 \u0635\u062d\u064a\u062d.'
      : 'The username or password is incorrect.';
  String get networkFailed => isArabic
      ? '\u062a\u062d\u0642\u0642 \u0645\u0646 \u0627\u0644\u0627\u062a\u0635\u0627\u0644 \u0628\u0627\u0644\u0625\u0646\u062a\u0631\u0646\u062a.'
      : 'Check your internet connection.';

  String minutes(int value) =>
      isArabic ? '$value \u062f\u0642\u0627\u0626\u0642' : '$value minutes';
  String minute(int value) =>
      isArabic ? '$value \u062f\u0642\u064a\u0642\u0629' : '$value minute';
  String hourMinute(int hours, int minutes) => isArabic
      ? '$hours \u0633\u0627\u0639\u0629 $minutes \u062f\u0642\u064a\u0642\u0629'
      : '$hours h $minutes min';
  String minuteSecond(int minutes, int seconds) => isArabic
      ? '$minutes \u062f\u0642\u064a\u0642\u0629 $seconds \u062b\u0627\u0646\u064a\u0629'
      : '$minutes min $seconds sec';
}

extension AppStringsContext on BuildContext {
  AppStrings get strings {
    final locale = Localizations.localeOf(this);
    return AppStrings(locale);
  }
}

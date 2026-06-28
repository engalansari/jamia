import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../core/localization/app_strings.dart';
import '../../core/models/app_user.dart';
import '../../core/models/model_enums.dart';
import '../../core/models/shopping_request.dart';
import '../../core/models/shopping_round.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/in_app_alert_service.dart';
import '../../core/services/messaging_service.dart';
import '../../core/services/request_service.dart';
import '../../core/services/round_service.dart';
import '../../main.dart';
import '../admin/admin_page.dart';
import '../notifications/notifications_page.dart';
import '../purchase/purchase_flow_page.dart';
import '../requests/request_editor_page.dart';
import '../search/search_and_logs_page.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, this.currentUser, this.enableLiveData = true});

  final AppUser? currentUser;
  final bool enableLiveData;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final nextLocale = strings.isArabic
        ? const Locale('en')
        : const Locale('ar');
    final content = enableLiveData
        ? _LiveRoundView(currentUser: currentUser)
        : _MainContent(
            currentUser: currentUser,
            round: null,
            neededRequests: const [],
            isLoadingRound: false,
          );
    final body = currentUser == null
        ? content
        : _InAppAlertListener(currentUser: currentUser!, child: content);

    return Scaffold(
      appBar: AppBar(
        leading: currentUser == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(start: 10),
                child: _UserBadge(currentUser: currentUser!),
              ),
        title: Text(strings.appName),
        actions: [
          IconButton(
            tooltip: strings.languageTooltip,
            onPressed: () => JamiaApp.setLocale(context, nextLocale),
            icon: const Icon(Icons.language),
          ),
          PopupMenuButton<_HomeMenuAction>(
            tooltip: 'Ø§Ù„Ù‚Ø§Ø¦Ù…Ø©',
            onSelected: (action) => _handleMenuAction(context, action, strings),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _HomeMenuAction.theme,
                child: ListTile(
                  leading: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  title: Text(
                    Theme.of(context).brightness == Brightness.dark
                        ? '\u0627\u0644\u062b\u064a\u0645 \u0627\u0644\u0646\u0647\u0627\u0631\u064a'
                        : '\u0627\u0644\u062b\u064a\u0645 \u0627\u0644\u0644\u064a\u0644\u064a',
                  ),
                ),
              ),
              const PopupMenuItem(
                value: _HomeMenuAction.background,
                child: ListTile(
                  leading: Icon(Icons.palette_outlined),
                  title: Text(
                    '\u0623\u0644\u0648\u0627\u0646 \u0627\u0644\u0623\u0631\u0636\u064a\u0629',
                  ),
                ),
              ),
              if (currentUser != null)
                PopupMenuItem(
                  value: _HomeMenuAction.notifications,
                  child: ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text(strings.notifications),
                  ),
                ),
              if (currentUser != null)
                PopupMenuItem(
                  value: _HomeMenuAction.search,
                  child: ListTile(
                    leading: const Icon(Icons.search),
                    title: Text(strings.searchAndLogs),
                  ),
                ),
              if (currentUser?.isAdmin == true)
                PopupMenuItem(
                  value: _HomeMenuAction.admin,
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: Text(strings.admin),
                  ),
                ),
              if (currentUser != null)
                PopupMenuItem(
                  value: _HomeMenuAction.signOut,
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(strings.signOut),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    _HomeMenuAction action,
    AppStrings strings,
  ) {
    switch (action) {
      case _HomeMenuAction.theme:
        JamiaApp.toggleTheme(context);
        return;
      case _HomeMenuAction.background:
        _showBackgroundColorSheet(context);
        return;
      case _HomeMenuAction.notifications:
        final user = currentUser;
        if (user == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NotificationsPage(currentUser: user),
          ),
        );
        return;
      case _HomeMenuAction.search:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SearchAndLogsPage(round: null),
          ),
        );
        return;
      case _HomeMenuAction.admin:
        final user = currentUser;
        if (user == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => AdminPage(currentUser: user)),
        );
        return;
      case _HomeMenuAction.signOut:
        AuthService().signOut();
        return;
    }
  }

  Future<void> _showBackgroundColorSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _BackgroundColorSheet(),
    );
  }
}

enum _HomeMenuAction {
  theme,
  background,
  notifications,
  search,
  admin,
  signOut,
}

class _InAppAlertListener extends StatefulWidget {
  const _InAppAlertListener({required this.currentUser, required this.child});

  final AppUser currentUser;
  final Widget child;

  @override
  State<_InAppAlertListener> createState() => _InAppAlertListenerState();
}

class _InAppAlertListenerState extends State<_InAppAlertListener> {
  StreamSubscription<List<InAppAlert>>? _subscription;
  final _shownAlertIds = <String>{};

  @override
  void initState() {
    super.initState();
    _listen();
    _runMaintenanceIfAdmin();
  }

  @override
  void didUpdateWidget(covariant _InAppAlertListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser.userId != widget.currentUser.userId) {
      _subscription?.cancel();
      _shownAlertIds.clear();
      _listen();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _listen() {
    _subscription = InAppAlertService()
        .watchPendingAlerts(widget.currentUser.userId)
        .listen((alerts) {
          for (final alert in alerts) {
            if (!_shownAlertIds.add(alert.alertId)) continue;
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(alert.message)));
            InAppAlertService().markSeen(alert.alertId);
          }
        });
  }

  void _runMaintenanceIfAdmin() {
    if (!widget.currentUser.isAdmin) return;
    unawaited(RoundService().cleanupClosedHistoryOlderThan30Days());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _UserBadge extends StatelessWidget {
  const _UserBadge({required this.currentUser});

  final AppUser currentUser;

  @override
  Widget build(BuildContext context) {
    final name = currentUser.displayName.trim().isNotEmpty
        ? currentUser.displayName.trim()
        : currentUser.username.trim();
    final initial = name.isEmpty ? '?' : name.characters.first;
    return Tooltip(
      message: name.isEmpty
          ? currentUser.roleLabel
          : '$name - ${currentUser.roleLabel}',
      child: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: Text(
          initial,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _BackgroundColorSheet extends StatelessWidget {
  const _BackgroundColorSheet();

  @override
  Widget build(BuildContext context) {
    final options = [
      _BackgroundColorOption(
        label: '\u0623\u0628\u064a\u0636',
        color: Colors.white,
      ),
      _BackgroundColorOption(
        label: '\u0623\u0632\u0631\u0642 \u0647\u0627\u062f\u0626',
        color: Color(0xFFF5F7FC),
      ),
      _BackgroundColorOption(
        label: '\u0623\u062e\u0636\u0631 \u0641\u0627\u062a\u062d',
        color: Color(0xFFF3FAF7),
      ),
      _BackgroundColorOption(
        label: '\u0639\u0627\u062c\u064a',
        color: Color(0xFFFFFEF7),
      ),
      _BackgroundColorOption(
        label: '\u0631\u0645\u0627\u062f\u064a \u0646\u0627\u0639\u0645',
        color: Color(0xFFF7F7F8),
      ),
      _BackgroundColorOption(
        label: '\u0641\u0636\u064a',
        color: Color(0xFFF3F4F6),
      ),
      _BackgroundColorOption(
        label: '\u0633\u0645\u0627\u0648\u064a',
        color: Color(0xFFF0F9FF),
      ),
      _BackgroundColorOption(
        label: '\u0646\u0639\u0646\u0627\u0639\u064a',
        color: Color(0xFFF0FDF4),
      ),
      _BackgroundColorOption(
        label: '\u0641\u064a\u0631\u0648\u0632\u064a',
        color: Color(0xFFF0FDFA),
      ),
      _BackgroundColorOption(
        label: '\u0644\u0627\u0641\u0646\u062f\u0631',
        color: Color(0xFFFAF5FF),
      ),
      _BackgroundColorOption(
        label: '\u0648\u0631\u062f\u064a \u0646\u0627\u0639\u0645',
        color: Color(0xFFFFF1F2),
      ),
      _BackgroundColorOption(
        label: '\u0645\u0634\u0645\u0634\u064a',
        color: Color(0xFFFFF7ED),
      ),
      _BackgroundColorOption(
        label: '\u0644\u064a\u0645\u0648\u0646\u064a',
        color: Color(0xFFFEFCE8),
      ),
      _BackgroundColorOption(
        label: '\u0632\u064a\u062a\u0648\u0646\u064a \u0641\u0627\u062a\u062d',
        color: Color(0xFFF7FEE7),
      ),
      _BackgroundColorOption(
        label: '\u0628\u0646\u0641\u0633\u062c\u064a \u0647\u0627\u062f\u0626',
        color: Color(0xFFF5F3FF),
      ),
    ];
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          Text(
            '\u0623\u0644\u0648\u0627\u0646 \u0627\u0644\u0623\u0631\u0636\u064a\u0629',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                _BackgroundColorTile(option: option),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackgroundColorTile extends StatelessWidget {
  const _BackgroundColorTile({required this.option});

  final _BackgroundColorOption option;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 78,
      child: Material(
        color: option.color,
        elevation: 1,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            JamiaApp.setLightBackground(context, option.color);
            Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            alignment: Alignment.bottomCenter,
            child: Text(
              option.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundColorOption {
  const _BackgroundColorOption({required this.label, required this.color});

  final String label;
  final Color color;
}

class _LiveRoundView extends StatelessWidget {
  const _LiveRoundView({required this.currentUser});

  final AppUser? currentUser;

  @override
  Widget build(BuildContext context) {
    final roundService = RoundService();

    return StreamBuilder<ShoppingRound?>(
      stream: roundService.watchCurrentRound(),
      builder: (context, snapshot) {
        final round = snapshot.data;
        return StreamBuilder<List<ShoppingRequest>>(
          stream: round == null
              ? Stream.value(const <ShoppingRequest>[])
              : roundService.watchNeededRequests(round.roundId),
          builder: (context, requestsSnapshot) {
            return _MainContent(
              currentUser: currentUser,
              round: round,
              neededRequests: requestsSnapshot.data ?? const [],
              isLoadingRound:
                  snapshot.connectionState == ConnectionState.waiting,
            );
          },
        );
      },
    );
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent({
    required this.currentUser,
    required this.round,
    required this.neededRequests,
    required this.isLoadingRound,
  });

  final AppUser? currentUser;
  final ShoppingRound? round;
  final List<ShoppingRequest> neededRequests;
  final bool isLoadingRound;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = context.strings;
    final uniqueItemCount = neededRequests
        .map((request) => request.itemId)
        .toSet()
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          strings.homeTitle,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.homeSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        if (currentUser != null) ...[
          if (kIsWeb) ...[
            const SizedBox(height: 10),
            _WebPushOptInCard(currentUser: currentUser!),
          ],
        ],
        const SizedBox(height: 12),
        if (isLoadingRound)
          const Center(child: CircularProgressIndicator())
        else
          _StatusPanel(
            colorScheme: colorScheme,
            round: round,
            neededRequestCount: neededRequests.length,
            neededItemCount: uniqueItemCount,
          ),
        const SizedBox(height: 12),
        _ActionGrid(currentUser: currentUser, round: round),
        if (currentUser != null) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SearchAndLogsPage(round: round),
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            icon: const Icon(Icons.search),
            label: Text(strings.searchAndLogs),
          ),
        ],
        const SizedBox(height: 12),
        _RequestsPreview(
          colorScheme: colorScheme,
          round: round,
          currentUser: currentUser,
          neededRequests: neededRequests,
        ),
      ],
    );
  }
}

class _WebPushOptInCard extends StatefulWidget {
  const _WebPushOptInCard({required this.currentUser});

  final AppUser currentUser;

  @override
  State<_WebPushOptInCard> createState() => _WebPushOptInCardState();
}

class _WebPushOptInCardState extends State<_WebPushOptInCard> {
  var _isRegistering = false;
  late Future<NotificationSettings> _notificationSettings;

  @override
  void initState() {
    super.initState();
    _notificationSettings = MessagingService().getNotificationSettings();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NotificationSettings>(
      future: _notificationSettings,
      builder: (context, snapshot) {
        final status = snapshot.data?.authorizationStatus;
        final isEnabled =
            status == AuthorizationStatus.authorized ||
            status == AuthorizationStatus.provisional;
        return LayoutBuilder(
          builder: (context, constraints) {
            final fullWidth = constraints.maxWidth < 420;
            final buttons = [
              OutlinedButton.icon(
                onPressed: _isRegistering || isEnabled
                    ? null
                    : _enableNotifications,
                icon: _isRegistering
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_active_outlined,
                      ),
                label: Text(
                  isEnabled
                      ? '\u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062a \u0645\u0641\u0639\u0644\u0629'
                      : '\u062a\u0641\u0639\u064a\u0644 \u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062a',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _openNotificationSettings(context),
                icon: const Icon(Icons.tune),
                label: const Text(
                  '\u0625\u0639\u062f\u0627\u062f\u0627\u062a \u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062a',
                ),
              ),
            ];

            if (fullWidth) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final button in buttons) ...[
                    button,
                    if (button != buttons.last) const SizedBox(height: 8),
                  ],
                ],
              );
            }

            return Wrap(spacing: 8, runSpacing: 8, children: buttons);
          },
        );
      },
    );
  }

  Future<void> _enableNotifications() async {
    setState(() => _isRegistering = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await MessagingService().registerDevice(
        widget.currentUser,
      );
      if (!mounted) return;
      setState(() {
        _notificationSettings = MessagingService().getNotificationSettings();
      });
      messenger.showSnackBar(SnackBar(content: Text(_messageFor(result))));
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  Future<void> _openNotificationSettings(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          _NotificationPreferencesSheet(currentUser: widget.currentUser),
    );
  }

  String _messageFor(MessagingRegistrationResult result) {
    switch (result) {
      case MessagingRegistrationResult.registered:
        return '\u062a\u0645 \u062a\u0641\u0639\u064a\u0644 \u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062a.';
      case MessagingRegistrationResult.missingWebPushKey:
        return '\u064a\u062c\u0628 \u0625\u0636\u0627\u0641\u0629 \u0645\u0641\u062a\u0627\u062d Web Push \u0623\u0648\u0644\u0627.';
      case MessagingRegistrationResult.permissionDenied:
        return '\u062a\u0645 \u0631\u0641\u0636 \u0625\u0630\u0646 \u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062a.';
      case MessagingRegistrationResult.noToken:
        return '\u0644\u0645 \u064a\u062a\u0645 \u0625\u0646\u0634\u0627\u0621 \u062a\u0648\u0643\u0646 \u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062a.';
    }
  }
}

class _NotificationPreferencesSheet extends StatelessWidget {
  const _NotificationPreferencesSheet({required this.currentUser});

  final AppUser currentUser;

  @override
  Widget build(BuildContext context) {
    final service = MessagingService();
    return SafeArea(
      child: StreamBuilder<NotificationPreferences>(
        stream: service.watchNotificationPreferences(currentUser.userId),
        builder: (context, snapshot) {
          final preferences = snapshot.data ?? const NotificationPreferences();
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: [
              Text(
                '\u0625\u0639\u062f\u0627\u062f\u0627\u062a \u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062a',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _NotificationPreferenceSwitch(
                title:
                    '\u0625\u0634\u0639\u0627\u0631 \u0639\u0646\u062f \u0625\u0646\u0634\u0627\u0621 \u0637\u0644\u0628 \u062c\u062f\u064a\u062f',
                subtitle:
                    '\u064a\u0635\u0644 \u0645\u0631\u0629 \u0648\u0627\u062d\u062f\u0629 \u0639\u0646\u062f \u0628\u062f\u0621 \u0625\u0636\u0627\u0641\u0629 \u0627\u0644\u0637\u0644\u0628\u0627\u062a.',
                value: preferences.requestCreated,
                onChanged: (value) => service.saveNotificationPreferences(
                  currentUser.userId,
                  preferences.copyWith(requestCreated: value),
                ),
              ),
              const SizedBox(height: 8),
              _NotificationPreferenceSwitch(
                title:
                    '\u0625\u0634\u0639\u0627\u0631 \u0639\u0646\u062f \u0628\u062f\u0621 \u0627\u0644\u062c\u0645\u0639\u064a\u0629',
                subtitle:
                    '\u064a\u0635\u0644 \u0639\u0646\u062f \u0627\u062e\u062a\u064a\u0627\u0631 \u0648\u0642\u062a \u0623\u0646\u0627 \u0641\u064a \u0627\u0644\u062c\u0645\u0639\u064a\u0629.',
                value: preferences.shoppingStarted,
                onChanged: (value) => service.saveNotificationPreferences(
                  currentUser.userId,
                  preferences.copyWith(shoppingStarted: value),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationPreferenceSwitch extends StatelessWidget {
  const _NotificationPreferenceSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8E0F6)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(subtitle),
        secondary: Icon(
          value ? Icons.notifications_active : Icons.notifications_off_outlined,
        ),
      ),
    );
  }
}

class _StatusPanel extends StatefulWidget {
  const _StatusPanel({
    required this.colorScheme,
    required this.round,
    required this.neededRequestCount,
    required this.neededItemCount,
  });

  final ColorScheme colorScheme;
  final ShoppingRound? round;
  final int neededRequestCount;
  final int neededItemCount;

  @override
  State<_StatusPanel> createState() => _StatusPanelState();
}

class _StatusPanelState extends State<_StatusPanel> {
  Timer? _timer;
  var _isClosingExpiredRound = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
      _closeExpiredRoundIfNeeded();
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _closeExpiredRoundIfNeeded(),
    );
  }

  @override
  void didUpdateWidget(covariant _StatusPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.round?.roundId != widget.round?.roundId) {
      _isClosingExpiredRound = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _closeExpiredRoundIfNeeded(),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _closeExpiredRoundIfNeeded() async {
    final round = widget.round;
    if (round == null || round.isOpen || _isClosingExpiredRound) return;
    _isClosingExpiredRound = true;
    await RoundService().closeRoundIfExpired(round);
  }

  @override
  Widget build(BuildContext context) {
    final round = widget.round;
    final strings = context.strings;
    final title = round?.isOpen == true ? round!.name : strings.noOpenRound;
    final remaining = round == null
        ? '--'
        : round.isShopping
        ? _formatDuration(round.remainingFrom(DateTime.now()))
        : strings.acceptingRequests;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF5A6EA8), width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1D2B53),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.today, color: Color(0xFF4F6198)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF172033),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final metricWidth = (constraints.maxWidth - 12) / 3;
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Metric(
                    label: strings.currentRequests,
                    value: widget.neededRequestCount.toString(),
                    width: metricWidth,
                  ),
                  _Metric(
                    label: strings.neededItems,
                    value: widget.neededItemCount.toString(),
                    width: metricWidth,
                  ),
                  _Metric(
                    label: strings.timeRemaining,
                    value: remaining,
                    width: metricWidth,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final strings = context.strings;
    if (duration == Duration.zero) return strings.minute(0);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return strings.hourMinute(hours, minutes);
    }
    final seconds = duration.inSeconds.remainder(60);
    return strings.minuteSecond(minutes, seconds);
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.width,
  });

  final String label;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    final valueTextStyle =
        (value.characters.length > 8
                ? Theme.of(context).textTheme.titleSmall
                : Theme.of(context).textTheme.titleMedium)
            ?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF25345D),
              height: 1.1,
            );

    return SizedBox(
      width: width.clamp(92, 160),
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD8E0F6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: valueTextStyle,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF5A6478),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.currentUser, required this.round});

  final AppUser? currentUser;
  final ShoppingRound? round;

  bool get hasOpenRound => round?.isOpen ?? false;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = [
          _HomeActionData(
            icon: Icons.add_shopping_cart,
            label: hasOpenRound ? strings.addRequest : strings.createRequest,
            tone: _HomeActionTone.primary,
            size: _HomeActionSize.large,
            onPressed: currentUser == null
                ? null
                : () => _openRequestEditor(context, favoritesOnly: false),
          ),
          _HomeActionData(
            icon: Icons.star,
            label: strings.favorites,
            tone: _HomeActionTone.secondary,
            size: _HomeActionSize.medium,
            onPressed: currentUser == null
                ? null
                : () => _openRequestEditor(context, favoritesOnly: true),
          ),
          _HomeActionData(
            icon: Icons.storefront,
            label: strings.atCoop,
            tone: _HomeActionTone.tertiary,
            size: _HomeActionSize.medium,
            onPressed: currentUser == null
                ? null
                : () => _showOpenRoundSheet(context, currentUser!),
          ),
          _HomeActionData(
            icon: Icons.receipt_long,
            label: strings.purchased,
            tone: _HomeActionTone.primary,
            size: _HomeActionSize.small,
            onPressed: hasOpenRound
                ? () => _openPurchaseFlow(context)
                : () => _showClosedRoundMessage(context),
          ),
        ];

        if (constraints.maxWidth >= 720) {
          return Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final action in actions)
                  _HomeAction(
                    action: action,
                    width: ((constraints.maxWidth - 30) / 4).clamp(150, 220),
                    height: 52,
                  ),
              ],
            ),
          );
        }

        final buttonWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final action in actions)
              _HomeAction(
                action: action,
                width: buttonWidth,
                height: constraints.maxWidth < 380 ? 62 : 58,
              ),
          ],
        );
      },
    );
  }

  void _openPurchaseFlow(BuildContext context) {
    final user = currentUser;
    final openRound = round;
    if (user == null || openRound == null || !openRound.isOpen) {
      _showClosedRoundMessage(context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            PurchaseFlowPage(currentUser: user, round: openRound),
      ),
    );
  }

  void _openRequestEditor(BuildContext context, {required bool favoritesOnly}) {
    _openOrCreateRequestEditor(context, favoritesOnly: favoritesOnly);
  }

  Future<void> _openOrCreateRequestEditor(
    BuildContext context, {
    required bool favoritesOnly,
  }) async {
    final user = currentUser;
    var openRound = round;
    if (user == null) {
      _showClosedRoundMessage(context);
      return;
    }
    if (openRound == null || !openRound.isOpen) {
      try {
        openRound = await RoundService().createRequestRound(createdBy: user);
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.strings.openRoundFailed)),
        );
        return;
      }
    }
    if (!context.mounted) return;
    final editorRound = openRound;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RequestEditorPage(
          currentUser: user,
          round: editorRound,
          favoritesOnly: favoritesOnly,
        ),
      ),
    );
  }

  void _showClosedRoundMessage(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.strings.openRoundFirst)));
  }

  Future<void> _showOpenRoundSheet(BuildContext context, AppUser user) async {
    final selectedAction = await showModalBottomSheet<_OpenRoundAction>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          _OpenRoundSheet(canActiveShoppingTime: round?.isShopping == true),
    );
    if (selectedAction == null || !context.mounted) return;

    try {
      if (selectedAction.cancelTime) {
        final openRound = round;
        if (openRound == null) return;
        await RoundService().cancelShoppingTime(openRound);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\u062a\u0645 \u0625\u0644\u063a\u0627\u0621 \u0648\u0642\u062a \u0627\u0644\u062c\u0645\u0639\u064a\u0629.',
            ),
          ),
        );
        return;
      }
      if (selectedAction.finishShopping) {
        final openRound = round;
        if (openRound == null) return;
        await RoundService().finishShoppingRound(openRound);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\u062a\u0645 \u0625\u0646\u0647\u0627\u0621 \u0627\u0644\u062c\u0645\u0639\u064a\u0629 \u0648\u0646\u0642\u0644 \u0627\u0644\u0645\u062a\u0628\u0642\u064a \u0625\u0644\u0649 \u0627\u0644\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u062c\u062f\u064a\u062f\u0629.',
            ),
          ),
        );
        return;
      }
      await RoundService().startShoppingRound(
        startedBy: user,
        round: round,
        duration: selectedAction.duration,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.strings.newRoundOpened)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.strings.openRoundFailed)));
    }
  }
}

class _OpenRoundSheet extends StatelessWidget {
  const _OpenRoundSheet({required this.canActiveShoppingTime});

  final bool canActiveShoppingTime;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final options = [
      _RoundDurationOption(
        label: strings.minutes(5),
        duration: Duration(minutes: 5),
      ),
      _RoundDurationOption(
        label: strings.minutes(10),
        duration: Duration(minutes: 10),
      ),
      _RoundDurationOption(
        label: strings.minute(15),
        duration: Duration(minutes: 15),
      ),
      _RoundDurationOption(
        label: strings.minute(30),
        duration: Duration(minutes: 30),
      ),
      _RoundDurationOption(
        label: strings.isArabic ? '\u0633\u0627\u0639\u0629' : '1 hour',
        duration: Duration(hours: 1),
      ),
    ];

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Text(
            strings.closeQuestion,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final option in options)
            ListTile(
              leading: const Icon(Icons.timer),
              title: Text(option.label),
              onTap: () => Navigator.of(
                context,
              ).pop(_OpenRoundAction.start(option.duration)),
            ),
          if (canActiveShoppingTime) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.done_all),
              title: const Text(
                '\u062a\u0645 \u0627\u0644\u0627\u0646\u062a\u0647\u0627\u0621 \u0645\u0646 \u0627\u0644\u062c\u0645\u0639\u064a\u0629',
              ),
              onTap: () =>
                  Navigator.of(context).pop(_OpenRoundAction.finishShopping()),
            ),
            ListTile(
              leading: const Icon(Icons.timer_off_outlined),
              title: const Text(
                '\u0625\u0644\u063a\u0627\u0621 \u0648\u0642\u062a \u0627\u0644\u062c\u0645\u0639\u064a\u0629',
              ),
              onTap: () => Navigator.of(context).pop(_OpenRoundAction.cancel()),
            ),
          ],
        ],
      ),
    );
  }
}

class _OpenRoundAction {
  const _OpenRoundAction._({
    required this.duration,
    required this.cancelTime,
    required this.finishShopping,
  });

  factory _OpenRoundAction.start(Duration duration) {
    return _OpenRoundAction._(
      duration: duration,
      cancelTime: false,
      finishShopping: false,
    );
  }

  factory _OpenRoundAction.cancel() {
    return const _OpenRoundAction._(
      duration: Duration.zero,
      cancelTime: true,
      finishShopping: false,
    );
  }

  factory _OpenRoundAction.finishShopping() {
    return const _OpenRoundAction._(
      duration: Duration.zero,
      cancelTime: false,
      finishShopping: true,
    );
  }

  final Duration duration;
  final bool cancelTime;
  final bool finishShopping;
}

class _RoundDurationOption {
  const _RoundDurationOption({required this.label, required this.duration});

  final String label;
  final Duration duration;
}

class _HomeActionData {
  const _HomeActionData({
    required this.icon,
    required this.label,
    required this.tone,
    required this.size,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final _HomeActionTone tone;
  final _HomeActionSize size;
  final VoidCallback? onPressed;
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.action,
    required this.width,
    required this.height,
  });

  final _HomeActionData action;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = switch (action.tone) {
      _HomeActionTone.primary => (
        isDark ? const Color(0xFF6F8CFF) : const Color(0xFF2F55C7),
        Colors.white,
      ),
      _HomeActionTone.secondary => (
        isDark ? const Color(0xFFB58CFF) : const Color(0xFF7B4CC2),
        Colors.white,
      ),
      _HomeActionTone.tertiary => (
        isDark ? const Color(0xFF5DD8C9) : const Color(0xFF167A72),
        Colors.white,
      ),
    };
    final metrics = switch (action.size) {
      _HomeActionSize.small => (18.0, 13.0),
      _HomeActionSize.medium => (20.0, 14.0),
      _HomeActionSize.large => (22.0, 15.0),
    };
    final backgroundColor = action.onPressed == null
        ? colorScheme.surfaceContainerHighest
        : colors.$1;
    final foregroundColor = action.onPressed == null
        ? colorScheme.onSurfaceVariant
        : colors.$2;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: backgroundColor,
        elevation: action.onPressed == null ? 0 : 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: action.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(action.icon, color: foregroundColor, size: metrics.$1),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    action.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: metrics.$2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _HomeActionTone { primary, secondary, tertiary }

enum _HomeActionSize { small, medium, large }

String _formatQuantity(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

class _RequestsPreview extends StatelessWidget {
  const _RequestsPreview({
    required this.colorScheme,
    required this.round,
    required this.currentUser,
    required this.neededRequests,
  });

  final ColorScheme colorScheme;
  final ShoppingRound? round;
  final AppUser? currentUser;
  final List<ShoppingRequest> neededRequests;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF9AAEF0), width: 1.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.strings.currentRequests,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (round == null)
            Text(context.strings.previewWhenRoundOpens)
          else if (neededRequests.isEmpty)
            Text(context.strings.noRequestsYet)
          else
            ...neededRequests.map((request) {
              final canEdit =
                  currentUser != null &&
                  round?.isOpen == true &&
                  request.requestedBy == currentUser!.userId;
              final tile = ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(
                  request.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${_formatQuantity(request.quantity)} ${request.unit}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: Icon(
                  _priorityIcon(request.priority),
                  color: _priorityColor(request.priority),
                ),
                trailing: canEdit ? const Icon(Icons.edit) : null,
                onTap: canEdit
                    ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditRequestPage(
                            request: request,
                            currentUser: currentUser!,
                          ),
                        ),
                      )
                    : null,
              );
              if (!canEdit) return tile;
              return Dismissible(
                key: ValueKey('home-request-${request.requestId}'),
                direction: DismissDirection.horizontal,
                background: _DeleteSwipeBackground(
                  alignment: Alignment.centerLeft,
                ),
                secondaryBackground: _DeleteSwipeBackground(
                  alignment: Alignment.centerRight,
                ),
                confirmDismiss: (_) => _confirmDelete(context, request),
                child: tile,
              );
            }),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    ShoppingRequest request,
  ) async {
    final user = currentUser;
    if (user == null) return false;
    await RequestService().deleteRequest(request: request, deletedBy: user);
    if (!context.mounted) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ØªÙ… Ø¥Ù„ØºØ§Ø¡ ${request.itemName}.')),
    );
    return true;
  }
}

class _DeleteSwipeBackground extends StatelessWidget {
  const _DeleteSwipeBackground({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}

IconData _priorityIcon(RequestPriority priority) {
  switch (priority) {
    case RequestPriority.important:
      return Icons.priority_high;
    case RequestPriority.medium:
      return Icons.error_outline;
    case RequestPriority.normal:
      return Icons.shopping_cart_outlined;
  }
}

Color? _priorityColor(RequestPriority priority) {
  switch (priority) {
    case RequestPriority.important:
      return Colors.red;
    case RequestPriority.medium:
      return Colors.orange;
    case RequestPriority.normal:
      return null;
  }
}

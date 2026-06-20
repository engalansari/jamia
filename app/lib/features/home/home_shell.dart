import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/models/app_user.dart';
import '../../core/models/model_enums.dart';
import '../../core/models/shopping_request.dart';
import '../../core/models/shopping_round.dart';
import '../../core/services/auth_service.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName),
        backgroundColor: const Color(0xFFF5F7FC),
        actions: [
          IconButton(
            tooltip: strings.languageTooltip,
            onPressed: () => JamiaApp.setLocale(context, nextLocale),
            icon: const Icon(Icons.language),
          ),
          if (currentUser != null)
            IconButton(
              tooltip: strings.notifications,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      NotificationsPage(currentUser: currentUser!),
                ),
              ),
              icon: const Icon(Icons.notifications),
            ),
          if (currentUser != null)
            IconButton(
              tooltip: strings.searchAndLogs,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SearchAndLogsPage(round: null),
                ),
              ),
              icon: const Icon(Icons.search),
            ),
          if (currentUser?.isAdmin == true)
            IconButton(
              tooltip: strings.admin,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AdminPage(currentUser: currentUser!),
                ),
              ),
              icon: const Icon(Icons.admin_panel_settings),
            ),
          if (currentUser != null)
            IconButton(
              tooltip: strings.signOut,
              onPressed: AuthService().signOut,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: SafeArea(
        child: enableLiveData
            ? _LiveRoundView(currentUser: currentUser)
            : _MainContent(
                currentUser: currentUser,
                round: null,
                neededRequests: const [],
                isLoadingRound: false,
              ),
      ),
    );
  }
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
          const SizedBox(height: 14),
          _UserBanner(currentUser: currentUser!, colorScheme: colorScheme),
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
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SearchAndLogsPage(round: round),
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

class _UserBanner extends StatelessWidget {
  const _UserBanner({required this.currentUser, required this.colorScheme});

  final AppUser currentUser;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF9AAEF0), width: 1.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            child: Text(
              currentUser.displayName.isEmpty
                  ? '?'
                  : currentUser.displayName.characters.first,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text('@${currentUser.username}'),
              ],
            ),
          ),
          Chip(label: Text(currentUser.roleLabel)),
        ],
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
    return SizedBox(
      width: width.clamp(92, 160),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD8E0F6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF25345D),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _HomeAction(
          icon: Icons.add_shopping_cart,
          label: hasOpenRound ? strings.addRequest : strings.createRequest,
          onPressed: currentUser == null
              ? null
              : () => _openRequestEditor(context, favoritesOnly: false),
        ),
        _HomeAction(
          icon: Icons.star,
          label: strings.favorites,
          onPressed: currentUser == null
              ? null
              : () => _openRequestEditor(context, favoritesOnly: true),
        ),
        _HomeAction(
          icon: Icons.storefront,
          label: strings.atCoop,
          onPressed: currentUser == null
              ? null
              : () => _showOpenRoundSheet(context, currentUser!),
        ),
        _HomeAction(
          icon: Icons.receipt_long,
          label: strings.purchased,
          onPressed: hasOpenRound
              ? () => _openPurchaseFlow(context)
              : () => _showClosedRoundMessage(context),
        ),
      ],
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
    final selectedDuration = await showModalBottomSheet<Duration>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _OpenRoundSheet(),
    );
    if (selectedDuration == null || !context.mounted) return;

    try {
      await RoundService().startShoppingRound(
        startedBy: user,
        round: round,
        duration: selectedDuration,
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
  const _OpenRoundSheet();

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
              onTap: () => Navigator.of(context).pop(option.duration),
            ),
        ],
      ),
    );
  }
}

class _RoundDurationOption {
  const _RoundDurationOption({required this.label, required this.duration});

  final String label;
  final Duration duration;
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('تم إلغاء ${request.itemName}.')));
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

import 'package:flutter/material.dart';

import '../../core/models/app_user.dart';
import '../../core/models/model_enums.dart';
import '../../core/models/shopping_request.dart';
import '../../core/models/shopping_round.dart';
import '../../core/services/request_service.dart';

class PurchaseFlowPage extends StatelessWidget {
  const PurchaseFlowPage({
    super.key,
    required this.currentUser,
    required this.round,
  });

  final AppUser currentUser;
  final ShoppingRound round;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المطلوب شرائه'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list_alt), text: 'المطلوب'),
              Tab(icon: Icon(Icons.shopping_bag), text: 'تم شراؤه'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RequestStatusList(
              round: round,
              currentUser: currentUser,
              status: RequestStatus.needed,
            ),
            _RequestStatusList(
              round: round,
              currentUser: currentUser,
              status: RequestStatus.purchased,
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestStatusList extends StatelessWidget {
  const _RequestStatusList({
    required this.round,
    required this.currentUser,
    required this.status,
  });

  final ShoppingRound round;
  final AppUser currentUser;
  final RequestStatus status;

  bool get isNeededList => status == RequestStatus.needed;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ShoppingRequest>>(
      stream: RequestService().watchRoundRequests(
        roundId: round.roundId,
        status: status,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final groups = _groupRequests(snapshot.data ?? const []);
        if (groups.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                isNeededList
                    ? 'لا توجد طلبات مطلوبة حاليا.'
                    : 'لم يتم شراء أي طلب حتى الآن.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final group = groups[index];
            final tile = _PurchaseRequestTile(
              group: group,
              currentUser: currentUser,
              canPurchase: isNeededList && round.isOpen,
            );
            if (!isNeededList || !round.isOpen) return tile;
            return Dismissible(
              key: ValueKey('purchase-group-${group.key}'),
              direction: DismissDirection.horizontal,
              background: const _DeleteSwipeBackground(
                alignment: Alignment.centerLeft,
              ),
              secondaryBackground: const _DeleteSwipeBackground(
                alignment: Alignment.centerRight,
              ),
              confirmDismiss: (_) => _deleteGroup(context, group),
              child: tile,
            );
          },
        );
      },
    );
  }

  Future<bool> _deleteGroup(
    BuildContext context,
    _ShoppingRequestGroup group,
  ) async {
    for (final request in group.requests) {
      await RequestService().deleteRequest(
        request: request,
        deletedBy: currentUser,
      );
    }
    if (!context.mounted) return true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('تم إلغاء ${group.itemName}.')));
    return true;
  }
}

class _PurchaseRequestTile extends StatefulWidget {
  const _PurchaseRequestTile({
    required this.group,
    required this.currentUser,
    required this.canPurchase,
  });

  final _ShoppingRequestGroup group;
  final AppUser currentUser;
  final bool canPurchase;

  @override
  State<_PurchaseRequestTile> createState() => _PurchaseRequestTileState();
}

class _PurchaseRequestTileState extends State<_PurchaseRequestTile> {
  var _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: _RequestImage(
        imageUrl: group.imageUrl,
        priority: group.highestPriority,
      ),
      title: Text(group.itemName),
      subtitle: Text(_subtitle(group)),
      trailing: widget.canPurchase
          ? FilledButton.icon(
              onPressed: _isSaving ? null : () => _markPurchased(context),
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('تم'),
            )
          : const Icon(Icons.check_circle, color: Colors.green),
    );
  }

  String _subtitle(_ShoppingRequestGroup group) {
    final parts = <String>[
      '${_formatQuantity(group.quantity)} ${group.unit}',
      _priorityLabel(group.highestPriority),
    ];
    if (group.note?.trim().isNotEmpty == true) {
      parts.add(group.note!.trim());
    }
    if (group.requests.length > 1) {
      parts.add('مجموع ${group.requests.length} طلبات');
    }
    if (group.isPurchased) {
      final purchaser =
          group.requests.first.purchasedByName ??
          group.requests.first.purchasedBy;
      if (purchaser?.isNotEmpty == true) parts.add('اشتراه: $purchaser');
      final purchasedAt = group.requests.first.purchasedAt;
      if (purchasedAt != null) {
        parts.add('وقت الشراء: ${_formatTime(purchasedAt)}');
      }
    }
    return parts.join(' • ');
  }

  Future<void> _markPurchased(BuildContext context) async {
    setState(() => _isSaving = true);
    try {
      for (final request in widget.group.requests) {
        await RequestService().markPurchased(
          request: request,
          purchasedBy: widget.currentUser,
        );
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم نقل ${widget.group.itemName} إلى المشتريات.'),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديث الطلب. حاول مرة أخرى.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _RequestImage extends StatelessWidget {
  const _RequestImage({required this.imageUrl, required this.priority});

  final String? imageUrl;
  final RequestPriority priority;

  @override
  Widget build(BuildContext context) {
    final icon = _priorityIcon(priority);
    final color = _priorityColor(priority);
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(child: Icon(icon, color: color));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            CircleAvatar(child: Icon(icon, color: color)),
      ),
    );
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
      color: Colors.red.shade600,
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}

class _ShoppingRequestGroup {
  const _ShoppingRequestGroup({required this.requests});

  final List<ShoppingRequest> requests;

  ShoppingRequest get first => requests.first;
  String get key => '${first.itemId}-${first.unit}-${first.status.name}';
  String get itemName => first.itemName;
  String get unit => first.unit;
  String? get note => first.note;
  String? get imageUrl => first.thumbnailUrl ?? first.imageUrl;
  bool get isPurchased => first.isPurchased;
  double get quantity =>
      requests.fold(0, (sum, request) => sum + request.quantity);

  RequestPriority get highestPriority {
    var priority = RequestPriority.normal;
    for (final request in requests) {
      if (_priorityRank(request.priority) > _priorityRank(priority)) {
        priority = request.priority;
      }
    }
    return priority;
  }
}

List<_ShoppingRequestGroup> _groupRequests(List<ShoppingRequest> requests) {
  final grouped = <String, List<ShoppingRequest>>{};
  for (final request in requests) {
    final key = '${request.itemId}-${request.unit}-${request.status.name}';
    grouped.putIfAbsent(key, () => <ShoppingRequest>[]).add(request);
  }
  final groups = grouped.values
      .map((requests) => _ShoppingRequestGroup(requests: requests))
      .toList();
  groups.sort((a, b) => a.itemName.compareTo(b.itemName));
  return groups;
}

int _priorityRank(RequestPriority priority) {
  switch (priority) {
    case RequestPriority.normal:
      return 0;
    case RequestPriority.medium:
      return 1;
    case RequestPriority.important:
      return 2;
  }
}

String _formatQuantity(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _priorityLabel(RequestPriority priority) {
  switch (priority) {
    case RequestPriority.important:
      return 'مهم';
    case RequestPriority.medium:
      return 'متوسط';
    case RequestPriority.normal:
      return 'عادي';
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

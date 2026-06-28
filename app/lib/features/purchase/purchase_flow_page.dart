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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '\u0627\u0644\u0645\u0637\u0644\u0648\u0628 \u0634\u0631\u0627\u0624\u0647',
        ),
      ),
      body: StreamBuilder<List<ShoppingRequest>>(
        stream: RequestService().watchRoundRequests(roundId: round.roundId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allGroups = _groupRequests(snapshot.data ?? const []);
          final neededGroups = allGroups
              .where((group) => group.status == RequestStatus.needed)
              .toList();
          final newListGroups = allGroups
              .where((group) => group.status == RequestStatus.newList)
              .toList();
          final purchasedGroups = allGroups
              .where((group) => group.status == RequestStatus.purchased)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
            children: [
              _PurchaseSection(
                title:
                    '\u0627\u0644\u0645\u0637\u0644\u0648\u0628 \u0634\u0631\u0627\u0624\u0647',
                emptyText:
                    '\u0644\u0627 \u062a\u0648\u062c\u062f \u0637\u0644\u0628\u0627\u062a \u0645\u0637\u0644\u0648\u0628\u0629 \u062d\u0627\u0644\u064a\u0627.',
                icon: Icons.shopping_cart_outlined,
                groups: neededGroups,
                builder: (group) => _PurchaseRequestTile(
                  group: group,
                  currentUser: currentUser,
                  canToggle: round.isOpen,
                  purchasedStyle: false,
                ),
              ),
              const SizedBox(height: 18),
              _PurchaseSection(
                title:
                    '\u0627\u0644\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u062c\u062f\u064a\u062f\u0629',
                emptyText:
                    '\u0644\u0627 \u062a\u0648\u062c\u062f \u0623\u0635\u0646\u0627\u0641 \u0641\u064a \u0627\u0644\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u062c\u062f\u064a\u062f\u0629.',
                icon: Icons.playlist_add_check,
                groups: newListGroups,
                builder: (group) => _PurchaseRequestTile(
                  group: group,
                  currentUser: currentUser,
                  canToggle: false,
                  purchasedStyle: false,
                ),
              ),
              const SizedBox(height: 18),
              _PurchaseSection(
                title: '\u062a\u0645 \u0634\u0631\u0627\u0624\u0647',
                emptyText:
                    '\u0644\u0645 \u064a\u062a\u0645 \u0634\u0631\u0627\u0621 \u0623\u064a \u0637\u0644\u0628 \u062d\u062a\u0649 \u0627\u0644\u0622\u0646.',
                icon: Icons.check_circle_outline,
                groups: purchasedGroups,
                builder: (group) => _PurchaseRequestTile(
                  group: group,
                  currentUser: currentUser,
                  canToggle: round.isOpen,
                  purchasedStyle: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PurchaseSection extends StatelessWidget {
  const _PurchaseSection({
    required this.title,
    required this.emptyText,
    required this.icon,
    required this.groups,
    required this.builder,
  });

  final String title;
  final String emptyText;
  final IconData icon;
  final List<_ShoppingRequestGroup> groups;
  final Widget Function(_ShoppingRequestGroup group) builder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Chip(label: Text(groups.length.toString())),
          ],
        ),
        const SizedBox(height: 8),
        if (groups.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD8E0F6)),
            ),
            child: Text(emptyText, textAlign: TextAlign.center),
          )
        else
          ..._buildCategoryGroups(),
      ],
    );
  }

  List<Widget> _buildCategoryGroups() {
    final widgets = <Widget>[];
    String? currentCategory;
    for (final group in groups) {
      final category = group.categoryTitle;
      if (category != currentCategory) {
        currentCategory = category;
        widgets.add(_CategoryHeader(title: category));
      }
      widgets.add(builder(group));
      widgets.add(const SizedBox(height: 8));
    }
    return widgets;
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseRequestTile extends StatefulWidget {
  const _PurchaseRequestTile({
    required this.group,
    required this.currentUser,
    required this.canToggle,
    required this.purchasedStyle,
  });

  final _ShoppingRequestGroup group;
  final AppUser currentUser;
  final bool canToggle;
  final bool purchasedStyle;

  @override
  State<_PurchaseRequestTile> createState() => _PurchaseRequestTileState();
}

class _PurchaseRequestTileState extends State<_PurchaseRequestTile> {
  var _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final colorScheme = Theme.of(context).colorScheme;
    final isPurchased = widget.purchasedStyle;
    return Material(
      color: Colors.white,
      elevation: isPurchased ? 0 : 1,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: widget.canToggle && !_isSaving ? () => _toggle(context) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              _RequestImage(
                imageUrl: group.imageUrl,
                priority: group.highestPriority,
                muted: isPurchased,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: isPurchased
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: isPurchased
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _subtitle(group),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        decoration: isPurchased
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_isSaving)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  isPurchased
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: isPurchased
                      ? Colors.green.shade700
                      : colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
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
      parts.add(
        '\u0645\u062c\u0645\u0648\u0639 ${group.requests.length} \u0637\u0644\u0628\u0627\u062a',
      );
    }
    if (group.isPurchased) {
      final purchaser =
          group.requests.first.purchasedByName ??
          group.requests.first.purchasedBy;
      if (purchaser?.isNotEmpty == true) {
        parts.add('\u0627\u0634\u062a\u0631\u0627\u0647: $purchaser');
      }
      final purchasedAt = group.requests.first.purchasedAt;
      if (purchasedAt != null) {
        parts.add(
          '\u0648\u0642\u062a \u0627\u0644\u0634\u0631\u0627\u0621: ${_formatTime(purchasedAt)}',
        );
      }
    }
    return parts.join(' - ');
  }

  Future<void> _toggle(BuildContext context) async {
    setState(() => _isSaving = true);
    try {
      if (widget.purchasedStyle) {
        for (final request in widget.group.requests) {
          await RequestService().markNeeded(
            request: request,
            updatedBy: widget.currentUser,
          );
        }
      } else {
        for (final request in widget.group.requests) {
          await RequestService().markPurchased(
            request: request,
            purchasedBy: widget.currentUser,
          );
        }
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u062a\u0639\u0630\u0631 \u062a\u062d\u062f\u064a\u062b \u0627\u0644\u0637\u0644\u0628. \u062d\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062e\u0631\u0649.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _RequestImage extends StatelessWidget {
  const _RequestImage({
    required this.imageUrl,
    required this.priority,
    required this.muted,
  });

  final String? imageUrl;
  final RequestPriority priority;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final icon = _priorityIcon(priority);
    final color = muted ? Colors.grey : _priorityColor(priority);
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(child: Icon(icon, color: color));
    }
    return Opacity(
      opacity: muted ? 0.55 : 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              CircleAvatar(child: Icon(icon, color: color)),
        ),
      ),
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
  RequestStatus get status => first.status;
  String get categoryTitle {
    final name = first.categoryName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final id = first.categoryId?.trim();
    if (id != null && id.isNotEmpty) return id;
    return '\u0628\u062f\u0648\u0646 \u0642\u0633\u0645';
  }

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
    final key =
        '${request.categoryId ?? ''}-${request.itemId}-${request.unit}-${request.status.name}';
    grouped.putIfAbsent(key, () => <ShoppingRequest>[]).add(request);
  }
  final groups = grouped.values
      .map((requests) => _ShoppingRequestGroup(requests: requests))
      .toList();
  groups.sort((a, b) {
    final categoryCompare = a.categoryTitle.compareTo(b.categoryTitle);
    if (categoryCompare != 0) return categoryCompare;
    return a.itemName.compareTo(b.itemName);
  });
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
      return '\u0645\u0647\u0645';
    case RequestPriority.medium:
      return '\u0645\u062a\u0648\u0633\u0637';
    case RequestPriority.normal:
      return '\u0639\u0627\u062f\u064a';
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

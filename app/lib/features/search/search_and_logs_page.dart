import 'package:flutter/material.dart';

import '../../core/models/category.dart';
import '../../core/models/model_enums.dart';
import '../../core/models/operation_log.dart';
import '../../core/models/shopping_request.dart';
import '../../core/models/shopping_round.dart';
import '../../core/services/admin_data_service.dart';
import '../../core/services/operation_log_service.dart';
import '../../core/services/request_service.dart';
import '../../core/services/round_service.dart';

class SearchAndLogsPage extends StatelessWidget {
  const SearchAndLogsPage({super.key, required this.round});

  final ShoppingRound? round;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('البحث والسجل'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.search), text: 'البحث'),
              Tab(icon: Icon(Icons.history), text: 'السجل'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RequestSearchTab(round: round),
            const _OperationLogTab(),
          ],
        ),
      ),
    );
  }
}

enum _SearchStatusFilter { all, needed, purchased }

class _RequestSearchTab extends StatefulWidget {
  const _RequestSearchTab({required this.round});

  final ShoppingRound? round;

  @override
  State<_RequestSearchTab> createState() => _RequestSearchTabState();
}

class _RequestSearchTabState extends State<_RequestSearchTab> {
  final _search = TextEditingController();
  String _activeSearchQuery = '';
  var _statusFilter = _SearchStatusFilter.all;
  String? _categoryId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final round = widget.round;
    if (round == null) {
      return StreamBuilder<ShoppingRound?>(
        stream: RoundService().watchCurrentRound(),
        builder: (context, snapshot) => _buildSearchContent(snapshot.data),
      );
    }
    return _buildSearchContent(round);
  }

  Widget _buildSearchContent(ShoppingRound? round) {
    return StreamBuilder<List<Category>>(
      stream: AdminDataService().watchCategories(),
      builder: (context, categoriesSnapshot) {
        final categories = categoriesSnapshot.data ?? const <Category>[];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _activeSearchQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'مسح البحث',
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close),
                            ),
                      labelText: 'اسم المنتج أو المستخدم',
                      hintText: 'اكتب كلمة البحث',
                    ),
                    onSubmitted: (_) => _runSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _runSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('ابحث'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _categoryId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'التصنيف',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('كل التصنيفات'),
                ),
                for (final category in categories)
                  DropdownMenuItem<String?>(
                    value: category.categoryId,
                    child: Text(category.nameAr),
                  ),
              ],
              onChanged: (value) => setState(() => _categoryId = value),
            ),
            const SizedBox(height: 12),
            SegmentedButton<_SearchStatusFilter>(
              segments: const [
                ButtonSegment(
                  value: _SearchStatusFilter.all,
                  label: Text('الكل'),
                ),
                ButtonSegment(
                  value: _SearchStatusFilter.needed,
                  label: Text('الحالي'),
                ),
                ButtonSegment(
                  value: _SearchStatusFilter.purchased,
                  label: Text('المشترى'),
                ),
              ],
              selected: {_statusFilter},
              onSelectionChanged: (values) =>
                  setState(() => _statusFilter = values.first),
            ),
            const SizedBox(height: 16),
            if (round == null)
              const _EmptyState(text: 'افتح جمعية حتى تظهر طلبات البحث هنا.')
            else
              StreamBuilder<List<ShoppingRequest>>(
                stream: RequestService().watchRoundRequests(
                  roundId: round.roundId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final requests = _filter(snapshot.data ?? const []);
                  if (requests.isEmpty) {
                    return const _EmptyState(text: 'لا توجد نتائج مطابقة.');
                  }
                  return Column(
                    children: [
                      for (final request in requests)
                        _RequestSearchTile(request: request),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }

  List<ShoppingRequest> _filter(List<ShoppingRequest> requests) {
    final query = _normalizeSearchText(_activeSearchQuery);
    return requests.where((request) {
      final matchesStatus = switch (_statusFilter) {
        _SearchStatusFilter.all => true,
        _SearchStatusFilter.needed => request.status == RequestStatus.needed,
        _SearchStatusFilter.purchased =>
          request.status == RequestStatus.purchased,
      };
      final matchesCategory =
          _categoryId == null || request.categoryId == _categoryId;
      final searchableText = [
        request.itemName,
        request.categoryName,
        request.requestedByName,
        request.requestedBy,
        request.purchasedByName,
        request.purchasedBy,
        request.note,
      ].whereType<String>().join(' ');
      final normalizedText = _normalizeSearchText(searchableText);
      final matchesQuery = query.isEmpty || normalizedText.contains(query);
      return matchesStatus && matchesCategory && matchesQuery;
    }).toList();
  }

  void _runSearch() {
    FocusScope.of(context).unfocus();
    setState(() => _activeSearchQuery = _search.text.trim());
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _activeSearchQuery = '');
  }
}

class _RequestSearchTile extends StatelessWidget {
  const _RequestSearchTile({required this.request});

  final ShoppingRequest request;

  @override
  Widget build(BuildContext context) {
    final isPurchased = request.status == RequestStatus.purchased;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isPurchased ? Icons.check_circle : Icons.shopping_cart_outlined,
        color: isPurchased ? Colors.green : null,
      ),
      title: Text(request.itemName),
      subtitle: Text(_subtitle(request)),
      trailing: Text(isPurchased ? 'مشترى' : 'حالي'),
    );
  }

  String _subtitle(ShoppingRequest request) {
    final parts = <String>[
      '${_formatQuantity(request.quantity)} ${request.unit}',
    ];
    if (request.categoryName?.isNotEmpty == true) {
      parts.add(request.categoryName!);
    }
    if (request.requestedByName?.isNotEmpty == true) {
      parts.add('طلبه: ${request.requestedByName}');
    }
    if (request.purchasedByName?.isNotEmpty == true) {
      parts.add('اشتراه: ${request.purchasedByName}');
    }
    if (request.note?.trim().isNotEmpty == true) {
      parts.add(request.note!.trim());
    }
    return parts.join(' • ');
  }
}

class _OperationLogTab extends StatelessWidget {
  const _OperationLogTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OperationLog>>(
      stream: OperationLogService().watchLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data ?? const <OperationLog>[];
        if (logs.isEmpty) {
          return const _EmptyState(text: 'لا يوجد سجل عمليات حتى الآن.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => _OperationLogTile(log: logs[index]),
        );
      },
    );
  }
}

class _OperationLogTile extends StatelessWidget {
  const _OperationLogTile({required this.log});

  final OperationLog log;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_logIcon(log.actionType)),
      title: Text(_logTitle(log)),
      subtitle: Text(_logSubtitle(log)),
      trailing: Text(_formatTime(log.createdAt)),
    );
  }

  String _logTitle(OperationLog log) {
    final item = log.itemName.isEmpty ? 'طلب' : log.itemName;
    return '${_actionLabel(log.actionType)}: $item';
  }

  String _logSubtitle(OperationLog log) {
    final parts = <String>[log.userName, log.details];
    if (log.categoryName?.isNotEmpty == true) parts.add(log.categoryName!);
    if (log.quantity != null && log.unit?.isNotEmpty == true) {
      parts.add('${_formatQuantity(log.quantity!)} ${log.unit}');
    }
    return parts.where((part) => part.trim().isNotEmpty).join(' • ');
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(child: Text(text, textAlign: TextAlign.center)),
    );
  }
}

String _formatQuantity(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

String _normalizeSearchText(String value) {
  return value
      .toLowerCase()
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .trim();
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _actionLabel(LogActionType actionType) {
  switch (actionType) {
    case LogActionType.requestCreated:
      return 'إضافة';
    case LogActionType.requestUpdated:
      return 'تعديل';
    case LogActionType.requestDeleted:
      return 'حذف';
    case LogActionType.requestPurchased:
      return 'شراء';
    default:
      return 'عملية';
  }
}

IconData _logIcon(LogActionType actionType) {
  switch (actionType) {
    case LogActionType.requestCreated:
      return Icons.add_circle_outline;
    case LogActionType.requestUpdated:
      return Icons.edit_outlined;
    case LogActionType.requestDeleted:
      return Icons.delete_outline;
    case LogActionType.requestPurchased:
      return Icons.check_circle_outline;
    default:
      return Icons.history;
  }
}

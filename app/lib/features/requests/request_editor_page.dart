import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/app_user.dart';
import '../../core/models/category.dart';
import '../../core/models/grocery_item.dart';
import '../../core/models/model_enums.dart';
import '../../core/models/shopping_request.dart';
import '../../core/models/shopping_round.dart';
import '../../core/services/admin_data_service.dart';
import '../../core/services/request_service.dart';

class RequestEditorPage extends StatefulWidget {
  const RequestEditorPage({
    super.key,
    required this.currentUser,
    required this.round,
    this.favoritesOnly = false,
  });

  final AppUser currentUser;
  final ShoppingRound round;
  final bool favoritesOnly;

  @override
  State<RequestEditorPage> createState() => _RequestEditorPageState();
}

class _RequestEditorPageState extends State<RequestEditorPage> {
  late bool _favoritesOnly;

  @override
  void initState() {
    super.initState();
    _favoritesOnly = widget.favoritesOnly;
  }

  @override
  Widget build(BuildContext context) {
    final title = _favoritesOnly
        ? '\u0627\u0644\u0645\u0641\u0636\u0644\u0629'
        : '\u0625\u0636\u0627\u0641\u0629 \u0637\u0644\u0628';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<GroceryItem>>(
        stream: RequestService().watchActiveItems(
          favoritesOnly: _favoritesOnly,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _RequestEditorMessage(
              message:
                  '\u062a\u0639\u0630\u0631 \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0623\u0635\u0646\u0627\u0641. \u062a\u0623\u0643\u062f \u0645\u0646 \u0627\u0644\u0627\u062a\u0635\u0627\u0644 \u0648\u0635\u0644\u0627\u062d\u064a\u0627\u062a Firestore.',
              action: widget.currentUser.isAdmin
                  ? FilledButton.icon(
                      onPressed: () => _seedDefaultCatalog(context),
                      icon: const Icon(Icons.inventory_2),
                      label: const Text(
                        '\u0625\u0636\u0627\u0641\u0629 \u0645\u0648\u0627\u062f \u0623\u0633\u0627\u0633\u064a\u0629',
                      ),
                    )
                  : null,
            );
          }
          final items = snapshot.data ?? const <GroceryItem>[];
          if (items.isEmpty) {
            return _RequestEditorMessage(
              message: _favoritesOnly
                  ? 'لا توجد أصناف مفضلة.'
                  : 'لا توجد أصناف.',
              action: !_favoritesOnly && widget.currentUser.isAdmin
                  ? FilledButton.icon(
                      onPressed: () => _seedDefaultCatalog(context),
                      icon: const Icon(Icons.inventory_2),
                      label: const Text(
                        '\u0625\u0636\u0627\u0641\u0629 \u0645\u0648\u0627\u062f \u0623\u0633\u0627\u0633\u064a\u0629',
                      ),
                    )
                  : null,
            );
          }
          return StreamBuilder<List<Category>>(
            stream: AdminDataService().watchCategories(),
            builder: (context, categoriesSnapshot) {
              final categories = categoriesSnapshot.data ?? const <Category>[];
              final groups = _groupItemsByCategory(items, categories);
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                itemCount: groups.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _RequestEditorHeader(
                      round: widget.round,
                      favoritesOnly: _favoritesOnly,
                      onFavoritesOnlyChanged: (value) =>
                          setState(() => _favoritesOnly = value),
                    );
                  }

                  final group = groups[index - 1];
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD8E0F6)),
                    ),
                    child: ExpansionTile(
                      dense: true,
                      leading: const Icon(Icons.category, size: 22),
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                      title: Text(
                        group.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text('${group.items.length} صنف'),
                      initiallyExpanded: groups.length == 1,
                      children: [
                        for (final item in group.items)
                          _QuickRequestItemTile(
                            item: item,
                            onQuickAdd: () => _addQuickRequest(context, item),
                            onDetails: () => _showRequestSheet(context, item),
                            onFavoriteChanged: (value) =>
                                AdminDataService().setItemFavorite(item, value),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _seedDefaultCatalog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await RequestService().seedDefaultCatalog();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            '\u062a\u0645\u062a \u0625\u0636\u0627\u0641\u0629 \u0645\u0648\u0627\u062f \u0623\u0633\u0627\u0633\u064a\u0629.',
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            '\u062a\u0639\u0630\u0631 \u0625\u0636\u0627\u0641\u0629 \u0627\u0644\u0645\u0648\u0627\u062f. \u062a\u0623\u0643\u062f \u0645\u0646 \u0635\u0644\u0627\u062d\u064a\u0627\u062a Firestore.',
          ),
        ),
      );
    }
  }

  Future<void> _showRequestSheet(BuildContext context, GroceryItem item) async {
    final result = await showModalBottomSheet<_RequestFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _RequestFormSheet(item: item),
    );
    if (result == null || !context.mounted) return;

    await RequestService().addRequest(
      roundId: widget.round.roundId,
      item: item,
      quantity: result.quantity,
      unit: result.unit,
      priority: result.priority,
      requestedBy: widget.currentUser,
      note: result.note,
      imageBytes: result.imageBytes,
      imageContentType: result.imageContentType,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '\u062a\u0645 \u0625\u0636\u0627\u0641\u0629 \u0627\u0644\u0637\u0644\u0628.',
        ),
      ),
    );
  }

  Future<void> _addQuickRequest(BuildContext context, GroceryItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await RequestService().addRequest(
        roundId: widget.round.roundId,
        item: item,
        quantity: 1,
        unit: item.defaultUnit,
        priority: RequestPriority.normal,
        requestedBy: widget.currentUser,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('تمت إضافة ${item.nameAr} إلى القائمة.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('تعذر إضافة الطلب. حاول مرة أخرى.')),
      );
    }
  }
}

class _RequestEditorHeader extends StatelessWidget {
  const _RequestEditorHeader({
    required this.round,
    required this.favoritesOnly,
    required this.onFavoritesOnlyChanged,
  });

  final ShoppingRound round;
  final bool favoritesOnly;
  final ValueChanged<bool> onFavoritesOnlyChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF9AAEF0), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_note, color: Color(0xFF4F6198)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  round.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  _formatArabicDateTime(round.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            segments: const [
              ButtonSegment(value: false, label: Text('الكل')),
              ButtonSegment(value: true, label: Text('المفضلة')),
            ],
            selected: {favoritesOnly},
            onSelectionChanged: (values) =>
                onFavoritesOnlyChanged(values.first),
          ),
        ],
      ),
    );
  }
}

String _formatArabicDateTime(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'م' : 'ص';
  return 'اليوم ${value.year}/${value.month}/${value.day} - $hour:$minute $period';
}

class _QuickRequestItemTile extends StatefulWidget {
  const _QuickRequestItemTile({
    required this.item,
    required this.onQuickAdd,
    required this.onDetails,
    required this.onFavoriteChanged,
  });

  final GroceryItem item;
  final Future<void> Function() onQuickAdd;
  final VoidCallback onDetails;
  final ValueChanged<bool> onFavoriteChanged;

  @override
  State<_QuickRequestItemTile> createState() => _QuickRequestItemTileState();
}

class _QuickRequestItemTileState extends State<_QuickRequestItemTile> {
  var _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: IconButton(
        tooltip: item.isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
        visualDensity: VisualDensity.compact,
        onPressed: () => widget.onFavoriteChanged(!item.isFavorite),
        icon: Icon(
          item.isFavorite ? Icons.star : Icons.star_border,
          color: item.isFavorite ? const Color(0xFFC58A00) : null,
          size: 22,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.nameAr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _isAdding ? null : _add,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(86, 34),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: _isAdding
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_shopping_cart, size: 18),
            label: const Text('إضافة'),
          ),
        ],
      ),
      subtitle: Text(item.defaultUnit),
      trailing: IconButton(
        tooltip: 'تفاصيل',
        onPressed: widget.onDetails,
        icon: const Icon(Icons.tune),
      ),
      onTap: _isAdding ? null : _add,
    );
  }

  Future<void> _add() async {
    setState(() => _isAdding = true);
    try {
      await widget.onQuickAdd();
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }
}

List<_CategoryItemGroup> _groupItemsByCategory(
  List<GroceryItem> items,
  List<Category> categories,
) {
  final categoryById = {
    for (final category in categories) category.categoryId: category,
  };
  final grouped = <String, List<GroceryItem>>{};
  for (final item in items) {
    final key = item.categoryId.isEmpty ? '_uncategorized' : item.categoryId;
    grouped.putIfAbsent(key, () => <GroceryItem>[]).add(item);
  }

  final groups = grouped.entries.map((entry) {
    final category = categoryById[entry.key];
    final title = category?.nameAr.isNotEmpty == true
        ? category!.nameAr
        : entry.key == '_uncategorized'
        ? '\u0628\u062f\u0648\u0646 \u0642\u0633\u0645'
        : entry.key;
    entry.value.sort((a, b) => a.nameAr.compareTo(b.nameAr));
    return _CategoryItemGroup(title: title, items: entry.value);
  }).toList();
  groups.sort((a, b) => a.title.compareTo(b.title));
  return groups;
}

class _CategoryItemGroup {
  const _CategoryItemGroup({required this.title, required this.items});

  final String title;
  final List<GroceryItem> items;
}

class _RequestEditorMessage extends StatelessWidget {
  const _RequestEditorMessage({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class EditRequestPage extends StatelessWidget {
  const EditRequestPage({
    super.key,
    required this.request,
    required this.currentUser,
  });

  final ShoppingRequest request;
  final AppUser currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('\u062a\u0639\u062f\u064a\u0644 \u0637\u0644\u0628'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: () => _showEditSheet(context),
              icon: const Icon(Icons.edit),
              label: const Text('\u062a\u0639\u062f\u064a\u0644'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _delete(context),
              icon: const Icon(Icons.delete),
              label: const Text('\u062d\u0630\u0641'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    await RequestService().deleteRequest(
      request: request,
      deletedBy: currentUser,
    );
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _showEditSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_RequestFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _RequestFormSheet(request: request),
    );
    if (result == null || !context.mounted) return;
    await RequestService().updateRequest(
      request: request,
      updatedBy: currentUser,
      quantity: result.quantity,
      unit: result.unit,
      priority: result.priority,
      note: result.note,
      imageBytes: result.imageBytes,
      imageContentType: result.imageContentType,
    );
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}

class _RequestFormSheet extends StatefulWidget {
  const _RequestFormSheet({this.item, this.request});

  final GroceryItem? item;
  final ShoppingRequest? request;

  @override
  State<_RequestFormSheet> createState() => _RequestFormSheetState();
}

class _RequestFormSheetState extends State<_RequestFormSheet> {
  late final TextEditingController _quantity;
  late final TextEditingController _unit;
  late final TextEditingController _note;
  late RequestPriority _priority;
  Uint8List? _imageBytes;
  String? _imageContentType;
  var _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(
      text: widget.request == null
          ? '1'
          : _formatQuantity(widget.request!.quantity),
    );
    _unit = TextEditingController(
      text: widget.request?.unit ?? widget.item?.defaultUnit ?? '',
    );
    _note = TextEditingController(text: widget.request?.note ?? '');
    _priority = widget.request?.priority ?? RequestPriority.normal;
  }

  @override
  void dispose() {
    _quantity.dispose();
    _unit.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.request?.itemName ?? widget.item?.nameAr ?? '';
    final existingImageUrl = widget.request?.imageUrl;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _quantity,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '\u0627\u0644\u0643\u0645\u064a\u0629',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _unit,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '\u0627\u0644\u0648\u062d\u062f\u0629',
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<RequestPriority>(
                segments: const [
                  ButtonSegment(
                    value: RequestPriority.normal,
                    label: Text('\u0639\u0627\u062f\u064a'),
                  ),
                  ButtonSegment(
                    value: RequestPriority.medium,
                    label: Text('\u0645\u062a\u0648\u0633\u0637'),
                  ),
                  ButtonSegment(
                    value: RequestPriority.important,
                    label: Text('\u0645\u0647\u0645'),
                  ),
                ],
                selected: {_priority},
                onSelectionChanged: (values) =>
                    setState(() => _priority = values.first),
              ),
              const SizedBox(height: 12),
              if (_imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _imageBytes!,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                )
              else if (existingImageUrl != null && existingImageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    existingImageUrl,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isPickingImage ? null : _pickImage,
                icon: _isPickingImage
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image),
                label: Text(
                  _imageBytes == null
                      ? '\u0625\u0636\u0627\u0641\u0629 \u0635\u0648\u0631\u0629'
                      : '\u062a\u063a\u064a\u064a\u0631 \u0627\u0644\u0635\u0648\u0631\u0629',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText:
                      '\u0645\u0644\u0627\u062d\u0638\u0629 \u0627\u062e\u062a\u064a\u0627\u0631\u064a\u0629',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('\u062d\u0641\u0638'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageContentType = image.mimeType ?? _contentTypeFromName(image.name);
      });
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  String _contentTypeFromName(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _submit() {
    final quantity = double.tryParse(_quantity.text.trim());
    if (quantity == null || quantity <= 0 || _unit.text.trim().isEmpty) return;
    Navigator.of(context).pop(
      _RequestFormResult(
        quantity: quantity,
        unit: _unit.text.trim(),
        priority: _priority,
        note: _note.text,
        imageBytes: _imageBytes,
        imageContentType: _imageContentType,
      ),
    );
  }
}

class _RequestFormResult {
  const _RequestFormResult({
    required this.quantity,
    required this.unit,
    required this.priority,
    this.note,
    this.imageBytes,
    this.imageContentType,
  });

  final double quantity;
  final String unit;
  final RequestPriority priority;
  final String? note;
  final Uint8List? imageBytes;
  final String? imageContentType;
}

String _formatQuantity(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

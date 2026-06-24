import 'package:flutter/material.dart';

import '../../core/models/app_user.dart';
import '../../core/models/category.dart';
import '../../core/models/grocery_item.dart';
import '../../core/models/model_enums.dart';
import '../../core/models/unit_option.dart';
import '../../core/services/admin_data_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/request_service.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.currentUser});

  final AppUser currentUser;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('\u0627\u0644\u0625\u062f\u0627\u0631\u0629'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(
                icon: Icon(Icons.people),
                text:
                    '\u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645\u0648\u0646',
              ),
              Tab(
                icon: Icon(Icons.category),
                text: '\u0627\u0644\u0623\u0642\u0633\u0627\u0645',
              ),
              Tab(
                icon: Icon(Icons.scale),
                text: '\u0627\u0644\u0648\u062d\u062f\u0627\u062a',
              ),
              Tab(
                icon: Icon(Icons.inventory_2),
                text: '\u0627\u0644\u0623\u0635\u0646\u0627\u0641',
              ),
              Tab(
                icon: Icon(Icons.message),
                text: '\u0627\u0644\u0631\u0633\u0627\u0626\u0644',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _UsersTab(currentUser: currentUser),
            const _CategoriesTab(),
            const _UnitsTab(),
            const _ItemsTab(),
            _AdminMessageTab(currentUser: currentUser),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab({required this.currentUser});

  final AppUser currentUser;

  @override
  Widget build(BuildContext context) {
    final service = AdminDataService();
    return StreamBuilder<List<AppUser>>(
      stream: service.watchUsers(),
      builder: (context, snapshot) {
        final users = snapshot.data ?? const <AppUser>[];
        return _AdminListShell(
          isLoading: snapshot.connectionState == ConnectionState.waiting,
          emptyText:
              '\u0644\u0627 \u064a\u0648\u062c\u062f \u0645\u0633\u062a\u062e\u062f\u0645\u0648\u0646.',
          action: FilledButton.icon(
            onPressed: () => _showUserDialog(context),
            icon: const Icon(Icons.person_add),
            label: const Text(
              '\u0625\u0636\u0627\u0641\u0629 \u0645\u0633\u062a\u062e\u062f\u0645',
            ),
          ),
          children: [
            for (final user in users)
              ListTile(
                leading: CircleAvatar(
                  child: Text(
                    user.displayName.isEmpty
                        ? '?'
                        : user.displayName.characters.first,
                  ),
                ),
                title: Text(
                  user.displayName.isEmpty ? user.username : user.displayName,
                ),
                subtitle: Text('@${user.username} - ${user.roleLabel}'),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      tooltip: user.isAdmin
                          ? '\u062c\u0639\u0644\u0647 \u0645\u0633\u062a\u062e\u062f\u0645'
                          : '\u062c\u0639\u0644\u0647 \u0645\u062f\u064a\u0631',
                      onPressed: () => service.setUserRole(
                        user,
                        user.isAdmin ? UserRole.regular : UserRole.admin,
                      ),
                      icon: Icon(
                        user.isAdmin
                            ? Icons.admin_panel_settings
                            : Icons.person,
                      ),
                    ),
                    Switch(
                      value: user.isActive,
                      onChanged: (value) => service.setUserStatus(
                        user,
                        value ? UserStatus.active : UserStatus.disabled,
                      ),
                    ),
                    if (user.userId != currentUser.userId)
                      IconButton(
                        tooltip: '\u062d\u0630\u0641 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645',
                        onPressed: () => _deleteUser(context, user),
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(BuildContext context, AppUser user) async {
    final displayName = user.displayName.isEmpty
        ? '@${user.username}'
        : user.displayName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('\u062d\u0630\u0641 \u0645\u0633\u062a\u062e\u062f\u0645'),
        content: Text(
          '\u0647\u0644 \u062a\u0631\u064a\u062f \u062d\u0630\u0641 $displayName\u061f',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('\u0625\u0644\u063a\u0627\u0621'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('\u062d\u0630\u0641'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await AdminDataService().deleteUser(user);
      messenger.showSnackBar(
        SnackBar(
          content: Text('\u062a\u0645 \u062d\u0630\u0641 $displayName.'),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            '\u062a\u0639\u0630\u0631 \u062d\u0630\u0641 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645. \u062d\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062e\u0631\u0649.',
          ),
        ),
      );
    }
  }

  Future<void> _showUserDialog(BuildContext context) async {
    final result = await showDialog<_UserCreationData>(
      context: context,
      builder: (context) => const _UserDialog(),
    );
    if (result == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await AdminDataService().createUserAccount(
        displayName: result.displayName,
        username: result.username,
        password: result.password,
        role: result.role,
        status: result.status,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('تم إنشاء حساب ${result.username}.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر إنشاء الحساب. تأكد من اسم الدخول وكلمة المرور وحاول مرة أخرى.',
          ),
        ),
      );
    }
  }
}

class _UserCreationData {
  const _UserCreationData({
    required this.displayName,
    required this.username,
    required this.password,
    required this.role,
    required this.status,
  });

  final String displayName;
  final String username;
  final String password;
  final UserRole role;
  final UserStatus status;
}

class _UserDialog extends StatefulWidget {
  const _UserDialog();

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  var _role = UserRole.regular;
  var _status = UserStatus.active;
  String? _error;

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة مستخدم'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _displayName,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'اسم الشخص'),
            ),
            TextField(
              controller: _username,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'اسم الدخول',
                helperText: 'مثال: ahmad',
              ),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<UserRole>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'الصلاحية'),
              items: const [
                DropdownMenuItem(
                  value: UserRole.regular,
                  child: Text('مستخدم'),
                ),
                DropdownMenuItem(value: UserRole.admin, child: Text('مدير')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _role = value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _status == UserStatus.active,
              onChanged: (value) => setState(
                () => _status = value ? UserStatus.active : UserStatus.disabled,
              ),
              title: const Text('فعال'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _submit, child: const Text('إنشاء')),
      ],
    );
  }

  void _submit() {
    final username = _username.text.trim().toLowerCase();
    final password = _password.text;
    if (_displayName.text.trim().isEmpty) {
      setState(() => _error = 'اكتب اسم الشخص.');
      return;
    }
    if (username.isEmpty || username.contains('@') || username.contains(' ')) {
      setState(() => _error = 'اكتب اسم دخول بدون مسافات وبدون @.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'كلمة المرور يجب أن تكون 6 أحرف أو أكثر.');
      return;
    }

    Navigator.of(context).pop(
      _UserCreationData(
        displayName: _displayName.text.trim(),
        username: username,
        password: password,
        role: _role,
        status: _status,
      ),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context) {
    final service = AdminDataService();
    return StreamBuilder<List<Category>>(
      stream: service.watchCategories(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? const <Category>[];
        return _AdminListShell(
          isLoading: snapshot.connectionState == ConnectionState.waiting,
          emptyText:
              '\u0644\u0627 \u062a\u0648\u062c\u062f \u0623\u0642\u0633\u0627\u0645.',
          action: FilledButton.icon(
            onPressed: () => _showCategoryDialog(context, null),
            icon: const Icon(Icons.add),
            label: const Text('\u0642\u0633\u0645 \u062c\u062f\u064a\u062f'),
          ),
          children: [
            for (final category in categories)
              ListTile(
                leading: Icon(category.isActive ? Icons.category : Icons.block),
                title: Text(category.nameAr),
                subtitle: Text(category.nameEn),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showCategoryDialog(context, category),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context,
    Category? category,
  ) async {
    final result = await showDialog<Category>(
      context: context,
      builder: (context) => _CategoryDialog(category: category),
    );
    if (result != null) await AdminDataService().saveCategory(result);
  }
}

class _UnitsTab extends StatelessWidget {
  const _UnitsTab();

  @override
  Widget build(BuildContext context) {
    final service = AdminDataService();
    return StreamBuilder<List<UnitOption>>(
      stream: service.watchUnits(),
      builder: (context, snapshot) {
        final units = snapshot.data ?? const <UnitOption>[];
        return _AdminListShell(
          isLoading: snapshot.connectionState == ConnectionState.waiting,
          emptyText:
              '\u0644\u0627 \u062a\u0648\u062c\u062f \u0648\u062d\u062f\u0627\u062a.',
          action: FilledButton.icon(
            onPressed: () => _showUnitDialog(context, null),
            icon: const Icon(Icons.add),
            label: const Text(
              '\u0648\u062d\u062f\u0629 \u062c\u062f\u064a\u062f\u0629',
            ),
          ),
          children: [
            for (final unit in units)
              ListTile(
                leading: Icon(unit.isActive ? Icons.scale : Icons.block),
                title: Text(unit.nameAr),
                subtitle: Text(unit.nameEn),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showUnitDialog(context, unit),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showUnitDialog(BuildContext context, UnitOption? unit) async {
    final result = await showDialog<UnitOption>(
      context: context,
      builder: (context) => _UnitDialog(unit: unit),
    );
    if (result != null) await AdminDataService().saveUnit(result);
  }
}

class _ItemsTab extends StatelessWidget {
  const _ItemsTab();

  @override
  Widget build(BuildContext context) {
    final service = AdminDataService();
    return StreamBuilder<List<GroceryItem>>(
      stream: service.watchItems(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <GroceryItem>[];
        return _AdminListShell(
          isLoading: snapshot.connectionState == ConnectionState.waiting,
          emptyText:
              '\u0644\u0627 \u062a\u0648\u062c\u062f \u0623\u0635\u0646\u0627\u0641.',
          action: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StreamBuilder<List<Category>>(
                stream: service.watchCategories(),
                builder: (context, categoriesSnapshot) {
                  return FilledButton.icon(
                    onPressed: () => _showItemDialog(
                      context,
                      null,
                      categoriesSnapshot.data ?? const <Category>[],
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      '\u0635\u0646\u0641 \u062c\u062f\u064a\u062f',
                    ),
                  );
                },
              ),
              OutlinedButton.icon(
                onPressed: () => _replaceCatalog(context),
                icon: const Icon(Icons.sync),
                label: const Text('استبدال بالقائمة الجديدة'),
              ),
            ],
          ),
          children: [
            for (final item in items)
              ListTile(
                leading: Icon(item.isActive ? Icons.inventory_2 : Icons.block),
                title: Text(item.nameAr),
                subtitle: Text(item.defaultUnit),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      icon: Icon(
                        item.isFavorite ? Icons.star : Icons.star_border,
                      ),
                      onPressed: () =>
                          service.setItemFavorite(item, !item.isFavorite),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final categories = await service
                            .watchCategories()
                            .first;
                        if (context.mounted) {
                          await _showItemDialog(context, item, categories);
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showItemDialog(
    BuildContext context,
    GroceryItem? item,
    List<Category> categories,
  ) async {
    final result = await showDialog<GroceryItem>(
      context: context,
      builder: (context) => _ItemDialog(item: item, categories: categories),
    );
    if (result != null) await AdminDataService().saveItem(result);
  }

  Future<void> _replaceCatalog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استبدال الأصناف'),
        content: const Text(
          'سيتم مسح الأقسام والأصناف والوحدات الحالية واستبدالها بالقائمة الجديدة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('استبدال'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await RequestService().seedDefaultCatalog();
      messenger.showSnackBar(
        const SnackBar(content: Text('تم استبدال الأصناف بالقائمة الجديدة.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('تعذر استبدال الأصناف. حاول مرة أخرى.')),
      );
    }
  }
}

class _AdminListShell extends StatelessWidget {
  const _AdminListShell({
    required this.isLoading,
    required this.emptyText,
    required this.action,
    required this.children,
  });

  final bool isLoading;
  final String emptyText;
  final Widget action;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(alignment: Alignment.centerRight, child: action),
        const SizedBox(height: 12),
        if (children.isEmpty)
          Center(child: Text(emptyText))
        else
          for (final child in children) ...[
            Card(child: child),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.category});

  final Category? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameAr;
  late final TextEditingController _nameEn;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameAr = TextEditingController(text: widget.category?.nameAr ?? '');
    _nameEn = TextEditingController(text: widget.category?.nameEn ?? '');
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameAr.dispose();
    _nameEn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _NamedDialog(
      title: '\u0642\u0633\u0645',
      nameAr: _nameAr,
      nameEn: _nameEn,
      isActive: _isActive,
      onActiveChanged: (value) => setState(() => _isActive = value),
      onSave: () {
        Navigator.of(context).pop(
          Category(
            categoryId: widget.category?.categoryId ?? '',
            nameAr: _nameAr.text.trim(),
            nameEn: _nameEn.text.trim(),
            sortOrder:
                widget.category?.sortOrder ??
                DateTime.now().millisecondsSinceEpoch,
            isActive: _isActive,
          ),
        );
      },
    );
  }
}

class _UnitDialog extends StatefulWidget {
  const _UnitDialog({this.unit});

  final UnitOption? unit;

  @override
  State<_UnitDialog> createState() => _UnitDialogState();
}

class _UnitDialogState extends State<_UnitDialog> {
  late final TextEditingController _nameAr;
  late final TextEditingController _nameEn;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameAr = TextEditingController(text: widget.unit?.nameAr ?? '');
    _nameEn = TextEditingController(text: widget.unit?.nameEn ?? '');
    _isActive = widget.unit?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameAr.dispose();
    _nameEn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _NamedDialog(
      title: '\u0648\u062d\u062f\u0629',
      nameAr: _nameAr,
      nameEn: _nameEn,
      isActive: _isActive,
      onActiveChanged: (value) => setState(() => _isActive = value),
      onSave: () {
        Navigator.of(context).pop(
          UnitOption(
            unitId: widget.unit?.unitId ?? '',
            nameAr: _nameAr.text.trim(),
            nameEn: _nameEn.text.trim(),
            sortOrder:
                widget.unit?.sortOrder ?? DateTime.now().millisecondsSinceEpoch,
            isActive: _isActive,
          ),
        );
      },
    );
  }
}

class _NamedDialog extends StatelessWidget {
  const _NamedDialog({
    required this.title,
    required this.nameAr,
    required this.nameEn,
    required this.isActive,
    required this.onActiveChanged,
    required this.onSave,
  });

  final String title;
  final TextEditingController nameAr;
  final TextEditingController nameEn;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameAr,
            decoration: const InputDecoration(
              labelText:
                  '\u0627\u0644\u0627\u0633\u0645 \u0628\u0627\u0644\u0639\u0631\u0628\u064a\u0629',
            ),
          ),
          TextField(
            controller: nameEn,
            decoration: const InputDecoration(
              labelText:
                  '\u0627\u0644\u0627\u0633\u0645 \u0628\u0627\u0644\u0625\u0646\u062c\u0644\u064a\u0632\u064a\u0629',
            ),
          ),
          SwitchListTile(
            value: isActive,
            onChanged: onActiveChanged,
            title: const Text('\u0641\u0639\u0627\u0644'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('\u0625\u0644\u063a\u0627\u0621'),
        ),
        FilledButton(
          onPressed: onSave,
          child: const Text('\u062d\u0641\u0638'),
        ),
      ],
    );
  }
}

class _ItemDialog extends StatefulWidget {
  const _ItemDialog({this.item, required this.categories});

  final GroceryItem? item;
  final List<Category> categories;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  late final TextEditingController _nameAr;
  late final TextEditingController _nameEn;
  late String? _categoryId;
  late final TextEditingController _defaultUnit;
  late bool _isFavorite;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameAr = TextEditingController(text: widget.item?.nameAr ?? '');
    _nameEn = TextEditingController(text: widget.item?.nameEn ?? '');
    final activeCategories = widget.categories
        .where((category) => category.isActive)
        .toList();
    _categoryId = widget.item?.categoryId.isNotEmpty == true
        ? widget.item!.categoryId
        : activeCategories.isNotEmpty
        ? activeCategories.first.categoryId
        : null;
    _defaultUnit = TextEditingController(text: widget.item?.defaultUnit ?? '');
    _isFavorite = widget.item?.isFavorite ?? false;
    _isActive = widget.item?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameAr.dispose();
    _nameEn.dispose();
    _defaultUnit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('\u0635\u0646\u0641'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameAr,
              decoration: const InputDecoration(
                labelText:
                    '\u0627\u0644\u0627\u0633\u0645 \u0628\u0627\u0644\u0639\u0631\u0628\u064a\u0629',
              ),
            ),
            TextField(
              controller: _nameEn,
              decoration: const InputDecoration(
                labelText:
                    '\u0627\u0644\u0627\u0633\u0645 \u0628\u0627\u0644\u0625\u0646\u062c\u0644\u064a\u0632\u064a\u0629',
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(
                labelText: '\u0627\u0644\u0642\u0633\u0645',
              ),
              items: [
                for (final category in widget.categories.where(
                  (category) => category.isActive,
                ))
                  DropdownMenuItem(
                    value: category.categoryId,
                    child: Text(category.nameAr),
                  ),
              ],
              onChanged: (value) => setState(() => _categoryId = value),
            ),
            TextField(
              controller: _defaultUnit,
              decoration: const InputDecoration(
                labelText: '\u0627\u0644\u0648\u062d\u062f\u0629',
              ),
            ),
            SwitchListTile(
              value: _isFavorite,
              onChanged: (value) => setState(() => _isFavorite = value),
              title: const Text('\u0645\u0641\u0636\u0644'),
            ),
            SwitchListTile(
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              title: const Text('\u0641\u0639\u0627\u0644'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('\u0625\u0644\u063a\u0627\u0621'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameAr.text.trim().isEmpty ||
                _defaultUnit.text.trim().isEmpty ||
                _categoryId == null) {
              return;
            }
            Navigator.of(context).pop(
              GroceryItem(
                itemId: widget.item?.itemId ?? '',
                nameAr: _nameAr.text.trim(),
                nameEn: _nameEn.text.trim(),
                categoryId: _categoryId ?? '',
                defaultUnit: _defaultUnit.text.trim(),
                isFavorite: _isFavorite,
                isActive: _isActive,
                defaultImageUrl: widget.item?.defaultImageUrl,
              ),
            );
          },
          child: const Text('\u062d\u0641\u0638'),
        ),
      ],
    );
  }
}

class _AdminMessageTab extends StatefulWidget {
  const _AdminMessageTab({required this.currentUser});

  final AppUser currentUser;

  @override
  State<_AdminMessageTab> createState() => _AdminMessageTabState();
}

class _AdminMessageTabState extends State<_AdminMessageTab> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  var _isSending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _title,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText:
                '\u0639\u0646\u0648\u0627\u0646 \u0627\u0644\u0631\u0633\u0627\u0644\u0629',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _body,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText:
                '\u0646\u0635 \u0627\u0644\u0631\u0633\u0627\u0644\u0629',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isSending ? null : _send,
          icon: _isSending
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: const Text('\u0625\u0631\u0633\u0627\u0644'),
        ),
      ],
    );
  }

  Future<void> _send() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty || body.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await NotificationService().sendAdminMessage(
        admin: widget.currentUser,
        title: title,
        body: body,
      );
      _title.clear();
      _body.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u062a\u0645 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0631\u0633\u0627\u0644\u0629.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}

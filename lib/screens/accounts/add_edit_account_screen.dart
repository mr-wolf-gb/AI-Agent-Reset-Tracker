import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/color_constants.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/account_provider.dart';
import '../../providers/ai_ide_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/notification_service.dart';
import '../../models/account.dart';
import '../../models/ai_ide.dart';
import '../../widgets/ide_icon.dart';

class AddEditAccountScreen extends ConsumerStatefulWidget {
  final String ideId;
  final String? accountId;

  const AddEditAccountScreen({
    super.key,
    required this.ideId,
    this.accountId,
  });

  @override
  ConsumerState<AddEditAccountScreen> createState() =>
      _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends ConsumerState<AddEditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _notesCtrl;
  DateTime? _resetTime;
  bool _isActive = true;
  bool _notificationEnabled = true;
  bool _showPassword = false;
  bool _isSaving = false;
  Account? _editingAccount;

  bool get _isEditing => widget.accountId != null;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAccount());
    }
  }

  Future<void> _loadAccount() async {
    final account =
        ref.read(accountProvider.notifier).getById(widget.accountId!);
    if (account == null) return;
    _editingAccount = account;
    final pw = await ref
        .read(accountProvider.notifier)
        .getPassword(account.id);
    if (!mounted) return;
    setState(() {
      _emailCtrl.text = account.email;
      _passwordCtrl.text = pw ?? '';
      _notesCtrl.text = account.notes;
      _resetTime = account.resetTime;
      _isActive = account.isActive;
      _notificationEnabled = account.notificationEnabled;
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final notifier = ref.read(accountProvider.notifier);

      if (_isEditing && _editingAccount != null) {
        final updated = _editingAccount!.copyWith(
          email: _emailCtrl.text.trim(),
          resetTime: _resetTime,
          isActive: _isActive,
          notificationEnabled: _notificationEnabled,
          notes: _notesCtrl.text.trim(),
          updatedAt: now,
          clearResetTime: _resetTime == null,
        );
        await notifier.updateAccount(updated, newPassword: _passwordCtrl.text);
        await _updateNotification(updated);
      } else {
        final id = const Uuid().v4();
        final account = Account(
          id: id,
          aiIdeId: widget.ideId,
          email: _emailCtrl.text.trim(),
          resetTime: _resetTime,
          isActive: _isActive,
          notificationEnabled: _notificationEnabled,
          notes: _notesCtrl.text.trim(),
          createdAt: now,
          updatedAt: now,
        );
        await notifier.addAccount(account, _passwordCtrl.text);
        await _updateNotification(account);
      }
      if (!mounted) return;
      context.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateNotification(Account account) async {
    final ide = ref.read(aiIdeProvider.notifier).getById(widget.ideId);
    final settings = ref.read(settingsProvider);
    if (ide == null) return;
    await NotificationService.instance.cancelNotification(account.id);
    if (account.notificationEnabled &&
        account.resetTime != null &&
        settings.notificationsEnabled) {
      await NotificationService.instance.scheduleResetNotification(
        account: account,
        ide: ide,
        advanceMinutes: settings.notificationAdvanceMinutes,
      );
    }
  }

  Future<void> _pickResetTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _resetTime ?? now.add(const Duration(days: 30)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_resetTime ?? now),
    );
    if (time == null || !mounted) return;

    setState(() {
      _resetTime = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ide = ref.watch(aiIdeProvider.notifier).getById(widget.ideId) ??
        AiIde.unknown(widget.ideId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IdeIcon(ide: ide, size: 24),
            const SizedBox(width: 8),
            Text(_isEditing ? 'Edit Account' : 'Add Account'),
          ],
        ),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // IDE header card
              _SectionCard(
                isDark: isDark,
                child: Row(
                  children: [
                    IdeIcon(ide: ide, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ide.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          Text(ide.typeLabel,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const _FieldLabel('Email Address'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: 16),

              const _FieldLabel('Password'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: !_showPassword,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: _isEditing
                      ? 'Leave blank to keep current'
                      : 'Enter password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
                validator: (v) {
                  if (!_isEditing && (v == null || v.isEmpty)) {
                    return 'Password is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const _FieldLabel('Reset Time (Optional)'),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickResetTime,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _resetTime != null
                              ? DateFormatter.formatDateTime(_resetTime!)
                              : 'Tap to set reset time',
                          style: TextStyle(
                            color: _resetTime != null
                                ? null
                                : AppColors.textTertiary,
                          ),
                        ),
                      ),
                      if (_resetTime != null)
                        GestureDetector(
                          onTap: () => setState(() => _resetTime = null),
                          child: const Icon(Icons.clear, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _SectionCard(
                isDark: isDark,
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active Account'),
                      subtitle: const Text('Uncheck if no longer in use'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reset Notifications'),
                      subtitle: const Text('Alert before account resets'),
                      value: _notificationEnabled,
                      onChanged: (v) =>
                          setState(() => _notificationEnabled = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const _FieldLabel('Notes (Optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Any additional notes...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.notes),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Add Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _SectionCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: child,
    );
  }
}

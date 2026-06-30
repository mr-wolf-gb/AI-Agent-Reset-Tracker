import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/validators.dart';
import '../../providers/ai_ide_provider.dart';
import '../../models/ai_ide.dart';
import '../../widgets/ide_icon.dart';

class AddCustomIdeScreen extends ConsumerStatefulWidget {
  const AddCustomIdeScreen({super.key});

  @override
  ConsumerState<AddCustomIdeScreen> createState() =>
      _AddCustomIdeScreenState();
}

class _AddCustomIdeScreenState extends ConsumerState<AddCustomIdeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _iconUrlCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _resetPeriodCtrl = TextEditingController();
  final _presetsCtrl = TextEditingController();


  String _type = 'web-app';
  bool _isSaving = false;

  static const _types = [
    'desktop-ide',
    'web-app',
    'web-ide',
    'plugin',
    'cli',
    'api'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _websiteCtrl.dispose();
    _iconUrlCtrl.dispose();
    _descCtrl.dispose();
    _resetPeriodCtrl.dispose();
    _presetsCtrl.dispose();


    super.dispose();
  }

  String _typeLabel(String t) {
    return t
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final presets = _presetsCtrl.text
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .where((e) => e != null)
          .cast<int>()
          .toList();

      final ide = AiIde(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        website: _websiteCtrl.text.trim(),
        iconUrl: _iconUrlCtrl.text.trim(),
        type: _type,
        isCustom: true,
        isRemoved: false,
        updatedAt: DateTime.now(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        resetPeriodHours: int.tryParse(_resetPeriodCtrl.text.trim()),
        resetPresets: presets.isEmpty ? null : presets,
      );
      await ref.read(aiIdeProvider.notifier).addCustomIde(ide);
      if (!mounted) return;
      context.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewIde = AiIde(
      id: 'preview',
      name: _nameCtrl.text.isEmpty ? 'Preview' : _nameCtrl.text,
      website: _websiteCtrl.text,
      iconUrl: _iconUrlCtrl.text,
      type: _type,
      updatedAt: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Custom AI Tool'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Live preview
              Center(
                child: Column(
                  children: [
                    IdeIcon(ide: previewIde, size: 64),
                    const SizedBox(height: 8),
                    Text(
                      previewIde.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    Text(previewIde.typeLabel,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) => Validators.required(v, 'Name'),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _websiteCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Website URL',
                  prefixIcon: Icon(Icons.language),
                  hintText: 'https://...',
                ),
                validator: Validators.url,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _iconUrlCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Icon URL',
                  prefixIcon: Icon(Icons.image_outlined),
                  hintText: 'https://site.com/favicon.ico',
                ),
                onChanged: (_) => setState(() {}),
                validator: Validators.url,
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _types
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_typeLabel(t)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Icon(Icons.notes),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _resetPeriodCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reset Period (Hours)',
                  prefixIcon: Icon(Icons.timer_outlined),
                  hintText: 'e.g. 24',
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                    return 'Must be a number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _presetsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reset Presets (Hours, comma separated)',
                  prefixIcon: Icon(Icons.list_alt_outlined),
                  hintText: 'e.g. 3, 24, 168',
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    final parts = v.split(',');
                    for (final p in parts) {
                      if (p.trim().isNotEmpty && int.tryParse(p.trim()) == null) {
                        return 'All values must be numbers';
                      }
                    }
                  }
                  return null;
                },
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
                    : const Text('Add AI Tool'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

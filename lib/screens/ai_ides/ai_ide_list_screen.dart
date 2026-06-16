import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/ai_ide_provider.dart';
import '../../models/ai_ide.dart';
import '../../core/constants/color_constants.dart';
import '../../widgets/ide_icon.dart';
import '../../widgets/empty_state.dart';

class AiIdeListScreen extends ConsumerStatefulWidget {
  const AiIdeListScreen({super.key});

  @override
  ConsumerState<AiIdeListScreen> createState() => _AiIdeListScreenState();
}

class _AiIdeListScreenState extends ConsumerState<AiIdeListScreen> {
  String _search = '';
  String _filter = 'All';

  static const _filters = [
    'All',
    'desktop-ide',
    'web-app',
    'web-ide',
    'plugin',
    'cli',
    'custom'
  ];

  @override
  Widget build(BuildContext context) {
    final allIdes = ref.watch(aiIdeProvider);
    final filtered = allIdes.where((ide) {
      if (_filter == 'custom' && !ide.isCustom) return false;
      if (_filter != 'All' && _filter != 'custom' && ide.type != _filter) {
        return false;
      }
      if (_search.isNotEmpty &&
          !ide.name.toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tools'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search AI tools...',
                    prefixIcon: const Icon(Icons.search),
                    fillColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.cardDark
                            : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final f = _filters[i];
                    final selected = f == _filter;
                    return ChoiceChip(
                      label: Text(_filterLabel(f)),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: AppColors.accent,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : null,
                        fontWeight:
                            selected ? FontWeight.w600 : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: filtered.isEmpty
          ? const EmptyState(
              icon: Icons.apps_outlined,
              title: 'No Results',
              subtitle: 'Try a different search or filter.',
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1),
              itemBuilder: (ctx, i) =>
                  _IdeListTile(ide: filtered[i]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/ides/add'),
        tooltip: 'Add Custom AI Tool',
        child: const Icon(Icons.add),
      ),
    );
  }

  String _filterLabel(String f) {
    switch (f) {
      case 'desktop-ide':
        return 'IDE';
      case 'web-app':
        return 'Web App';
      case 'web-ide':
        return 'Web IDE';
      case 'plugin':
        return 'Plugin';
      case 'cli':
        return 'CLI';
      case 'custom':
        return 'Custom';
      default:
        return f;
    }
  }
}

class _IdeListTile extends StatelessWidget {
  final AiIde ide;
  const _IdeListTile({required this.ide});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      leading: IdeIcon(ide: ide, size: 44),
      title: Row(
        children: [
          Flexible(
            child: Text(ide.name,
                style:
                    const TextStyle(fontWeight: FontWeight.w700)),
          ),
          if (ide.isCustom) ...[
            const SizedBox(width: 6),
            _Pill(label: 'Custom', color: AppColors.accent),
          ],
          if (ide.isRemoved) ...[
            const SizedBox(width: 6),
            _Pill(label: 'Removed', color: AppColors.inactive),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: ide.typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ide.typeLabel,
              style: TextStyle(
                  fontSize: 11,
                  color: ide.typeColor,
                  fontWeight: FontWeight.w600),
            ),
          ),
          if (ide.description != null &&
              ide.description!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ide.description!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textTertiary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      trailing: ide.website.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.open_in_new,
                  size: 18, color: AppColors.accent),
              onPressed: () async {
                final uri = Uri.tryParse(ide.website);
                if (uri != null) await launchUrl(uri);
              },
              tooltip: 'Open website',
            )
          : null,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

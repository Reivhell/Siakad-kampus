import 'package:flutter/material.dart';

/// Baris filter M3: search + dropdown + refresh. Wrap otomatis di mobile.
class FilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchHint;
  final List<FilterOption> filters;
  final VoidCallback? onRefresh;
  final ValueChanged<String>? onSearchChanged;

  const FilterBar({
    super.key,
    required this.searchController,
    required this.searchHint,
    this.filters = const [],
    this.onRefresh,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: SearchBar(
            controller: searchController,
            hintText: searchHint,
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll(0),
            onChanged: onSearchChanged,
            trailing: [
              if (searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    searchController.clear();
                    onSearchChanged?.call('');
                  },
                ),
            ],
          ),
        ),
        for (final f in filters)
          DropdownMenu<String>(
            initialSelection: f.value,
            label: Text(f.label),
            dropdownMenuEntries: [
              for (final o in f.options)
                DropdownMenuEntry(value: o, label: o),
            ],
            onSelected: (v) => f.onSelected(v ?? f.value),
          ),
        if (onRefresh != null)
          IconButton.filledTonal(
            tooltip: 'Segarkan',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_outlined),
          ),
      ],
    );
  }
}

class FilterOption {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  const FilterOption({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });
}

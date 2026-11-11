import 'dart:async';

import 'package:flutter/material.dart';

/// Baris filter M3: search + dropdown + refresh. Wrap otomatis di mobile.
///
/// Pencarian di-debounce 300ms: ketikan N tombol → 1 rebuild saat jeda.
/// Tombol clear tetap instan. Zero-debounce (`debounceMs: 0`) untuk tes.
class FilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final String searchHint;
  final List<FilterOption> filters;
  final VoidCallback? onRefresh;
  final ValueChanged<String>? onSearchChanged;
  final int debounceMs;

  const FilterBar({
    super.key,
    required this.searchController,
    required this.searchHint,
    this.filters = const [],
    this.onRefresh,
    this.onSearchChanged,
    this.debounceMs = 300,
  });

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    final cb = widget.onSearchChanged;
    if (cb == null) return;
    if (widget.debounceMs <= 0) {
      cb(v);
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: widget.debounceMs), () {
      if (mounted) cb(v);
    });
  }

  void _onClear() {
    _debounce?.cancel();
    widget.searchController.clear();
    widget.onSearchChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 500;
        final searchWidth = narrow
            ? constraints.maxWidth
            : (constraints.maxWidth * 0.42).clamp(200.0, 360.0);
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: searchWidth,
              child: SearchBar(
                controller: widget.searchController,
                hintText: widget.searchHint,
                leading: const Icon(Icons.search),
                elevation: const WidgetStatePropertyAll(0),
                onChanged: _onChanged,
                trailing: [
                  if (widget.searchController.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Bersihkan pencarian',
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: _onClear,
                    ),
                ],
              ),
            ),
            for (final f in widget.filters)
              DropdownMenu<String>(
                initialSelection: f.value,
                label: Text(f.label),
                dropdownMenuEntries: [
                  for (final o in f.options)
                    DropdownMenuEntry(value: o, label: o),
                ],
                onSelected: (v) => f.onSelected(v ?? f.value),
              ),
            if (widget.onRefresh != null)
              IconButton.filledTonal(
                tooltip: 'Segarkan',
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh_outlined),
              ),
          ],
        );
      },
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

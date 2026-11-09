import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Lapisan adaptif Cupertino — dipakai selektif, bukan migrasi penuh.
///
/// Verdict: full `CupertinoApp` buruk untuk SIAKAD (design.md M3:
/// DataTable zebra, NavigationDrawer/Rail/Bar, SearchBar — tidak ada
/// padanan Cupertino padat). Yang bagus dari Cupertino hanya:
/// dialog, action sheet, switch, picker, activity indicator.
/// File ini bungkus itu dengan token SIAKAD agar rasa iOS tanpa
/// buang `SiakadTheme`.
abstract class SiakadAdaptive {
  static bool isApple(BuildContext context) {
    final p = Theme.of(context).platform;
    return p == TargetPlatform.iOS || p == TargetPlatform.macOS;
  }

  /// CupertinoTheme agar widget Cupertino ikut brand, bukan biru default.
  static Widget wrap(BuildContext context, Widget child) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CupertinoTheme(
      data: CupertinoThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        primaryColor: dark ? AppColors.darkPrimary : AppColors.indigoBlue,
        scaffoldBackgroundColor:
            dark ? AppColors.darkBg : AppColors.lightBg,
        textTheme: CupertinoTextThemeData(
          textStyle: DefaultTextStyle.of(context).style,
        ),
      ),
      child: child,
    );
  }

  /// Dialog: CupertinoAlertDialog di Apple, AlertDialog biasa lainnya.
  static Future<T?> dialog<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget> actions = const [],
  }) {
    if (isApple(context)) {
      return showCupertinoDialog<T>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(title),
          content: content,
          actions: actions.isEmpty
              ? [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ]
              : actions,
        ),
      );
    }
    return showDialog<T>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: content,
        actions: actions.isEmpty
            ? [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ]
            : actions,
      ),
    );
  }

  /// Action sheet: CupertinoActionSheet di Apple, bottom sheet M3 lainnya.
  static Future<T?> sheet<T>({
    required BuildContext context,
    required String title,
    required List<({String label, IconData? icon, bool destructive, VoidCallback? onTap})> options,
  }) {
    if (isApple(context)) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: Text(title),
          actions: [
            for (final o in options)
              CupertinoActionSheetAction(
                isDestructiveAction: o.destructive,
                onPressed: () {
                  Navigator.pop(context);
                  o.onTap?.call();
                },
                child: Text(o.label),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ),
      );
    }
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final o in options)
              ListTile(
                leading: o.icon == null ? null : Icon(o.icon),
                title: Text(
                  o.label,
                  style: o.destructive
                      ? const TextStyle(color: AppColors.destructive)
                      : null,
                ),
                onTap: () {
                  Navigator.pop(context);
                  o.onTap?.call();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Switch adaptif — CupertinoSwitch di Apple, Switch M3 lainnya.
/// Token ikut `ColorScheme.primary`, tanpa warna hardcode.
class SiakadSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SiakadSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      // ponytail: default M3/Cupertino track, tanpa override brand.
    );
  }
}

/// Loading adaptif — indicator iOS di Apple, circular M3 lainnya.
class SiakadLoading extends StatelessWidget {
  final double size;
  const SiakadLoading({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    if (SiakadAdaptive.isApple(context)) {
      return SizedBox(
        width: size,
        height: size,
        child: const CupertinoActivityIndicator(radius: 11),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator.adaptive(strokeWidth: 2.5),
    );
  }
}

/// Tombol adaptif — CupertinoButton di Apple, FilledButton M3 lainnya.
/// Warna ikut token light/dark, bukan default iOS blue.
class SiakadButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;

  const SiakadButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = secondary
        ? null
        : (dark ? AppColors.darkGold : AppColors.indigoBlue);
    final fg = secondary
        ? null
        : (dark ? AppColors.darkBg : Colors.white);
    if (SiakadAdaptive.isApple(context)) {
      return CupertinoButton(
        onPressed: onPressed,
        color: secondary ? null : bg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        borderRadius: BorderRadius.circular(12),
        minimumSize: const Size.fromHeight(50),
        child: Text(
          label,
          style: TextStyle(
            color: secondary
                ? (dark ? AppColors.darkPrimary : AppColors.indigoBlue)
                : fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    if (secondary) {
      return OutlinedButton(onPressed: onPressed, child: Text(label));
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(label),
    );
  }
}

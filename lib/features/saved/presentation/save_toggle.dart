import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/error_text.dart';
import '../../../core/ui/ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/saved_controller.dart';

/// Saves or unsaves a programme and says so. Removing offers Undo rather than
/// asking "are you sure": Undo covers the rare slip without costing every
/// citizen an extra tap.
Future<void> toggleSaved(BuildContext context, WidgetRef ref, String opportunityId) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final controller = ref.read(savedControllerProvider.notifier);
  final saved = ref.read(savedForOpportunityProvider(opportunityId));

  if (saved == null) {
    final error = await controller.save(opportunityId);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error == null ? l.savedToast : errorText(l, error))));
    return;
  }
  final result = await controller.remove(saved.id);
  messenger.hideCurrentSnackBar();
  if (result.error != null) {
    messenger.showSnackBar(SnackBar(content: Text(errorText(l, result.error!))));
  } else if (result.removed != null) {
    final removed = result.removed!;
    messenger.showSnackBar(SnackBar(
      content: Text(l.removedToast),
      action: SnackBarAction(label: l.undo, onPressed: () => controller.undoRemove(removed)),
    ));
  }
}

/// A bookmark button that shows and flips whether a programme is saved.
class SaveIconButton extends ConsumerWidget {
  const SaveIconButton({super.key, required this.opportunityId});
  final String opportunityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final saved = ref.watch(savedForOpportunityProvider(opportunityId)) != null;
    return IconButton(
      tooltip: saved ? l.unsaveProgramme : l.saveProgramme,
      isSelected: saved,
      color: saved ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
      icon: const Icon(Icons.bookmark_border_rounded),
      selectedIcon: const Icon(Icons.bookmark_rounded),
      onPressed: () => toggleSaved(context, ref, opportunityId),
    );
  }
}

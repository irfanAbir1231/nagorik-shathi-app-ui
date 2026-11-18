import 'package:flutter/material.dart';
import '../../../core/ui/ui.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Four large icon-and-label shortcuts.
class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onSpeak,
    required this.onMyList,
    required this.onPlans,
    required this.onBrowseAll,
  });

  final VoidCallback onSpeak;
  final VoidCallback onMyList;
  final VoidCallback onPlans;
  final VoidCallback onBrowseAll;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Action(icon: Icons.mic_rounded, color: const Color(0xFFE07A1F), label: l.voiceStart, onTap: onSpeak),
        _Action(icon: Icons.bookmarks_rounded, color: const Color(0xFF6B4FBB), label: l.navSaved, onTap: onMyList),
        _Action(icon: Icons.checklist_rounded, color: const Color(0xFF00838F), label: l.plansTab, onTap: onPlans),
        _Action(icon: Icons.travel_explore_rounded, color: const Color(0xFF3F6FD8), label: l.quickAll, onTap: onBrowseAll),
      ]),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.color, required this.label, required this.onTap});
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Tap(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ),
      );
}

import 'package:flutter/material.dart';

import '../../../core/ui/theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/saved.dart';

String savedStatusLabel(AppLocalizations l, SavedStatus s) => switch (s) {
      SavedStatus.interested => l.statusInterested,
      SavedStatus.preparing => l.statusPreparing,
      SavedStatus.documentsReady => l.statusDocsReady,
      SavedStatus.applied => l.statusApplied,
      SavedStatus.underReview => l.statusUnderReview,
      SavedStatus.approved => l.statusApproved,
      SavedStatus.rejected => l.statusRejected,
      SavedStatus.completed => l.statusCompleted,
    };

/// Icon and colour per status. Always shown with the label.
({IconData icon, Color color}) savedStatusVisual(SavedStatus s) => switch (s) {
      SavedStatus.interested => (icon: Icons.star_outline_rounded, color: const Color(0xFF607D8B)),
      SavedStatus.preparing => (icon: Icons.edit_note_rounded, color: const Color(0xFF3F6FD8)),
      SavedStatus.documentsReady => (icon: Icons.folder_open_rounded, color: const Color(0xFF00838F)),
      SavedStatus.applied => (icon: Icons.send_rounded, color: const Color(0xFF6B4FBB)),
      SavedStatus.underReview => (icon: Icons.hourglass_top_rounded, color: AppColors.warning),
      SavedStatus.approved => (icon: Icons.verified_rounded, color: AppColors.success),
      SavedStatus.rejected => (icon: Icons.cancel_outlined, color: AppColors.danger),
      SavedStatus.completed => (icon: Icons.emoji_events_rounded, color: AppColors.success),
    };

/// The journey, in order. "Not approved" sits outside it: it ends the journey
/// rather than being a stage of it.
const savedJourney = [
  SavedStatus.interested,
  SavedStatus.preparing,
  SavedStatus.documentsReady,
  SavedStatus.applied,
  SavedStatus.underReview,
  SavedStatus.approved,
  SavedStatus.completed,
];

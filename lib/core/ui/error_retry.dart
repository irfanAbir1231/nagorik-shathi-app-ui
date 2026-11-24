import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../i18n/error_text.dart';
import '../network/api_result.dart';
import 'components.dart';
import 'theme.dart';

/// Shared error block: a picture of what went wrong, the localised message,
/// the request id for support, and a retry button.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final err = error is ApiFailure
        ? (error as ApiFailure).err
        : const Err<dynamic>(ErrorCodes.unknown, '');
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IllustratedBadge(
              icon: err.isNetwork
                  ? Icons.wifi_off_rounded
                  : Icons.cloud_off_rounded,
              color: AppColors.warning,
              size: 72,
            ),
            const SizedBox(height: 12),
            Text(
              errorText(l, err),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (err.requestId != null) ...[
              const SizedBox(height: 4),
              Text(
                l.errReference(err.requestId!),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }
}

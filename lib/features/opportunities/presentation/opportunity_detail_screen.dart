import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/error_text.dart';
import '../../../core/ui/ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/application/home_providers.dart' show daysUntil;
import '../../plans/application/plan_controller.dart';
import '../../saved/application/saved_controller.dart';
import '../../saved/presentation/save_toggle.dart';
import '../application/opportunity_providers.dart';
import '../domain/opportunity.dart';
import 'category_visuals.dart';
import 'labels.dart';

/// One programme, ordered by what a citizen needs to decide:
/// what it is → key facts → can I get it → how → what to bring → who to ask.
class OpportunityDetailScreen extends ConsumerStatefulWidget {
  const OpportunityDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  ConsumerState<OpportunityDetailScreen> createState() => _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends ConsumerState<OpportunityDetailScreen> {
  final _scroll = ScrollController();
  var _showTitle = false;

  @override
  void initState() {
    super.initState();
    // The title moves into the app bar once the hero has scrolled away.
    _scroll.addListener(() {
      final show = _scroll.hasClients && _scroll.offset > 120;
      if (show != _showTitle) setState(() => _showTitle = show);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(opportunityDetailProvider(widget.slug));
    final detail = async.value;
    final locale = Localizations.localeOf(context);
    final accent = detail == null ? AppColors.primary : categoryVisual(detail.summary.category).color;
    final heroTop = Color.alphaBlend(accent.withValues(alpha: 0.16), Colors.white);

    return Scaffold(
      appBar: AppBar(
        foregroundColor: AppColors.ink,
        shape: const RoundedRectangleBorder(),
        scrolledUnderElevation: 1,
        // Tinted to blend into the hero, white once content scrolls under it.
        backgroundColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.scrolledUnder) ? Colors.white : heroTop,
        ),
        title: AnimatedOpacity(
          opacity: _showTitle && detail != null ? 1 : 0,
          duration: const Duration(milliseconds: 150),
          child: Text(detail?.summary.title.of(locale) ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
      bottomNavigationBar: detail == null ? null : _ActionBar(opportunityId: detail.summary.id, slug: widget.slug),
      body: async.when(
        loading: () => const _DetailSkeleton(),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(opportunityDetailProvider(widget.slug))),
        data: (d) => RefreshIndicator(
          onRefresh: () => ref.refresh(opportunityDetailProvider(widget.slug).future),
          child: _DetailBody(detail: d, controller: _scroll, heroTop: heroTop),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.controller, required this.heroTop});
  final OpportunityDetail detail;
  final ScrollController controller;
  final Color heroTop;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final s = detail.summary;
    final org = s.organization;
    final benefits = detail.benefits.of(locale);
    final description = detail.description.of(locale);
    const gutter = EdgeInsets.symmetric(horizontal: 16);
    const headerPadding = EdgeInsets.fromLTRB(20, 28, 16, 10);

    return ListView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _Hero(detail: detail, heroTop: heroTop),
        if (s.verificationStatus != 'verified')
          Padding(padding: gutter, child: _VerificationBanner(status: s.verificationStatus)),
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: _KeyFacts(detail: detail)),
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: _VerdictCard(detail: detail)),
        if (description.isNotEmpty) ...[
          SectionHeader(title: l.secDescription, icon: Icons.info_outline_rounded, padding: headerPadding),
          Padding(
            padding: gutter,
            child: Card(child: Padding(padding: const EdgeInsets.all(16), child: _ExpandableText(description))),
          ),
        ],
        if (benefits.isNotEmpty) ...[
          SectionHeader(
            title: l.secBenefits,
            icon: Icons.card_giftcard_rounded,
            iconColor: AppColors.warning,
            padding: headerPadding,
          ),
          Padding(
            padding: gutter,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sun.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(benefits, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.ink)),
            ),
          ),
        ],
        if (detail.steps.isNotEmpty) ...[
          SectionHeader(title: l.secHowToApply, icon: Icons.route_rounded, padding: headerPadding),
          Padding(
            padding: gutter,
            child: Card(
              child: Padding(padding: const EdgeInsets.all(16), child: _StepsTimeline(steps: detail.steps)),
            ),
          ),
        ],
        if (detail.documents.isNotEmpty) ...[
          SectionHeader(title: l.secDocuments, icon: Icons.folder_copy_rounded, padding: headerPadding),
          for (final d in detail.documents)
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: _DocumentCard(doc: d)),
        ],
        if (org != null) ...[
          SectionHeader(title: l.secProvider, icon: Icons.account_balance_rounded, padding: headerPadding),
          Padding(
            padding: gutter,
            child: _OfficeCard(
              office: org,
              website: org.website ?? detail.officialUrl,
              applyUrl: detail.applyUrl,
            ),
          ),
        ],
        if (detail.nearbyOffices.isNotEmpty) ...[
          SectionHeader(title: l.secNearbyOffices, icon: Icons.near_me_rounded, padding: headerPadding),
          for (final o in detail.nearbyOffices)
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: _OfficeCard(office: o)),
        ],
        SectionHeader(title: l.secTrust, icon: Icons.verified_user_rounded, padding: headerPadding),
        Padding(padding: gutter, child: _TrustCard(detail: detail)),
      ],
    );
  }
}

/* -------------------------------------------------------------------- hero */

class _Hero extends StatelessWidget {
  const _Hero({required this.detail, required this.heroTop});
  final OpportunityDetail detail;
  final Color heroTop;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final s = detail.summary;
    final visual = categoryVisual(s.category);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [heroTop, AppColors.canvas],
        ),
      ),
      child: Stack(children: [
        Positioned(
          right: -24,
          top: -8,
          child: ExcludeSemantics(child: Icon(visual.icon, size: 150, color: visual.color.withValues(alpha: 0.10))),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 6, children: [
              Pill(label: categoryLabel(l, s.category), color: visual.color, icon: visual.icon),
              if (s.verificationStatus == 'verified')
                Pill(label: l.verifVerified, color: AppColors.success, icon: Icons.verified_rounded),
            ]),
            const SizedBox(height: 12),
            Text(s.title.of(locale), style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.ink)),
            if (s.organization != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.account_balance_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.organization!.name.of(locale),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// Honesty first: the app must not present sample or unchecked data as official.
class _VerificationBanner extends StatelessWidget {
  const _VerificationBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sun.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        const Icon(Icons.info_rounded, color: AppColors.warning),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            verificationLabel(l, status),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }
}

/* --------------------------------------------------------------- key facts */

class _KeyFacts extends StatelessWidget {
  const _KeyFacts({required this.detail});
  final OpportunityDetail detail;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final s = detail.summary;
    final money = benefitText(l, locale, s.benefitAmount, s.benefitPeriod);
    final deadline = s.deadline;
    final days = deadline == null ? null : daysUntil(deadline);

    final facts = <Widget>[
      if (money != null) _Fact(icon: Icons.payments_rounded, label: l.keyBenefit, value: money, color: AppColors.primary),
      if (deadline != null)
        _Fact(
          icon: Icons.event_rounded,
          label: l.keyDeadline,
          value: formatDate(locale, deadline),
          note: days! < 0 ? l.deadlinePassed : l.daysLeft(days),
          color: days < 0 || days <= 7 ? AppColors.danger : AppColors.warning,
        ),
      if (detail.processingTime != null && detail.processingTime!.isNotEmpty)
        _Fact(
          icon: Icons.hourglass_bottom_rounded,
          label: l.processingTime,
          value: detail.processingTime!,
          color: const Color(0xFF3F6FD8),
        ),
    ];
    if (facts.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < facts.length; i++) ...[
              if (i > 0) const VerticalDivider(width: 1),
              Expanded(child: facts[i]),
            ],
          ]),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value, required this.color, this.note});
  final IconData icon;
  final String label;
  final String value;
  final String? note;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: color, width: kHairline)),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        if (note != null)
          Text(note!, textAlign: TextAlign.center, style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/* ----------------------------------------------------------------- verdict */

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.detail});
  final OpportunityDetail detail;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final style = outcomeStyle(theme.colorScheme, detail.outcome);
    final rules = detail.rules.where((r) => r.reason != null).toList();
    final met = rules.where((r) => r.state == 'met').length;
    final score = detail.score.clamp(0, 100);
    final percent = NumberFormat.percentPattern(locale.languageCode).format(score / 100);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: style.color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: style.color.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          child: Row(children: [
            Semantics(
              label: l.eligScore(score),
              child: ExcludeSemantics(
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(fit: StackFit.expand, children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      color: style.color,
                      backgroundColor: style.color.withValues(alpha: 0.15),
                    ),
                    Center(
                      child: Text(percent, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Semantics(
                  header: true,
                  child: Text(
                    l.secWhyEligible,
                    style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(style.icon, color: style.color, size: 24),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      outcomeLabel(l, detail.outcome),
                      style: theme.textTheme.titleLarge?.copyWith(color: style.color),
                    ),
                  ),
                ]),
                if (rules.isNotEmpty)
                  Text(l.rulesSummary(met, rules.length), style: theme.textTheme.bodySmall),
              ]),
            ),
          ]),
        ),
        if (rules.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(children: [for (final r in rules) _RuleRow(rule: r)]),
          ),
      ]),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.rule});
  final RuleResult rule;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final (icon, color, label) = switch (rule.state) {
      'met' => (Icons.check_rounded, AppColors.success, l.ruleMet),
      'failed' => (Icons.close_rounded, AppColors.danger, l.ruleFailed),
      _ => (Icons.question_mark_rounded, scheme.outline, l.ruleUnknown),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: color, width: kHairline)),
          child: Icon(icon, size: 16, color: color, semanticLabel: label),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(rule.reason!.of(locale))),
      ]),
    );
  }
}

/* ------------------------------------------------------------ text, steps */

/// Long text clipped to a few lines with a "Read more" toggle, shown only when
/// the text is actually longer than that.
class _ExpandableText extends StatefulWidget {
  const _ExpandableText(this.text);
  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  static const _lines = 5;
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.bodyLarge;
    return LayoutBuilder(builder: (context, constraints) {
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: style),
        maxLines: _lines,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      final overflows = painter.didExceedMaxLines;
      painter.dispose();

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: Text(
            widget.text,
            style: style,
            maxLines: _expanded ? null : _lines,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ),
        if (overflows)
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 40)),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? l.readLess : l.readMore),
          ),
      ]);
    });
  }
}

class _StepsTimeline extends StatelessWidget {
  const _StepsTimeline({required this.steps});
  final List<ApplicationStep> steps;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final number = NumberFormat.decimalPattern(locale.languageCode);
    return Column(children: [
      for (var i = 0; i < steps.length; i++)
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Column(children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Text(
                  number.format(steps[i].step == 0 ? i + 1 : steps[i].step),
                  style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
                ),
              ),
              if (i < steps.length - 1)
                Expanded(child: Container(width: 2, color: theme.colorScheme.primaryContainer)),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 4, bottom: i < steps.length - 1 ? 18 : 0),
                child: Text(steps[i].text.of(locale), style: theme.textTheme.bodyLarge),
              ),
            ),
          ]),
        ),
    ]);
  }
}

/* --------------------------------------------------------------- documents */

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.doc});
  final RequiredDocument doc;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.description_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(doc.name.of(locale), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
                doc.required
                    ? Pill(label: l.requiredDoc, color: AppColors.danger)
                    : Pill(label: l.optionalDoc, color: theme.colorScheme.outline),
              ]),
              if (doc.issuedBy != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(doc.issuedBy!.of(locale), style: theme.textTheme.bodySmall),
                ),
              if (doc.tip != null)
                _Note(icon: Icons.lightbulb_rounded, color: AppColors.warning, label: l.tipLabel, text: doc.tip!.of(locale)),
              if (doc.commonMistake != null)
                _Note(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  label: l.commonMistakeLabel,
                  text: doc.commonMistake!.of(locale),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.color, required this.label, required this.text});
  final IconData icon;
  final Color color;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$label: ', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
              TextSpan(text: text),
            ]),
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ]),
    );
  }
}

/* ----------------------------------------------------------------- offices */

Future<void> _launch(BuildContext context, Uri uri) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened) messenger.showSnackBar(SnackBar(content: Text(l.couldNotOpen)));
}

Uri? _webUri(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final text = raw.trim();
  return Uri.tryParse(text.contains('://') ? text : 'https://$text');
}

class _OfficeCard extends StatelessWidget {
  const _OfficeCard({required this.office, this.website, this.applyUrl});
  final OrganizationRef office;
  final String? website;
  final String? applyUrl;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final name = office.name.of(locale);
    final address = office.address?.of(locale);
    final phone = office.contactPhone;
    final site = _webUri(website);
    final apply = _webUri(applyUrl);

    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ]),
        );

    const compact = Size(0, 44);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          if (address != null && address.isNotEmpty) line(Icons.place_outlined, address),
          if (office.officeHours != null) line(Icons.schedule_rounded, '${l.officeHours}: ${office.officeHours!.of(locale)}'),
          if (phone != null && phone.isNotEmpty) line(Icons.phone_outlined, phone),
          if (phone != null || address != null || site != null) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (phone != null && phone.isNotEmpty)
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: compact),
                  onPressed: () => _launch(context, Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''))),
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: Text(l.callOffice),
                ),
              if (address != null && address.isNotEmpty)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: compact),
                  onPressed: () => _launch(
                    context,
                    Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': '$name, $address'}),
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: Text(l.directions),
                ),
              if (site != null)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: compact),
                  onPressed: () => _launch(context, site),
                  icon: const Icon(Icons.language_rounded, size: 18),
                  label: Text(l.website),
                ),
            ]),
          ],
          if (apply != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _launch(context, apply),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(l.applyOnline),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

/* ------------------------------------------------------------------- trust */

class _TrustCard extends StatelessWidget {
  const _TrustCard({required this.detail});
  final OpportunityDetail detail;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final score = detail.confidenceScore.clamp(0, 100);
    final color = switch (detail.confidenceBand) {
      'high' => AppColors.success,
      'medium' => AppColors.warning,
      _ => AppColors.danger,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                confidenceLabel(l, detail.confidenceBand),
                style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              NumberFormat.percentPattern(locale.languageCode).format(score / 100),
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          for (final r in detail.confidenceReasons)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.circle, size: 6, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(child: Text(r.of(locale), style: theme.textTheme.bodyMedium)),
              ]),
            ),
          if (detail.sourceNote != null && detail.sourceNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('${l.sourceLabel}: ${detail.sourceNote}', style: theme.textTheme.bodySmall),
          ],
        ]),
      ),
    );
  }
}

/* ------------------------------------------------------------- action bar */

/// Save and plan, in thumb reach. "Make a plan" turns the programme's steps
/// and documents into a checklist; if one exists the button opens it instead.
class _ActionBar extends ConsumerStatefulWidget {
  const _ActionBar({required this.opportunityId, required this.slug});
  final String opportunityId;
  final String slug;

  @override
  ConsumerState<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends ConsumerState<_ActionBar> {
  bool _busy = false;

  Future<void> _plan() async {
    final l = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final existing = ref.read(planForOpportunityProvider(widget.slug));
    if (existing != null) {
      router.push('/plan/${existing.id}');
      return;
    }
    setState(() => _busy = true);
    final result = await ref.read(planControllerProvider.notifier).createFor(widget.opportunityId);
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      ok: (plan) => router.push('/plan/${plan.id}'),
      err: (e) => messenger.showSnackBar(SnackBar(content: Text(errorText(l, e)))),
    );
  }

  Future<void> _toggleSave() => toggleSaved(context, ref, widget.opportunityId);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasPlan = ref.watch(planForOpportunityProvider(widget.slug)) != null;
    final isSaved = ref.watch(savedForOpportunityProvider(widget.opportunityId)) != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            SizedBox(
              width: 56,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(52, 52),
                  foregroundColor: isSaved ? AppColors.primary : null,
                  side: BorderSide(color: isSaved ? AppColors.primary : Theme.of(context).colorScheme.outlineVariant, width: kHairline),
                ),
                onPressed: _toggleSave,
                child: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  semanticLabel: isSaved ? l.unsaveProgramme : l.saveProgramme,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : _plan,
                icon: _busy
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(hasPlan ? Icons.checklist_rounded : Icons.playlist_add_check_rounded),
                label: Text(hasPlan ? l.openPlan : l.makePlan),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/* ---------------------------------------------------------------- loading */

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          Skeleton(width: 120, height: 28, radius: 20),
          SizedBox(height: 14),
          Skeleton(height: 30),
          SizedBox(height: 8),
          Skeleton(width: 220, height: 30),
          SizedBox(height: 20),
          Skeleton(height: 110, radius: AppRadius.lg),
          SizedBox(height: 16),
          Skeleton(height: 170, radius: AppRadius.lg),
          SizedBox(height: 16),
          Skeleton(height: 120, radius: AppRadius.lg),
        ],
      );
}

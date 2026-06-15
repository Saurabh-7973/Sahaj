import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/widgets.dart';

/// Optional doctor consultation (pricing_paywall_copy.md §4).
///
/// FIREWALL: this surface is opt-in and reachable ONLY from Settings. It must
/// NEVER be triggered by, linked from, or suggested alongside any health
/// screening result, warning-sign content, or "see a doctor" message —
/// funnelling an honest health prompt into a paid sale is exactly the pattern
/// the app refuses. Do not import or route to it from onboarding/triage/safety.
///
/// Booking is not live: there is no doctor panel or payment backend yet, and
/// the app does not charge for something it can't deliver (the same honesty
/// rule that cut the ₹1499 tier). The CTA stays in a truthful "not yet" state
/// until a real provider exists.
class ConsultationScreen extends StatelessWidget {
  const ConsultationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Talk to a doctor',
      leading: const BackButton(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Want to talk to a doctor?',
              style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Text(
            'If you\'d like a professional opinion, you\'ll be able to book a '
            'one-time consultation with a doctor through Sahaj.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'It\'s entirely optional — your own GP or any clinician works just '
            'as well. This is here only if it\'s convenient for you.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                'Not available yet. We\'re still lining up the doctors, and we '
                'won\'t charge for something we can\'t yet deliver. When it\'s '
                'ready, booking will appear here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Honest "not yet" state — disabled until a real provider exists.
          AppButton(
            label: 'Book a consultation',
            onPressed: null,
          ),
        ],
      ),
    );
  }
}

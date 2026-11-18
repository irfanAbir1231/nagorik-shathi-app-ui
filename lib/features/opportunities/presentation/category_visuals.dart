import 'package:flutter/material.dart';

/// An icon and accent colour per category, for tiles and cards. Decorative only:
/// the category name is always shown next to it, so nothing relies on colour.
({IconData icon, Color color}) categoryVisual(String slug) => switch (slug) {
      'scholarship' => const (icon: Icons.school_rounded, color: Color(0xFF3F6FD8)),
      'healthcare' => const (icon: Icons.local_hospital_rounded, color: Color(0xFFD9485F)),
      'agriculture' => const (icon: Icons.agriculture_rounded, color: Color(0xFF3E8E41)),
      'business' => const (icon: Icons.storefront_rounded, color: Color(0xFFE07A1F)),
      'legal_aid' => const (icon: Icons.gavel_rounded, color: Color(0xFF6B4FBB)),
      'employment' => const (icon: Icons.work_rounded, color: Color(0xFF00838F)),
      'financial' => const (icon: Icons.account_balance_wallet_rounded, color: Color(0xFFB07A00)),
      'social_welfare' => const (icon: Icons.volunteer_activism_rounded, color: Color(0xFFC2185B)),
      'training' => const (icon: Icons.handyman_rounded, color: Color(0xFF5D7A1F)),
      'disaster' => const (icon: Icons.flood_rounded, color: Color(0xFF1565C0)),
      'research' => const (icon: Icons.science_rounded, color: Color(0xFF7B5E3B)),
      _ => const (icon: Icons.category_rounded, color: Color(0xFF607D8B)),
    };

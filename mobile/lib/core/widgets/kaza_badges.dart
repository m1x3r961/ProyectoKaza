import 'package:flutter/material.dart';
import '../../app/theme/kaza_theme.dart';

/// Reusable Badges for Property & Listing metadata as specified in Kaza Master v0.2
class KazaTrustBadge extends StatelessWidget {
  final String label;
  final bool isOrganization;

  const KazaTrustBadge({
    super.key,
    this.label = 'Actor Verificado',
    this.isOrganization = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: KazaTheme.trustBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KazaTheme.trustBlue.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOrganization ? Icons.business : Icons.verified_user,
            size: 14,
            color: KazaTheme.trustBlue,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: KazaTheme.trustBlue,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class KazaPlusBadge extends StatelessWidget {
  const KazaPlusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KazaTheme.accentGold,
            KazaTheme.accentGold.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: KazaTheme.accentGold.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 14, color: Colors.black),
          SizedBox(width: 2),
          Text(
            'PLUS',
            style: TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class KazaStatusBadge extends StatelessWidget {
  final String status;

  const KazaStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String labelText;

    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        badgeColor = KazaTheme.statusAvailable;
        labelText = 'Disponible';
        break;
      case 'RESERVED':
        badgeColor = KazaTheme.statusReserved;
        labelText = 'Reservado';
        break;
      case 'CLOSED':
        badgeColor = KazaTheme.statusClosed;
        labelText = 'Vendido / Cerrado';
        break;
      default:
        badgeColor = KazaTheme.statusPaused;
        labelText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            labelText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

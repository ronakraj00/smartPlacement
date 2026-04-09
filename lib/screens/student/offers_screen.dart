import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/offer_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_helper.dart';
import '../../theme/app_theme.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  void _respondToOffer(BuildContext context, OfferModel offer, String response) async {
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(response == 'accepted' ? '🎉 Accept Offer?' : 'Decline Offer?'),
        content: Text(response == 'accepted'
            ? 'You\'re about to accept the ${offer.role} offer from ${offer.company} at ${offer.ctcLpa} LPA. This action is significant.'
            : 'Are you sure you want to decline this offer? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: response == 'accepted' ? AppTheme.success : AppTheme.error,
            ),
            child: Text(response == 'accepted' ? 'Accept' : 'Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('offers').doc(offer.id).update({'status': response});
      if (response == 'accepted') {
        await FirebaseFirestore.instance.collection('users').doc(offer.studentId).update({
          'placementStatus': 'placed',
          'offersReceived': FieldValue.increment(1),
        });
        await NotificationHelper.onApplicationStatusChange(
          studentId: offer.studentId,
          jobTitle: '${offer.role} at ${offer.company}',
          newStatus: 'Offer Accepted ✅',
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Offer ${response == 'accepted' ? 'accepted! 🎉' : 'declined.'}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('offers')
          .where('studentId', isEqualTo: user.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.card_giftcard_rounded, size: 40, color: AppTheme.primary.withAlpha(100)),
                ),
                const SizedBox(height: 16),
                Text('No offers yet', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                const Text('Keep applying and ace your interviews!',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ],
            ),
          );
        }

        final offers = docs.map((d) => OfferModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
        offers.sort((a, b) => b.offeredAt.compareTo(a.offeredAt));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            return _buildOfferCard(context, offer);
          },
        );
      },
    );
  }

  Widget _buildOfferCard(BuildContext context, OfferModel offer) {
    final tierColor = _tierColor(offer.tier);
    final statusColor = _statusColor(offer.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: offer.status == 'accepted' ? AppTheme.success.withAlpha(100) : AppTheme.dividerColor,
          width: offer.status == 'accepted' ? 2 : 1,
        ),
        boxShadow: [
          if (offer.status == 'pending')
            BoxShadow(color: tierColor.withAlpha(20), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Tier ribbon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [tierColor.withAlpha(20), tierColor.withAlpha(8)]),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(19), topRight: Radius.circular(19)),
            ),
            child: Center(
              child: Text(
                offer.tier == 'Super Dream' ? '⭐ SUPER DREAM OFFER' : offer.tier == 'Dream' ? '💎 DREAM OFFER' : '📋 OFFER',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: tierColor, letterSpacing: 1),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [tierColor.withAlpha(25), tierColor.withAlpha(12)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(offer.company[0].toUpperCase(),
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: tierColor)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(offer.role, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          Text(offer.company, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    // CTC badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.success.withAlpha(15), AppTheme.success.withAlpha(8)]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.success.withAlpha(40)),
                      ),
                      child: Text('₹${offer.ctcLpa} LPA', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.success)),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Status and deadline row
                Row(
                  children: [
                    _statusBadge(offer.status, statusColor),
                    const Spacer(),
                    if (offer.responseDeadline != null)
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: offer.isExpired ? AppTheme.error : AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            offer.isExpired
                                ? 'EXPIRED'
                                : 'Due ${offer.responseDeadline!.day}/${offer.responseDeadline!.month}/${offer.responseDeadline!.year}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                color: offer.isExpired ? AppTheme.error : AppTheme.textSecondary),
                          ),
                        ],
                      ),
                  ],
                ),

                if (offer.offerLetterUrl != null && offer.offerLetterUrl!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.info.withAlpha(10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description_outlined, size: 16, color: AppTheme.info),
                          SizedBox(width: 6),
                          Text('View Offer Letter', style: TextStyle(color: AppTheme.info, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],

                // Accept/Decline Buttons
                if (offer.status == 'pending' && !offer.isExpired) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _respondToOffer(context, offer, 'declined'),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Decline'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _respondToOffer(context, offer, 'accepted'),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    IconData icon;
    String label;
    switch (status) {
      case 'accepted': icon = Icons.check_circle_rounded; label = 'ACCEPTED'; break;
      case 'declined': icon = Icons.cancel_rounded; label = 'DECLINED'; break;
      default: icon = Icons.pending_rounded; label = 'PENDING'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'Super Dream': return AppTheme.superDreamTier;
      case 'Dream': return AppTheme.dreamTier;
      default: return AppTheme.normalTier;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted': return AppTheme.success;
      case 'declined': return AppTheme.error;
      default: return AppTheme.warning;
    }
  }
}

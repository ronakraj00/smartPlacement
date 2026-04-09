import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/offer_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_helper.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  void _respondToOffer(BuildContext context, OfferModel offer, String response) async {
    try {
      await FirebaseFirestore.instance.collection('offers').doc(offer.id).update({
        'status': response,
      });

      if (response == 'accepted') {
        // Update student's placement status
        await FirebaseFirestore.instance.collection('users').doc(offer.studentId).update({
          'placementStatus': 'placed',
          'offersReceived': FieldValue.increment(1),
        });

        // Notify
        await NotificationHelper.onApplicationStatusChange(
          studentId: offer.studentId,
          jobTitle: '${offer.role} at ${offer.company}',
          newStatus: 'Offer Accepted ✅',
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Offer ${response == 'accepted' ? 'accepted' : 'declined'}!')),
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No offers yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                Text('Keep applying and interview well!', style: TextStyle(color: Colors.grey)),
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
            Color tierColor = offer.tier == 'Super Dream'
                ? Colors.amber.shade800
                : offer.tier == 'Dream'
                    ? Colors.purple
                    : Colors.blue;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: offer.status == 'accepted'
                    ? const BorderSide(color: Colors.green, width: 2)
                    : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: tierColor.withAlpha(30),
                          child: Text(offer.company[0].toUpperCase(), style: TextStyle(color: tierColor, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(offer.role, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(offer.company, style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: tierColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tierColor),
                          ),
                          child: Text(offer.tier, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tierColor)),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        _detailChip(Icons.currency_rupee, '${offer.ctcLpa} LPA', Colors.green),
                        const SizedBox(width: 12),
                        _detailChip(
                          offer.status == 'accepted' ? Icons.check_circle : offer.status == 'declined' ? Icons.cancel : Icons.pending,
                          offer.status.toUpperCase(),
                          offer.status == 'accepted' ? Colors.green : offer.status == 'declined' ? Colors.red : Colors.orange,
                        ),
                      ],
                    ),
                    if (offer.responseDeadline != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Respond by: ${offer.responseDeadline!.day}/${offer.responseDeadline!.month}/${offer.responseDeadline!.year}${offer.isExpired ? " (EXPIRED)" : ""}',
                        style: TextStyle(fontSize: 12, color: offer.isExpired ? Colors.red : Colors.grey),
                      ),
                    ],
                    if (offer.offerLetterUrl != null && offer.offerLetterUrl!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {},
                        child: const Row(
                          children: [
                            Icon(Icons.description, size: 16, color: Colors.blue),
                            SizedBox(width: 4),
                            Text('View Offer Letter', style: TextStyle(color: Colors.blue, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                    if (offer.status == 'pending' && !offer.isExpired) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _respondToOffer(context, offer, 'declined'),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                              child: const Text('Decline', style: TextStyle(color: Colors.red)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _respondToOffer(context, offer, 'accepted'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Accept Offer', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

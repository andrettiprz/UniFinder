import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/review.dart';
import '../providers/review_provider.dart';
import '../auth/auth_provider.dart';
import 'review_dialog.dart';

class ReviewsSection extends StatefulWidget {
  final String universidadId;
  final String universidadNombre;

  const ReviewsSection({
    super.key,
    required this.universidadId,
    required this.universidadNombre,
  });

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  bool _showAllReviews = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().loadUniversidadReviews(widget.universidadId);
    });
  }

  Future<void> _showReviewDialog(BuildContext context, [Review? existingReview]) async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión para dejar una review')),
        );
      }
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ReviewDialog(
        universidadId: widget.universidadId,
        universidadNombre: widget.universidadNombre,
        existingReview: existingReview,
      ),
    );

    if (result != null && context.mounted) {
      final reviewProvider = context.read<ReviewProvider>();
      final user = authProvider.user!;

      final review = Review(
        id: existingReview?.id ?? '',
        userId: user.uid,
        userName: user.email ?? 'Usuario',
        universidadId: widget.universidadId,
        universidadNombre: widget.universidadNombre,
        rating: result['rating'],
        comentario: result['comentario'],
        fecha: DateTime.now(),
      );

      try {
        if (existingReview != null) {
          await reviewProvider.updateReview(review);
        } else {
          await reviewProvider.createReview(review);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                existingReview != null
                    ? 'Review actualizada correctamente'
                    : 'Review publicada correctamente',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al publicar la review'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        final reviews = reviewProvider.universidadReviews[widget.universidadId] ?? [];
        final promedio = reviewProvider.promedioRatings[widget.universidadId] ?? 0.0;
        
        // Determinar cuántas reviews mostrar
        final displayedReviews = _showAllReviews ? reviews : reviews.take(3).toList();
        final hasMoreReviews = reviews.length > 3;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reviews',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (reviews.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: promedio,
                                  itemBuilder: (context, _) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  itemCount: 5,
                                  itemSize: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${promedio.toStringAsFixed(1)} (${reviews.length})',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showReviewDialog(context),
                        icon: const Icon(Icons.rate_review),
                        label: const Text('Escribir Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sé el primero en dejar una review',
                  style: TextStyle(fontSize: 16),
                ),
              )
            else
              Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayedReviews.length,
                    itemBuilder: (context, index) {
                      final review = displayedReviews[index];
                      return ReviewTile(
                        review: review,
                        onEdit: () => _showReviewDialog(context, review),
                      );
                    },
                  ),
                  if (hasMoreReviews && !_showAllReviews)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _showAllReviews = true;
                          });
                        },
                        child: Text(
                          'Ver todas las reviews (${reviews.length})',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class ReviewTile extends StatelessWidget {
  final Review review;
  final VoidCallback onEdit;

  const ReviewTile({
    super.key,
    required this.review,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = context.read<AuthProvider>().user?.uid == review.userId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  review.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (isCurrentUser)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    tooltip: 'Editar review',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            RatingBarIndicator(
              rating: review.rating,
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              itemCount: 5,
              itemSize: 20,
            ),
            const SizedBox(height: 8),
            Text(review.comentario),
            const SizedBox(height: 8),
            Text(
              'Fecha: ${_formatDate(review.fecha)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 
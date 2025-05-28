import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/review.dart';

class ReviewDialog extends StatefulWidget {
  final String universidadId;
  final String universidadNombre;
  final Review? existingReview;

  const ReviewDialog({
    super.key,
    required this.universidadId,
    required this.universidadNombre,
    this.existingReview,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  late double _rating;
  late TextEditingController _comentarioController;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 0;
    _comentarioController = TextEditingController(
      text: widget.existingReview?.comentario ?? '',
    );
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existingReview != null ? 'Editar Review' : 'Nueva Review',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.universidadNombre,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: RatingBar.builder(
                initialRating: _rating,
                minRating: 0,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _comentarioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentario',
                border: OutlineInputBorder(),
                hintText: 'Escribe tu opinión sobre esta universidad...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _rating == 0
                      ? null
                      : () {
                          if (_comentarioController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Por favor escribe un comentario'),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context, {
                            'rating': _rating,
                            'comentario': _comentarioController.text.trim(),
                          });
                        },
                  child: Text(
                    widget.existingReview != null ? 'Actualizar' : 'Publicar',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 
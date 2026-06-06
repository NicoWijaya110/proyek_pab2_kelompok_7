import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_theme.dart';
import '../../core/utils/image_utils.dart';
import '../../models/game_review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/favorite_service.dart';
import '../detail/detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final favoriteService = FavoriteService();

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favorit Saya')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('Masuk untuk melihat favoritmu',
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/signin'),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Masuk'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorit Saya'),
        centerTitle: false,
      ),
      body: StreamBuilder<List<String>>(
        stream: favoriteService.streamFavoriteIds(auth.user!.uid),
        builder: (ctx, idsSnap) {
          if (idsSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final ids = idsSnap.data ?? [];

          if (ids.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 72,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Belum ada favorit\nTandai review yang kamu suka!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.35)),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<List<dynamic>>(
            future: favoriteService.fetchFavoriteReviews(ids),
            builder: (ctx, reviewsSnap) {
              if (reviewsSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = reviewsSnap.data ?? [];
              final reviews = docs
                  .where((d) => d.exists)
                  .map((d) => GameReview.fromFirestore(d))
                  .toList();

              return ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: reviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) =>
                    _FavoriteCard(review: reviews[i], userId: auth.user!.uid),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final GameReview review;
  final String userId;
  const _FavoriteCard({required this.review, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(review: review)),
      ),
      child: Card(
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: ImageUtils.buildImage(
                review.imageUrl,
                width: 100,
                height: 130,
                fit: BoxFit.cover,
                placeholder: Container(color: AppColors.darkBorder),
                errorWidget: Container(
                  color: AppColors.darkBorder,
                  child: const Icon(Icons.broken_image_outlined,
                      color: Colors.white24),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.genreColor(review.genre)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            review.genre,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.genreColor(review.genre),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Tombol hapus dari favorit
                        GestureDetector(
                          onTap: () {
                            FavoriteService().toggleFavorite(
                                userId, review.id, true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Dihapus dari Favorit'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Icon(Icons.favorite_rounded,
                              color: Colors.red, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review.title,
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 13,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.reviewText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 11, color: isDark ? Colors.white38 : Colors.black38),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            review.userName,
                            style: TextStyle(
                                fontSize: 11, color: isDark ? Colors.white38 : Colors.black45),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeago.format(review.createdAt, locale: 'id'),
                          style: TextStyle(
                              fontSize: 10, color: isDark ? Colors.white24 : Colors.black38),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

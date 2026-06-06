import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/image_utils.dart';
import '../../models/game_review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/review_service.dart';
import '../detail/detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _reviewService = ReviewService();
  String _selectedGenre = 'Semua';
  bool _isGrid = false;

  final List<String> _genres = [
    'Semua', 'Action', 'RPG', 'Adventure', 'Sports', 'Strategy', 'Horror', 'Other'
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GAMES RR'),
        centerTitle: false,
        actions: [
          // Grid/List toggle
          IconButton(
            icon: Icon(_isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded),
            tooltip: _isGrid ? 'Mode List' : 'Mode Grid',
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
          // Dark mode toggle (shortcut dari home)
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          // Avatar / login
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                if (!auth.isLoggedIn) Navigator.pushNamed(context, '/signin');
              },
              child: () {
                final photoUrl = auth.userProfile?['photoUrl'] ?? auth.user?.photoURL ?? '';
                return CircleAvatar(
                  radius: 17,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                  backgroundImage: photoUrl.isNotEmpty
                      ? ImageUtils.getImageProvider(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
                      ? Icon(Icons.person_rounded, size: 18, color: colorScheme.primary)
                      : null,
                );
              }(),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Genre Filter Chips ──────────────────────────────────────
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _genres.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final genre = _genres[i];
                final isSelected = _selectedGenre == genre;
                return FilterChip(
                  label: Text(genre),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedGenre = genre),
                  selectedColor: AppColors.genreColor(genre).withValues(alpha: 0.25),
                  checkmarkColor: AppColors.genreColor(genre),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.genreColor(genre)
                        : Colors.transparent,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.genreColor(genre) : null,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              },
            ),
          ),

          // ── Review Stream ──────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<GameReview>>(
              stream: _reviewService.streamReviews(
                  genre: _selectedGenre == 'Semua' ? null : _selectedGenre),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _buildShimmer();
                }
                if (snap.hasError) {
                  return Center(
                    child: Text('Gagal memuat: ${snap.error}',
                        style: const TextStyle(color: Colors.redAccent)),
                  );
                }
                final reviews = snap.data ?? [];
                if (reviews.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sports_esports_outlined,
                            size: 64,
                            color: colorScheme.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada review\nJadi yang pertama!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                  );
                }

                Widget content;
                if (_isGrid) {
                  content = GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(ctx).size.width > 1200
                          ? 5
                          : MediaQuery.of(ctx).size.width > 900
                              ? 4
                              : MediaQuery.of(ctx).size.width > 600
                                  ? 3
                                  : 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: reviews.length,
                    itemBuilder: (ctx, i) =>
                        _ReviewGridCard(review: reviews[i]),
                  );
                } else {
                  content = ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: reviews.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _ReviewListCard(review: reviews[i]),
                  );
                }

                return Expanded(
                  child: content,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.darkCard,
      highlightColor: AppColors.darkBorder,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ── Review List Card ─────────────────────────────────────────────────────────
class _ReviewListCard extends StatelessWidget {
  final GameReview review;
  const _ReviewListCard({required this.review});

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
            // Game Cover Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: ImageUtils.buildImage(
                review.imageUrl,
                width: 95,
                height: 120,
                fit: BoxFit.cover,
                placeholder: Container(
                  color: AppColors.darkBorder,
                  child: const Icon(Icons.image_outlined, color: Colors.white24),
                ),
                errorWidget: Container(
                  color: AppColors.darkBorder,
                  child: const Icon(Icons.broken_image_outlined, color: Colors.white24),
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Genre chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.genreColor(review.genre).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.genreColor(review.genre).withValues(alpha: 0.5),
                        ),
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
                    // Star rating
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < review.rating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 14,
                        color: Colors.amber,
                      )),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review.reviewText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 12, color: isDark ? Colors.white38 : Colors.black38),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            review.userName,
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeago.format(review.createdAt, locale: 'id'),
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.white24 : Colors.black38),
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

// ── Review Grid Card ─────────────────────────────────────────────────────────
class _ReviewGridCard extends StatelessWidget {
  final GameReview review;
  const _ReviewGridCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(review: review)),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImageUtils.buildImage(
                    review.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: Container(color: AppColors.darkBorder),
                    errorWidget: Container(
                      color: AppColors.darkBorder,
                      child: const Icon(Icons.broken_image_outlined, color: Colors.white24),
                    ),
                  ),
                  // Genre overlay
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.genreColor(review.genre),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        review.genre,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  // Rating overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            review.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.title,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 11, color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          review.userName,
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
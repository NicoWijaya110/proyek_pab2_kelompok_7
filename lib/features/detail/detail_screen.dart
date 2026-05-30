import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../models/game_review.dart';
import '../../models/comment.dart';
import '../../providers/auth_provider.dart';
import '../../services/comment_service.dart';
import '../../services/favorite_service.dart';

class DetailScreen extends StatefulWidget {
  final GameReview review;
  const DetailScreen({super.key, required this.review});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _commentService = CommentService();
  final _favoriteService = FavoriteService();
  final _commentCtrl = TextEditingController();
  final _replyCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String? _replyingToId; // ID komentar yang sedang dibalas
  String? _replyingToName; // Nama user yang dibalas

  @override
  void dispose() {
    _commentCtrl.dispose();
    _replyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Buka Google Maps untuk koordinat lokasi
  Future<void> _openMaps() async {
    if (widget.review.latitude == null) return;
    final lat = widget.review.latitude!;
    final lng = widget.review.longitude!;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Kirim komentar baru / balasan
  Future<void> _submitComment() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      Navigator.pushNamed(context, '/signin');
      return;
    }

    final isReply = _replyingToId != null;
    final text = isReply ? _replyCtrl.text.trim() : _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final comment = Comment(
      id: '',
      reviewId: widget.review.id,
      parentId: _replyingToId,
      userId: auth.user!.uid,
      userName: auth.user!.displayName ?? 'Anonim',
      userPhotoUrl: auth.user!.photoURL ?? '',
      text: text,
      createdAt: DateTime.now(),
    );

    await _commentService.addComment(comment);

    if (isReply) {
      _replyCtrl.clear();
      setState(() {
        _replyingToId = null;
        _replyingToName = null;
      });
    } else {
      _commentCtrl.clear();
    }
  }

  // Hapus komentar
  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Komentar?'),
        content: const Text('Komentar ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _commentService.deleteComment(
        reviewId: widget.review.id,
        commentId: commentId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // ── Sliver App Bar dengan Cover Image ─────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: widget.review.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: AppColors.darkCard),
                errorWidget: (_, _, _) => Container(
                  color: AppColors.darkCard,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white24,
                    size: 48,
                  ),
                ),
              ),
            ),
            actions: [
              // Tombol Favorit
              if (auth.isLoggedIn)
                StreamBuilder<bool>(
                  stream: _favoriteService.isFavorite(
                    auth.user!.uid,
                    widget.review.id,
                  ),
                  builder: (ctx, snap) {
                    final isFav = snap.data ?? false;
                    return IconButton(
                      icon: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFav ? Colors.red : Colors.white,
                      ),
                      onPressed: () async {
                        await _favoriteService.toggleFavorite(
                          auth.user!.uid,
                          widget.review.id,
                          isFav,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFav
                                    ? 'Dihapus dari Favorit'
                                    : 'Ditambahkan ke Favorit ❤️',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Genre Badge + Time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.genreColor(widget.review.genre),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.review.genre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: Colors.white38,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeago.format(widget.review.createdAt, locale: 'id'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Judul Game
                  Text(
                    widget.review.title,
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Reviewer
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.darkBorder,
                        backgroundImage: widget.review.userPhotoUrl.isNotEmpty
                            ? NetworkImage(widget.review.userPhotoUrl)
                            : null,
                        child: widget.review.userPhotoUrl.isEmpty
                            ? const Icon(
                                Icons.person_rounded,
                                size: 14,
                                color: Colors.white38,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.review.userName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Rating Stars
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < widget.review.rating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.review.rating.toStringAsFixed(1)} / 5.0',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Divider(color: AppColors.darkBorder),
                  const SizedBox(height: 12),

                  // Review Text
                  Text(
                    widget.review.reviewText,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Lokasi GPS ───────────────────────────────────
                  if (widget.review.latitude != null) ...[
                    GestureDetector(
                      onTap: _openMaps,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.review.locationName ??
                                            'Lokasi tercatat',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${widget.review.latitude!.toStringAsFixed(6)}, '
                                        '${widget.review.longitude!.toStringAsFixed(6)}',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.open_in_new_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: GestureDetector(
                                onTap: _openMaps,
                                child: SizedBox(
                                  height: 180,
                                  child: FlutterMap(
                                    options: MapOptions(
                                      center: LatLng(widget.review.latitude!, widget.review.longitude!),
                                      zoom: 15,
                                      interactiveFlags: InteractiveFlag.all,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        subdomains: const ['a', 'b', 'c'],
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(widget.review.latitude!, widget.review.longitude!),
                                            width: 36,
                                            height: 36,
                                            builder: (ctx) => const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 36),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Divider(color: AppColors.darkBorder),
                  const SizedBox(height: 12),

                  // ── Section Komentar ─────────────────────────────
                  Text(
                    'Komentar (${widget.review.commentsCount})',
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Daftar Komentar
                  StreamBuilder<List<Comment>>(
                    stream: _commentService.streamComments(widget.review.id),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final comments = snap.data ?? [];

                      // Pisahkan komentar utama dan balasan
                      final topLevel = comments
                          .where((c) => c.parentId == null)
                          .toList();
                      final replies = comments
                          .where((c) => c.parentId != null)
                          .toList();

                      if (topLevel.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'Belum ada komentar.\nJadi yang pertama!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: _openMaps,
                                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                  label: const Text('Buka di Google Maps'),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: topLevel.map((comment) {
                          final commentReplies = replies
                              .where((r) => r.parentId == comment.id)
                              .toList();
                          return _CommentTile(
                            comment: comment,
                            replies: commentReplies,
                            currentUserId: auth.user?.uid,
                            onReply: () {
                              setState(() {
                                _replyingToId = comment.id;
                                _replyingToName = comment.userName;
                              });
                              // Scroll ke bawah ke text field
                              Future.delayed(
                                const Duration(milliseconds: 300),
                                () => _scrollCtrl.animateTo(
                                  _scrollCtrl.position.maxScrollExtent,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOut,
                                ),
                              );
                            },
                            onDelete: () => _deleteComment(comment.id),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 120), // Ruang untuk input field
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Input Komentar (Sticky Bottom) ─────────────────────────────
      bottomSheet: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          border: Border(top: BorderSide(color: AppColors.darkBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indikator sedang membalas
            if (_replyingToId != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.reply_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Membalas $_replyingToName',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _replyingToId = null;
                        _replyingToName = null;
                      }),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyingToId != null
                        ? _replyCtrl
                        : _commentCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _replyingToId != null
                          ? 'Tulis balasan...'
                          : 'Tulis komentar...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _submitComment,
                  icon: const Icon(Icons.send_rounded),
                  color: AppColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
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

// ── Comment Tile (komentar + balasan tersarang) ──────────────────────────────
class _CommentTile extends StatefulWidget {
  final Comment comment;
  final List<Comment> replies;
  final String? currentUserId;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.replies,
    required this.currentUserId,
    required this.onReply,
    required this.onDelete,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _showReplies = true;

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.comment.userId == widget.currentUserId;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Komentar Utama
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.darkBorder,
                backgroundImage: widget.comment.userPhotoUrl.isNotEmpty
                    ? NetworkImage(widget.comment.userPhotoUrl)
                    : null,
                child: widget.comment.userPhotoUrl.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: Colors.white38,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.comment.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timeago.format(
                              widget.comment.createdAt,
                              locale: 'id',
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.comment.text,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Balas button
                          if (widget.currentUserId != null)
                            GestureDetector(
                              onTap: widget.onReply,
                              child: const Text(
                                'Balas',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 16),
                          // Hapus button (hanya pemilik)
                          if (isOwner)
                            GestureDetector(
                              onTap: widget.onDelete,
                              child: const Text(
                                'Hapus',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Balasan (tersarang/indented)
          if (widget.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Column(
                children: [
                  // Toggle tampil/sembunyikan balasan
                  GestureDetector(
                    onTap: () => setState(() => _showReplies = !_showReplies),
                    child: Row(
                      children: [
                        Icon(
                          _showReplies
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        Text(
                          _showReplies
                              ? 'Sembunyikan ${widget.replies.length} balasan'
                              : 'Lihat ${widget.replies.length} balasan',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showReplies)
                    ...widget.replies.map(
                      (reply) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: AppColors.darkBorder,
                              backgroundImage: reply.userPhotoUrl.isNotEmpty
                                  ? NetworkImage(reply.userPhotoUrl)
                                  : null,
                              child: reply.userPhotoUrl.isEmpty
                                  ? const Icon(
                                      Icons.person_rounded,
                                      size: 12,
                                      color: Colors.white38,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.darkCard,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.darkBorder,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          reply.userName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          timeago.format(
                                            reply.createdAt,
                                            locale: 'id',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white38,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      reply.text,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                    // Hapus balasan (hanya pemilik)
                                    if (reply.userId ==
                                        widget.currentUserId) ...[
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: widget.onDelete,
                                        child: const Text(
                                          'Hapus',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

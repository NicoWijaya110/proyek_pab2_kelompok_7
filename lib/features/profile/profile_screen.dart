import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../models/game_review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/review_service.dart';
import '../../services/storage_service.dart';
import '../detail/detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  File? _newPhotoFile;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _startEditing(Map<String, dynamic>? profile, String? displayName) {
    _nameCtrl.text = profile?['displayName'] ?? displayName ?? '';
    _bioCtrl.text = profile?['bio'] ?? '';
    setState(() => _isEditing = true);
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 600,
    );
    if (xFile != null) {
      setState(() => _newPhotoFile = File(xFile.path));
    }
  }

  Future<void> _saveProfile() async {
    if (_bioCtrl.text.length > 150) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bio maksimal 150 karakter')),
      );
      return;
    }

    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();

    try {
      String? photoUrl;
      if (_newPhotoFile != null) {
        photoUrl = await StorageService()
            .uploadProfilePhoto(_newPhotoFile!, auth.user!.uid);
      }

      final err = await auth.updateProfile(
        displayName: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        photoUrl: photoUrl,
      );

      if (err != null) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Gagal: $err')));
        }
      } else {
        setState(() {
          _isEditing = false;
          _newPhotoFile = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui ✓'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;
    final reviewService = ReviewService();

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
              const SizedBox(height: 16),
              const Text('Masuk untuk melihat profilmu',
                  style: TextStyle(color: Colors.white54)),
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

    final profile = auth.userProfile;
    final displayName = auth.user?.displayName ?? 'User';
    final email = auth.user?.email ?? '';
    final photoUrl = profile?['photoUrl'] ?? auth.user?.photoURL ?? '';
    final bio = profile?['bio'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        centerTitle: false,
        actions: [
          // Dark Mode Toggle — Fitur utama Gregory
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    size: 18,
                    color: isDark ? AppColors.primary : AppColors.primaryDark),
                Switch(
                  value: isDark,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Keluar?'),
                  content: const Text('Kamu akan keluar dari akun ini.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Keluar',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true && mounted) {
                await auth.signOut();
                Navigator.pushReplacementNamed(context, '/signin');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header Profil ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [AppColors.darkCard, AppColors.darkSurface]
                      : [Colors.blue.shade50, Colors.white],
                ),
                border: Border(
                    bottom: BorderSide(color: AppColors.darkBorder)),
              ),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.darkBorder,
                        backgroundImage: _newPhotoFile != null
                            ? FileImage(_newPhotoFile!) as ImageProvider
                            : (photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null),
                        child: (photoUrl.isEmpty && _newPhotoFile == null)
                            ? const Icon(Icons.person_rounded,
                                size: 48, color: Colors.white38)
                            : null,
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickPhoto,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 16, color: Colors.black),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (!_isEditing) ...[
                    // Tampilan info (non-edit mode)
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(email,
                        style: const TextStyle(color: Colors.white38, fontSize: 13)),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 13, height: 1.5),
                      ),
                    ],
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _startEditing(profile, displayName),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit Profil'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ] else ...[
                    // Form edit profil
                    TextFormField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioCtrl,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Bio (maks. 150 karakter)',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.info_outline_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => setState(() {
                            _isEditing = false;
                            _newPhotoFile = null;
                          }),
                          child: const Text('Batal'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _saving ? null : _saveProfile,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.black))
                              : const Icon(Icons.save_rounded, size: 16),
                          label: const Text('Simpan'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── Posting Saya ─────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const Text(
                    'Posting Saya',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.sports_esports_rounded,
                      size: 18, color: AppColors.primary),
                ],
              ),
            ),

            StreamBuilder<List<GameReview>>(
              stream: reviewService.streamUserReviews(auth.user!.uid),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reviews = snap.data ?? [];
                if (reviews.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Kamu belum pernah memposting review.\nMulai sekarang!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.35)),
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: reviews.length,
                  itemBuilder: (ctx, i) {
                    final r = reviews[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DetailScreen(review: r)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: r.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  Container(color: AppColors.darkBorder),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.darkBorder,
                                child: const Icon(Icons.broken_image_outlined,
                                    color: Colors.white24),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                color: Colors.black.withOpacity(0.65),
                                child: Text(
                                  r.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
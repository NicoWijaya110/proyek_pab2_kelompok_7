import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../models/game_review.dart';
import '../../providers/auth_provider.dart';
import '../../services/review_service.dart';
import '../../services/storage_service.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _reviewCtrl = TextEditingController();

  Uint8List? _imageBytes;
  bool _pickingImage = false;
  String _selectedGenre = 'Action';
  double _rating = 4.0;
  bool _submitting = false;
  bool _gettingLocation = false;
  Position? _position;
  String? _locationName;

  final List<String> _genres = [
    'Action',
    'RPG',
    'Adventure',
    'Sports',
    'Strategy',
    'Horror',
    'Other',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    final canUseCamera = !kIsWeb;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (canUseCamera)
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Batal'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _pickingImage = true);
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (xFile != null) {
        final bytes = await xFile.readAsBytes();
        setState(() => _imageBytes = bytes);
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  // removed unused static map helper

  Future<void> _openMapExternal(Position position) async {
    final mapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}');
    if (await canLaunchUrl(mapsUrl)) {
      await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuka peta')));
    }
  }

  Future<void> _getLocation() async {
    setState(() => _gettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('GPS tidak aktif');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Izin lokasi permanen ditolak. Buka pengaturan browser/OS dan aktifkan izin lokasi.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String? name;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        final place = placemarks.first;
        name = '${place.subLocality ?? ''}, ${place.locality ?? ''}'.trim();
      } catch (_) {
        name = null;
      }

      setState(() {
        _position = position;
        _locationName = name?.isNotEmpty == true
            ? name
            : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mendapat lokasi: $e')));
      }
    } finally {
      setState(() => _gettingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
      if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih gambar cover game terlebih dahulu'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();

    try {
      if (auth.user == null) throw Exception('Belum login. Silakan masuk terlebih dahulu.');

      // Upload image to Firebase Storage
      print('DEBUG: starting image upload (${_imageBytes!.lengthInBytes} bytes)');
      String imageUrl;
      try {
        imageUrl = await StorageService().uploadReviewImage(
          bytes: _imageBytes!,
          userId: auth.user!.uid,
        );
        print('DEBUG: upload finished, url=$imageUrl');
      } catch (e) {
        print('DEBUG: upload failed: $e');
        // show detailed error and stop
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload gambar: $e')));
        rethrow;
      }

      // Prepare review and save to Firestore
      final review = GameReview(
        id: '',
        title: _titleCtrl.text.trim(),
        reviewText: _reviewCtrl.text.trim(),
        genre: _selectedGenre,
        rating: _rating,
        imageUrl: imageUrl,
        userId: auth.user!.uid,
        userName: auth.user!.displayName ?? 'Anonim',
        userPhotoUrl: auth.user!.photoURL ?? '',
        createdAt: DateTime.now(),
        latitude: _position?.latitude,
        longitude: _position?.longitude,
        locationName: _locationName,
      );

      try {
        print('DEBUG: saving review to firestore');
        await ReviewService().addReview(review);
        print('DEBUG: review saved');
      } catch (e) {
        print('DEBUG: save failed: $e');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan review: $e')));
        rethrow;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review berhasil diposting! 🎮'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // final fallback error message already shown above where possible
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal posting: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Baru'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text(
                    'KIRIM',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image Picker ─────────────────────────────────────
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _imageBytes != null
                              ? AppColors.primary
                              : AppColors.darkBorder,
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: AppColors.primary.withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tambahkan Cover Game',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pilih dari galeri atau kamera',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (_pickingImage)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Genre Chips ──────────────────────────────────────
              const Text(
                'Genre',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _genres.map((g) {
                  final selected = _selectedGenre == g;
                  return ChoiceChip(
                    label: Text(g),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedGenre = g),
                    selectedColor: AppColors.genreColor(
                      g,
                    ).withValues(alpha: 0.3),
                    side: BorderSide(
                      color: selected
                          ? AppColors.genreColor(g)
                          : Colors.transparent,
                    ),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.genreColor(g)
                          : Colors.white60,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Star Rating ──────────────────────────────────────
              const Text(
                'Rating',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => GestureDetector(
                      onTap: () => setState(() => _rating = (i + 1).toDouble()),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          i < _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 36,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${_rating.toInt()} / 5',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Game Title ───────────────────────────────────────
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Judul Game',
                  prefixIcon: Icon(Icons.gamepad_rounded),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Judul tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 14),

              // ── Review Text ──────────────────────────────────────
              TextFormField(
                controller: _reviewCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Tulis reviewmu di sini...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.edit_note_rounded),
                  ),
                ),
                validator: (v) => (v == null || v.length < 10)
                    ? 'Review min 10 karakter'
                    : null,
              ),
              const SizedBox(height: 20),

              // ── Lokasi GPS ───────────────────────────────────────
              const Text(
                'Lokasi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _gettingLocation ? null : _getLocation,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _position != null
                          ? AppColors.primary
                          : AppColors.darkBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _position != null
                                ? Icons.location_on_rounded
                                : Icons.my_location_rounded,
                            color: _position != null
                                ? AppColors.primary
                                : Colors.white38,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _gettingLocation
                                ? const Text(
                                    'Mendapatkan lokasi...',
                                    style: TextStyle(color: AppColors.primary),
                                  )
                                : Text(
                                    _position != null
                                        ? '${_locationName ?? 'Lokasi ditemukan'}\n'
                                              '${_position!.latitude.toStringAsFixed(6)}, '
                                              '${_position!.longitude.toStringAsFixed(6)}'
                                        : 'Dapatkan lokasi GPS saat ini',
                                    style: TextStyle(
                                      color: _position != null
                                          ? Colors.white
                                          : Colors.white38,
                                      height: 1.5,
                                    ),
                                  ),
                          ),
                          if (_gettingLocation)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                      if (_position != null) ...[
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GestureDetector(
                            onTap: () => _openMapExternal(_position!),
                            child: SizedBox(
                              height: 180,
                              child: FlutterMap(
                                options: MapOptions(
                                  center: LatLng(_position!.latitude, _position!.longitude),
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
                                        point: LatLng(_position!.latitude, _position!.longitude),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
    );
  }
}

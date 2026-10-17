import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/secure_storage_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../logic/blocs/profile/profile_bloc.dart';
import '../../../logic/blocs/profile/profile_event.dart';
import '../../../logic/blocs/profile/profile_state.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/services/image_picker_service.dart';
import '../../../data/models/vibe_photo_item.dart';
import '../../widgets/vibe_duration_picker_modal.dart';
import '../../../core/utils/constants.dart';
import '../../../services/api_service.dart';
import 'edit_profile_screen.dart';
import 'widgets/profile_sliver_app_bar.dart';
import 'widgets/profile_soul_id_card.dart';
import 'widgets/profile_soul_stats_card.dart';
import 'widgets/profile_face_lock_card.dart';
import 'widgets/profile_action_buttons.dart';
import 'widgets/profile_share_card_modal.dart';
import 'widgets/profile_hobbies_section.dart';
import 'widgets/profile_vibe_corner.dart';
import 'widgets/profile_personality_chart.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const ProfileScreen({super.key, this.onMenuTap});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _cachedName;
  String? _cachedAvatar;
  String? _cachedUserId;
  String? _cachedMood;
  String? _cachedMoodIcon;
  String? _cachedHertz;
  String? _cachedVibe;
  String? _cachedSignal;
  String? _cachedHandle;
  String? _cachedAddress;
  String? _cachedDob;
  String? _cachedGender;
  String? _cachedTagline;
  List<VibePhotoItem> _cachedVibes = [];
  bool _isFaceLocked = false;

  @override
  void initState() {
    super.initState();
    _loadLocalCache();
    context.read<ProfileBloc>().add(LoadProfileEvent(context));
  }

  Future<void> _loadLocalCache() async {
    final name = await SecureStorageHelper.read('userName');
    final avatar = await SecureStorageHelper.read('avatarUrl');
    final userId = await SecureStorageHelper.read('userId');
    final handle = await SecureStorageHelper.read('userHandle');

    final prefs = await SharedPreferences.getInstance();
    final mood = prefs.getString('user_frequency_mood');
    final icon = prefs.getString('user_frequency_icon');
    final hertz = prefs.getString('user_frequency_hertz');
    final vibe = prefs.getString('user_frequency_vibe');
    final signal = prefs.getString('user_frequency_signal');
    final locked = prefs.getBool('is_face_locked') ?? false;
    final prefHandle = prefs.getString('user_handle');
    final address = prefs.getString('user_address');
    final dob = prefs.getString('user_dob');
    final gender = prefs.getString('user_gender');
    final tagline = prefs.getString('user_tagline');

    final rawVibes = prefs.getStringList('user_vibe_photos') ?? [];
    final parsedVibes = rawVibes.map((e) => VibePhotoItem.fromRaw(e)).toList();
    final activeVibes = VibePhotoItem.filterActive(parsedVibes);
    if (activeVibes.length != rawVibes.length) {
      prefs.setStringList(
        'user_vibe_photos',
        activeVibes.map((e) => e.toRawString()).toList(),
      );
    }

    if (mounted) {
      setState(() {
        _cachedName = name;
        _cachedAvatar = avatar;
        _cachedUserId = userId;
        _cachedMood = mood;
        _cachedMoodIcon = icon;
        _cachedHertz = hertz;
        _cachedVibe = vibe;
        _cachedSignal = signal;
        _cachedHandle = prefHandle ?? handle;
        _cachedAddress = address;
        _cachedDob = dob;
        _cachedGender = gender;
        _cachedTagline = tagline;
        _cachedVibes = activeVibes;
        _isFaceLocked = locked;
      });
    }
  }

  Future<void> _toggleFaceLock(bool value) async {
    setState(() => _isFaceLocked = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_face_locked', value);
    if (mounted) {
      if (value) {
        ToastUtil.showWarning(context, 'Đã BẬT Khóa diện mạo cá nhân');
      } else {
        ToastUtil.showSuccess(context, 'Đã TẮT Khóa diện mạo cá nhân');
      }
    }
  }

  Future<void> _addVibePhotosDirectly() async {
    if (_cachedVibes.length >= 6) {
      ToastUtil.showWarning(
        context,
        'Bạn đã đăng tối đa 6 ảnh trong Góc tâm hồn',
      );
      return;
    }
    final newImages = await ImagePickerService.pickMultiVibeImages(
      context,
      maxImages: 6 - _cachedVibes.length,
    );
    if (newImages.isEmpty || !mounted) return;

    final selectedOption = await VibeDurationPickerModal.show(
      context,
      photoCount: newImages.length,
      initialOption: VibeDurationOption.twentyFourHours,
    );
    if (selectedOption == null || !mounted) return;

    ToastUtil.showInfo(
      context,
      'Đang tải ${newImages.length} ảnh lên Đám mây Cloudinary...',
    );

    final List<VibePhotoItem> newItems = [];
    for (final img in newImages) {
      String finalUrl = img;
      try {
        final uploaded = await ImagePickerService.uploadToCloudinary(
          context,
          img,
          folder: 'fatelink/vibes',
        );
        if (uploaded != null && uploaded.isNotEmpty) {
          finalUrl = uploaded;
        }
      } catch (_) {}

      newItems.add(
        VibePhotoItem.createNew(imageUrl: finalUrl, option: selectedOption),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _cachedVibes.addAll(newItems);
      });
    }
    await prefs.setStringList(
      'user_vibe_photos',
      _cachedVibes.map((e) => e.toRawString()).toList(),
    );

    // Đồng bộ lên backend MongoDB
    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (token != null && token.isNotEmpty && mounted) {
        final url = '${AppConstants.baseUrl}/${AppConstants.updateUserProfile}';
        await ApiService.post(
          url,
          context,
          body: {'vibePhotos': _cachedVibes.map((e) => e.toJson()).toList()},
          token: token,
          showLoading: false,
        );
      }
    } catch (_) {}

    if (mounted) {
      ToastUtil.showSuccess(
        context,
        'Đã lưu ${newItems.length} ảnh (${selectedOption.label}) trên Góc tâm hồn ✨',
      );
    }
  }

  Future<void> _deleteVibePhoto(VibePhotoItem item) async {
    setState(() {
      _cachedVibes.removeWhere(
        (p) => p.id == item.id || p.imageUrl == item.imageUrl,
      );
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'user_vibe_photos',
      _cachedVibes.map((e) => e.toRawString()).toList(),
    );

    // Đồng bộ danh sách sau khi xóa lên backend
    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (token != null && token.isNotEmpty && mounted) {
        final url = '${AppConstants.baseUrl}/${AppConstants.updateUserProfile}';
        await ApiService.post(
          url,
          context,
          body: {'vibePhotos': _cachedVibes.map((e) => e.toJson()).toList()},
          token: token,
          showLoading: false,
        );
      }
    } catch (_) {}

    if (mounted) {
      ToastUtil.showInfo(context, 'Đã xóa ảnh khỏi Góc tâm hồn');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6366F1); // Indigo
    const Color backgroundColor = Color(0xFFF8FAFC); // Slate Canvas

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background ambient gradient mesh mượt mà (Loại bỏ BackdropFilter tràn viền gây vệt vuông)
          Positioned(
            top: -90,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEC4899).withValues(alpha: 0.12),
                    const Color(0xFFEC4899).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 140,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.10),
                    primaryColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main Profile Content
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              Map<String, dynamic> data = {};
              if (state is ProfileLoaded) {
                data = state.profileData;
              }

              // Extract real data with fallback to cached preferences
              final name =
                  data['name'] ?? data['displayName'] ?? _cachedName ?? 'Bạn';
              final avatar =
                  (data['avatar'] != null &&
                      data['avatar'].toString().isNotEmpty)
                  ? data['avatar'].toString()
                  : (_cachedAvatar != null && _cachedAvatar!.isNotEmpty)
                  ? _cachedAvatar!
                  : 'https://api.dicebear.com/7.x/adventurer/png?seed=${Uri.encodeComponent(name)}&backgroundColor=e0e7ff';
              final mood =
                  data['latestEmotion'] ??
                  data['mood'] ??
                  _cachedMood ??
                  'Bình yên';
              final moodIcon = data['moodIcon'] ?? _cachedMoodIcon ?? '✨';
              final frequency =
                  data['frequencyHertz'] ?? _cachedHertz ?? '639 Hz';
              final bio =
                  data['bio'] ??
                  data['desiredVibe'] ??
                  _cachedVibe ??
                  'Đang tìm kiếm tần số đồng điệu trong thế giới ồn ào này.';
              final userId =
                  data['id'] ?? data['_id'] ?? _cachedUserId ?? 'USER';
              final soulId =
                  '#${userId.length >= 6 ? userId.substring(userId.length - 6).toUpperCase() : "SOUL"}_ID';

              List<String> tags = [];
              if (data['tags'] is List && (data['tags'] as List).isNotEmpty) {
                tags = (data['tags'] as List).map((e) => e.toString()).toList();
              } else if (_cachedSignal != null && _cachedSignal!.isNotEmpty) {
                tags = [_cachedSignal!];
              }

              final emotions = data['emotions'] as Map<String, dynamic>?;

              final likesCount = (data['likesReceived'] is num)
                  ? (data['likesReceived'] as num).toInt()
                  : ((data['likesCount'] is num)
                      ? (data['likesCount'] as num).toInt()
                      : 0);

              final viewsCount = (data['profileViews'] is num)
                  ? (data['profileViews'] as num).toInt()
                  : ((data['matchedCount'] is num)
                      ? (data['matchedCount'] as num).toInt()
                      : 0);

              final handle =
                  _cachedHandle ?? '@${name.toLowerCase().replaceAll(' ', '')}';
              final displayBio =
                  (_cachedTagline != null && _cachedTagline!.isNotEmpty)
                      ? _cachedTagline!
                      : bio;

              List<VibePhotoItem> allVibes;
              final rawVibePhotos = data['vibePhotos'] as List<dynamic>?;
              if (rawVibePhotos != null && rawVibePhotos.isNotEmpty) {
                final parsed = rawVibePhotos
                    .map((e) => VibePhotoItem.fromRaw(e.toString()))
                    .toList();
                allVibes = VibePhotoItem.filterActive(parsed);
              } else {
                allVibes = _cachedVibes;
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  ProfileSliverAppBar(onMenuTap: widget.onMenuTap),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: ResponsiveCenter(
                        maxWidth: 600,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            ProfileSoulIdCard(
                              name: name,
                              avatar: avatar,
                              soulId: soulId,
                              mood: mood,
                              moodIcon: moodIcon,
                              frequency: frequency,
                              bio: displayBio,
                              handle: handle,
                              address: _cachedAddress,
                              dob: _cachedDob,
                              gender: _cachedGender,
                            ),
                            const SizedBox(height: 16),
                            ProfileSoulStatsCard(
                              likesCount: likesCount,
                              viewsCount: viewsCount,
                              frequency: frequency,
                            ),
                            const SizedBox(height: 20),
                            ProfileFaceLockCard(
                              isFaceLocked: _isFaceLocked,
                              onToggle: _toggleFaceLock,
                            ),
                            const SizedBox(height: 20),
                            ProfileActionButtons(
                              onEditProfile: () async {
                                final profileBloc = context.read<ProfileBloc>();
                                final currentContext = context;
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditProfileScreen(
                                      initialName: name,
                                      initialBio: bio,
                                      initialStatus: mood,
                                      initialAvatar: avatar,
                                    ),
                                  ),
                                );
                                if (result == true && mounted && currentContext.mounted) {
                                  _loadLocalCache();
                                  profileBloc.add(
                                    LoadProfileEvent(currentContext),
                                  );
                                }
                              },
                              onShareCard: () {
                                ProfileShareCardModal.show(
                                  context,
                                  name: name,
                                  handle: handle,
                                  soulId: soulId,
                                  avatar: avatar,
                                );
                              },
                            ),
                            const SizedBox(height: 28),
                            ProfileHobbiesSection(tags: tags),
                            const SizedBox(height: 28),
                            ProfileVibeCorner(
                              vibes: allVibes,
                              onAddPhotos: _addVibePhotosDirectly,
                              onDeletePhoto: _deleteVibePhoto,
                            ),
                            const SizedBox(height: 28),
                            ProfilePersonalityChart(emotions: emotions),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

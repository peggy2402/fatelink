import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../logic/blocs/profile/profile_bloc.dart';
import '../../../logic/blocs/profile/profile_event.dart';
import '../../../logic/blocs/profile/profile_state.dart';
import '../../widgets/back.dart';
import '../../../logic/blocs/main/main_bloc.dart';
import '../../../logic/blocs/main/main_event.dart';
import '../../../core/utils/toast_utils.dart';
import 'edit_profile_screen.dart';

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
  String? _cachedTagline;
  bool _isFaceLocked = false;

  @override
  void initState() {
    super.initState();
    _loadLocalCache();
    context.read<ProfileBloc>().add(LoadProfileEvent(context));
  }

  Future<void> _loadLocalCache() async {
    const secureStorage = FlutterSecureStorage();
    final name = await secureStorage.read(key: 'userName');
    final avatar = await secureStorage.read(key: 'avatarUrl');
    final userId = await secureStorage.read(key: 'userId');
    final handle = await secureStorage.read(key: 'userHandle');

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
    final tagline = prefs.getString('user_tagline');

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
        _cachedTagline = tagline;
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

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6366F1); // Indigo
    const Color backgroundColor = Color(0xFFF8FAFC); // Slate Canvas

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background ambient gradient mesh matching UserDetailScreen
          Positioned(
            top: -90,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEC4899).withValues(alpha: 0.12),
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
                color: primaryColor.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: const SizedBox(),
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

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildSoulIdCard(
                            name: name,
                            avatar: avatar,
                            soulId: soulId,
                            mood: mood,
                            moodIcon: moodIcon,
                            frequency: frequency,
                            bio: bio,
                          ),
                          const SizedBox(height: 20),
                          _buildLockedPhotoAlert(),
                          const SizedBox(height: 20),
                          _buildActionButtons(
                            name: name,
                            bio: bio,
                            status: mood,
                            avatar: avatar,
                            handle: _cachedHandle ?? '@${name.toLowerCase().replaceAll(' ', '')}',
                            soulId: soulId,
                          ),
                          const SizedBox(height: 28),
                          _buildHobbiesSection(tags),
                          const SizedBox(height: 28),
                          _buildVibeCorner(data['vibePhotos'] as List<dynamic>?),
                          const SizedBox(height: 28),
                          _buildPersonalityChart(emotions),
                          const SizedBox(height: 80),
                        ],
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white.withValues(alpha: 0.85),
      centerTitle: true,
      title: Text(
        'MyProfile'.tr(),
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: -0.2,
        ),
      ),
      leading: Center(
        child: CustomBackButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.read<MainBloc>().add(PopTabEvent());
            }
          },
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => widget.onMenuTap?.call(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: Color(0xFF1E293B),
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // A. Thẻ Soul ID Card (Điểm nhấn cá nhân đồng bộ với UserDetailScreen)
  Widget _buildSoulIdCard({
    required String name,
    required String avatar,
    required String soulId,
    required String mood,
    required String moodIcon,
    required String frequency,
    required String bio,
  }) {
    final handle = _cachedHandle ?? '@${name.toLowerCase().replaceAll(' ', '')}';
    final displayBio = (_cachedTagline != null && _cachedTagline!.isNotEmpty)
        ? _cachedTagline!
        : bio;
    final displayAddress = (_cachedAddress != null && _cachedAddress!.isNotEmpty)
        ? _cachedAddress!
        : 'Đang phát tín hiệu gần bạn';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar với viền phát sáng Gradient & Mood Badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF6366F1,
                          ).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const CircleAvatar(
                              backgroundColor: Color(0xFFE0E7FF),
                              child: Icon(
                                Icons.person,
                                color: Color(0xFF6366F1),
                                size: 40,
                              ),
                            ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        moodIcon,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Thông tin người dùng
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$handle • $soulId',
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tần số cảm xúc Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.graphic_eq_rounded,
                            size: 14,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '$frequency • $mood',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: const Color(0xFFF1F5F9), thickness: 1),
          const SizedBox(height: 12),

          // Bio & Vị trí / Ngày sinh
          Text(
            '"$displayBio"',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontStyle: FontStyle.italic,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  displayAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_cachedDob != null && _cachedDob!.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.cake_outlined,
                  size: 15,
                  color: Color(0xFFEC4899),
                ),
                const SizedBox(width: 4),
                Text(
                  _cachedDob!,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // B. Box Khóa Ảnh (Tính năng ẩn danh độc bản)
  Widget _buildLockedPhotoAlert() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isFaceLocked
              ? const Color(0xFFEC4899).withValues(alpha: 0.3)
              : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: _isFaceLocked
                ? const Color(0xFFEC4899).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isFaceLocked
                        ? [const Color(0xFFEC4899), const Color(0xFFF43F5E)]
                        : [const Color(0xFFEC4899), const Color(0xFF6366F1)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isFaceLocked
                              ? const Color(0xFFEC4899).withValues(alpha: 0.12)
                              : const Color(0xFF6366F1).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFaceLocked
                              ? Icons.lock_rounded
                              : Icons.lock_open_rounded,
                          color: _isFaceLocked
                              ? const Color(0xFFEC4899)
                              : const Color(0xFF6366F1),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isFaceLocked
                                  ? 'Khóa diện mạo cá nhân (Đang bật)'
                                  : 'Khóa diện mạo cá nhân (Đang tắt)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _isFaceLocked
                                    ? const Color(0xFFEC4899)
                                    : const Color(0xFF0F172A),
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _isFaceLocked
                                  ? '🔒 Đang ẩn danh: Người khác sẽ KHÔNG THỂ xem Tên thật, Avatar và Vibes của bạn kể cả khi hai người đã theo dõi nhau.'
                                  : '✨ Mặc định: Avatar, Tên thật & Vibes sẽ tự động mở khóa ngay khi cả hai người cùng thả tim / theo dõi nhau.',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isFaceLocked,
                        activeTrackColor: const Color(0xFFEC4899),
                        onChanged: (val) => _toggleFaceLock(val),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // C. Nút Hành Động
  Widget _buildActionButtons({
    required String name,
    required String bio,
    required String status,
    required String avatar,
    required String handle,
    required String soulId,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    initialName: name,
                    initialBio: bio,
                    initialStatus: status,
                    initialAvatar: avatar,
                  ),
                ),
              );
              if (result == true && mounted) {
                _loadLocalCache();
                context.read<ProfileBloc>().add(LoadProfileEvent(context));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
            label: const Text(
              'Chỉnh sửa hồ sơ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 50,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.share_rounded,
              color: Color(0xFF475569),
              size: 18,
            ),
            onPressed: () {
              _showShareSoulCardModal(
                context,
                name: name,
                handle: handle,
                soulId: soulId,
                avatar: avatar,
              );
            },
          ),
        ),
      ],
    );
  }

  void _showShareSoulCardModal(
    BuildContext context, {
    required String name,
    required String handle,
    required String soulId,
    required String avatar,
  }) {
    final cleanHandle = handle.startsWith('@') ? handle.substring(1) : handle;
    final profileUrl = 'https://meyu.com/m/@$cleanHandle';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        final bottomInset = MediaQuery.paddingOf(bottomSheetContext).bottom;
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset > 0 ? bottomInset + 16 : 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              // Thanh kéo
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Danh thiếp Meyu Soul',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Quét mã QR để đồng điệu tần số cùng tôi',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),

              // Card danh thiếp
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header avatar + name
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                            ),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              avatar,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const CircleAvatar(
                                backgroundColor: Color(0xFFE0E7FF),
                                child: Icon(Icons.person, color: Color(0xFF6366F1)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@$cleanHandle • $soulId',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Mã QR 2D
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
                      ),
                      child: QrImageView(
                        data: profileUrl,
                        version: QrVersions.auto,
                        size: 160.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0F172A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.circle,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // URL Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.link_rounded, color: Color(0xFF6366F1), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'meyu.com/m/@$cleanHandle',
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Nút Sao chép liên kết
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: profileUrl));
                    Navigator.pop(bottomSheetContext);
                    ToastUtil.showSuccess(context, 'Đã sao chép liên kết: meyu.com/m/@$cleanHandle ✨');
                  },
                  icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Sao chép liên kết danh thiếp',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
  }

  // D. Những Mảnh Ghép (Gu sống & Sở thích)
  Widget _buildHobbiesSection(List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.tag_rounded, color: Color(0xFFEC4899), size: 20),
            SizedBox(width: 6),
            Text(
              'Những mảnh ghép (Gu sống)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tags.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.style_outlined, color: Color(0xFF94A3B8), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chưa có mảnh ghép sở thích nào. Chạm "Chỉnh sửa hồ sơ" để thêm gu sống.',
                    style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // E. Góc Tâm Hồn (Vibe Gallery)
  Widget _buildVibeCorner(List<dynamic>? vibePhotos) {
    final realVibes = vibePhotos?.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.camera_alt_rounded, color: Color(0xFF6366F1), size: 20),
            SizedBox(width: 6),
            Text(
              'Góc tâm hồn (Vibe)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Lưu giữ những khoảnh khắc không lộ mặt mang cảm xúc riêng.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        if (realVibes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  ),
                  child: const Center(
                    child: Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF6366F1), size: 26),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Chưa có khoảnh khắc Vibe nào',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chia sẻ những bức ảnh không lộ mặt thể hiện góc tâm hồn của bạn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              children: [
                ...realVibes.map((url) => _buildVibeImageCard(url)),
                _buildAddVibeCard(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVibeImageCard(String imageUrl) {
    return Container(
      width: 105,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(imageUrl, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildAddVibeCard() {
    return Container(
      width: 105,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_rounded, size: 28, color: Color(0xFF94A3B8)),
          SizedBox(height: 4),
          Text(
            'Thêm Vibe',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // F. Chiều Sâu Tâm Lý (Emotion Vector từ AI Backend)
  Widget _buildPersonalityChart(Map<String, dynamic>? emotions) {
    final double calmness =
        ((emotions?['calmness'] ?? 7) as num).toDouble() / 10.0;
    final double warmth = ((emotions?['warmth'] ?? 8) as num).toDouble() / 10.0;
    final double depth =
        ((emotions?['loneliness'] ?? 6) as num).toDouble() / 10.0;
    final double positive =
        ((emotions?['happiness'] ?? 7) as num).toDouble() / 10.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF8B5CF6),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Chiều sâu tâm lý (AI Emotion Vector)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressItem(
            'Ấm áp & Chân thành',
            warmth,
            const Color(0xFFEC4899),
            const Color(0xFFFCE7F3),
          ),
          _buildProgressItem(
            'Bình yên nội tâm',
            calmness,
            const Color(0xFF10B981),
            const Color(0xFFD1FAE5),
          ),
          _buildProgressItem(
            'Chiều sâu tâm tư',
            depth,
            const Color(0xFF6366F1),
            const Color(0xFFE0E7FF),
          ),
          _buildProgressItem(
            'Tần số tích cực',
            positive,
            const Color(0xFFF59E0B),
            const Color(0xFFFEF3C7),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    String label,
    double value,
    Color mainColor,
    Color bgColor,
  ) {
    final percent = (value * 100).clamp(0, 100).toInt();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: mainColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: bgColor,
              valueColor: AlwaysStoppedAnimation<Color>(mainColor),
            ),
          ),
        ],
      ),
    );
  }
}

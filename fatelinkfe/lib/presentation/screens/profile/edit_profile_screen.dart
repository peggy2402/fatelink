import 'package:flutter/material.dart';
import '../../../core/utils/secure_storage_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/back.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/responsive/responsive.dart';
import '../home/widgets/radar_scanner_modal.dart';
import '../../../core/services/image_picker_service.dart';
import '../../widgets/cosmic_date_picker_modal.dart';
import '../../widgets/address_autocomplete_field.dart';
import '../../../data/models/vibe_photo_item.dart';
import '../../widgets/vibe_duration_picker_modal.dart';
import '../../../core/utils/constants.dart';
import '../../../services/api_service.dart';
import 'widgets/edit_profile_avatar_section.dart';
import 'widgets/edit_profile_input_field.dart';
import 'widgets/edit_profile_gender_selector.dart';
import 'widgets/edit_profile_frequency_card.dart';
import 'widgets/edit_profile_vibe_manager.dart';
import 'widgets/profile_face_lock_card.dart';

class EditProfileScreen extends StatefulWidget {
  final String? initialName;
  final String? initialBio;
  final String? initialStatus;
  final String? initialAvatar;

  const EditProfileScreen({
    super.key,
    this.initialName,
    this.initialBio,
    this.initialStatus,
    this.initialAvatar,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _handleController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _taglineController;

  bool _isSaving = false;
  bool _isFaceLocked = false;
  String _selectedGender = 'female'; // 'female', 'male', 'other'
  String _selectedMoodIcon = '✨';
  String _selectedHertz = '639 Hz';
  String _currentMoodTitle = 'Nhạc Indie';
  String? _currentAvatar;
  List<VibePhotoItem> _vibePhotos = [];

  // Quy định thời hạn chỉnh sửa
  bool _canChangeName = true;
  int _daysUntilNameChange = 0;
  String _originalName = '';

  bool _canChangeHandle = true;
  int _daysUntilHandleChange = 0;
  String _originalHandle = '';

  @override
  void initState() {
    super.initState();
    _originalName = widget.initialName ?? 'Bạn';
    _currentAvatar = widget.initialAvatar;
    _nameController = TextEditingController(text: _originalName);
    _handleController = TextEditingController(
      text: '@${_originalName.toLowerCase().replaceAll(' ', '')}',
    );
    _dobController = TextEditingController();
    _addressController = TextEditingController();
    final initialBioRaw =
        widget.initialBio ?? 'Đang tìm kiếm một kết nối định mệnh...';
    _taglineController = TextEditingController(
      text: initialBioRaw.length > 100
          ? initialBioRaw.substring(0, 100)
          : initialBioRaw,
    );

    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final savedHandle = await SecureStorageHelper.read('userHandle');
    final savedName = await SecureStorageHelper.read('userName');
    final savedAvatar = await SecureStorageHelper.read('avatarUrl');

    final prefs = await SharedPreferences.getInstance();
    final locked = prefs.getBool('is_face_locked') ?? false;
    final icon = prefs.getString('user_frequency_icon') ?? '✨';
    final hertz = prefs.getString('user_frequency_hertz') ?? '639 Hz';
    final mood = prefs.getString('user_frequency_mood') ?? 'Nhạc Indie';
    final prefHandle = prefs.getString('user_handle');
    final prefDob = prefs.getString('user_dob') ?? '';
    final prefAddress = prefs.getString('user_address') ?? '';
    final prefTagline = prefs.getString('user_tagline');
    final prefGender = prefs.getString('user_gender') ?? 'female';
    final prefVibes = prefs.getStringList('user_vibe_photos') ?? [];

    // Kiểm tra quy định thời hạn đổi tên hiển thị (30 ngày/lần)
    final lastNameChangeStr = prefs.getString('last_name_change_date');
    if (lastNameChangeStr != null) {
      final lastDate = DateTime.tryParse(lastNameChangeStr);
      if (lastDate != null) {
        final daysPassed = DateTime.now().difference(lastDate).inDays;
        if (daysPassed < 30) {
          _canChangeName = false;
          _daysUntilNameChange = 30 - daysPassed;
        }
      }
    }

    // Kiểm tra quy định thời hạn đổi mã @ (7 ngày/lần)
    final lastHandleChangeStr = prefs.getString('last_handle_change_date');
    if (lastHandleChangeStr != null) {
      final lastDate = DateTime.tryParse(lastHandleChangeStr);
      if (lastDate != null) {
        final daysPassed = DateTime.now().difference(lastDate).inDays;
        if (daysPassed < 7) {
          _canChangeHandle = false;
          _daysUntilHandleChange = 7 - daysPassed;
        }
      }
    }

    final parsedVibes = prefVibes.map((e) => VibePhotoItem.fromRaw(e)).toList();
    final activeVibes = VibePhotoItem.filterActive(parsedVibes);

    if (mounted) {
      setState(() {
        _isFaceLocked = locked;
        _selectedMoodIcon = icon;
        _selectedHertz = hertz;
        _currentMoodTitle = mood;
        _selectedGender = prefGender;
        _vibePhotos = activeVibes;

        if (savedAvatar != null && savedAvatar.isNotEmpty) {
          _currentAvatar = savedAvatar;
        }
        if (savedName != null && savedName.isNotEmpty) {
          _nameController.text = savedName;
          _originalName = savedName;
        }
        if (prefHandle != null && prefHandle.isNotEmpty) {
          _handleController.text = prefHandle.startsWith('@')
              ? prefHandle
              : '@$prefHandle';
          _originalHandle = _handleController.text;
        } else if (savedHandle != null && savedHandle.isNotEmpty) {
          _handleController.text = savedHandle.startsWith('@')
              ? savedHandle
              : '@$savedHandle';
          _originalHandle = _handleController.text;
        }
        if (prefDob.isNotEmpty) {
          _dobController.text = prefDob;
        }
        if (prefAddress.isNotEmpty) {
          _addressController.text = prefAddress;
        }
        if (prefTagline != null && prefTagline.isNotEmpty) {
          _taglineController.text = prefTagline;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  String _getZodiacSign(DateTime date) {
    final day = date.day;
    final month = date.month;
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) {
      return 'Bạch Dương ♈';
    }
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) {
      return 'Kim Ngưu ♉';
    }
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) {
      return 'Song Tử ♊';
    }
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) {
      return 'Cự Giải ♋';
    }
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) {
      return 'Sư Tử ♌';
    }
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) {
      return 'Xử Nữ ♍';
    }
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) {
      return 'Thiên Bình ♎';
    }
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) {
      return 'Bọ Cạp ♏';
    }
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
      return 'Nhân Mã ♐';
    }
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) {
      return 'Ma Kết ♑';
    }
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
      return 'Bảo Bình ♒';
    }
    return 'Song Ngư ♓';
  }

  /// Chọn ảnh đại diện từ Thư viện hoặc Camera và tải lên Cloudinary CDN
  Future<void> _pickAvatar() async {
    final newAvatar = await ImagePickerService.showImageSourceDialog(
      context,
      title: 'Cập nhật ảnh đại diện',
    );
    if (newAvatar != null && mounted) {
      setState(() {
        _currentAvatar = newAvatar;
      });
      ToastUtil.showInfo(
        context,
        'Đang tối ưu & tải ảnh đại diện lên Đám mây Cloudinary...',
      );

      final cloudUrl = await ImagePickerService.uploadToCloudinary(
        context,
        newAvatar,
        folder: 'fatelink/avatars',
      );

      if (cloudUrl != null && mounted) {
        setState(() {
          _currentAvatar = cloudUrl;
        });
        ToastUtil.showSuccess(
          context,
          'Đã tải ảnh lên Cloudinary CDN thành công! Nhớ nhấn Lưu nhé ✨',
        );
      } else if (mounted) {
        ToastUtil.showSuccess(
          context,
          'Đã chọn ảnh đại diện mới! Nhớ nhấn Lưu nhé ✨',
        );
      }
    }
  }

  /// Chọn thêm ảnh vào Góc tâm hồn (Vibes) với cơ chế tự động xóa và tải lên Cloudinary
  Future<void> _pickVibePhotos() async {
    if (_vibePhotos.length >= 6) {
      ToastUtil.showWarning(
        context,
        'Bạn đã đăng tối đa 6 ảnh trong Góc tâm hồn',
      );
      return;
    }
    final newImages = await ImagePickerService.pickMultiVibeImages(
      context,
      maxImages: 6 - _vibePhotos.length,
    );
    if (newImages.isEmpty || !mounted) return;

    // Hiển thị modal chọn thời hạn tự hủy ảnh
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

    if (mounted) {
      setState(() {
        _vibePhotos.addAll(newItems);
      });
      ToastUtil.showSuccess(
        context,
        'Đã lưu ${newItems.length} ảnh (${selectedOption.label}) trên Góc tâm hồn ✨',
      );
    }
  }

  void _removeVibePhoto(int index) {
    if (index >= 0 && index < _vibePhotos.length) {
      setState(() {
        _vibePhotos.removeAt(index);
      });
      ToastUtil.showInfo(context, 'Đã xóa ảnh khỏi Góc tâm hồn');
    }
  }

  /// Chọn ngày sinh bằng CosmicDatePickerModal hiện đại
  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    DateTime initial = DateTime(now.year - 20, 1, 1);
    final rawText = _dobController.text.trim();
    if (rawText.isNotEmpty) {
      final datePart = rawText.split(' ')[0];
      final parts = datePart.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          initial = DateTime(y, m, d);
        }
      }
    }

    final picked = await CosmicDatePickerModal.show(
      context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 14, now.month, now.day),
    );

    if (picked != null && mounted) {
      final age = now.year - picked.year;
      final zodiac = _getZodiacSign(picked);
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year} ($age tuổi • $zodiac)';
      setState(() {
        _dobController.text = formatted;
      });
    }
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    var newHandle = _handleController.text.trim();
    final newDob = _dobController.text.trim();
    final newAddress = _addressController.text.trim();
    final newTagline = _taglineController.text.trim();

    if (newName.isEmpty) {
      ToastUtil.showWarning(context, 'Tên hiển thị không được để trống');
      return;
    }

    if (newHandle.isEmpty) {
      ToastUtil.showWarning(context, 'Mã định danh không được để trống');
      return;
    }

    if (!newHandle.startsWith('@')) {
      newHandle = '@$newHandle';
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Kiểm tra xem Tên hiển thị có thay đổi không
      if (newName != _originalName) {
        if (!_canChangeName) {
          if (mounted) {
            ToastUtil.showWarning(
              context,
              'Bạn chỉ có thể đổi lại Tên hiển thị sau $_daysUntilNameChange ngày nữa.',
            );
            setState(() => _isSaving = false);
          }
          return;
        }
        await SecureStorageHelper.write('userName', newName);
        await prefs.setString('userName', newName);
        await prefs.setString(
          'last_name_change_date',
          DateTime.now().toIso8601String(),
        );
      }

      // Kiểm tra xem @handle có thay đổi không
      if (newHandle != _originalHandle) {
        if (!_canChangeHandle) {
          if (mounted) {
            ToastUtil.showWarning(
              context,
              'Bạn chỉ có thể đổi @ sau $_daysUntilHandleChange ngày nữa.',
            );
            setState(() => _isSaving = false);
          }
          return;
        }
        await SecureStorageHelper.write('userHandle', newHandle);
        await prefs.setString('user_handle', newHandle);
        await prefs.setString(
          'last_handle_change_date',
          DateTime.now().toIso8601String(),
        );
      }

      // Lưu các trường còn lại
      await prefs.setBool('is_face_locked', _isFaceLocked);
      await prefs.setString('user_gender', _selectedGender);
      await SecureStorageHelper.write('userGender', _selectedGender);
      await prefs.setString('user_dob', newDob);
      await prefs.setString('user_address', newAddress);
      await prefs.setString('user_tagline', newTagline);

      // Lưu Avatar mới nếu có
      if (_currentAvatar != null && _currentAvatar!.isNotEmpty) {
        await SecureStorageHelper.write('avatarUrl', _currentAvatar!);
        await prefs.setString('avatarUrl', _currentAvatar!);
      }

      // Lưu album Góc tâm hồn (Vibe photos) có thời hạn
      final activeVibes = VibePhotoItem.filterActive(_vibePhotos);
      await prefs.setStringList(
        'user_vibe_photos',
        activeVibes.map((e) => e.toRawString()).toList(),
      );

      // Đồng bộ thông tin lên Server Backend qua API /api/users/profile
      try {
        final token = await SecureStorageHelper.read('accessToken');
        if (token != null && token.isNotEmpty) {
          final payload = {
            'name': newName,
            'handle': newHandle,
            'avatar': _currentAvatar,
            'bio': newTagline,
            'gender': _selectedGender,
            'dateOfBirth': newDob,
            'address': newAddress,
            'isFaceLocked': _isFaceLocked,
            'vibePhotos': activeVibes.map((p) => p.toJson()).toList(),
          };
          final url =
              '${AppConstants.baseUrl}/${AppConstants.updateUserProfile}';
          if (mounted) {
            await ApiService.post(
              url,
              context,
              body: payload,
              token: token,
              showLoading: false,
            );
          }
        }
      } catch (_) {
        // Dữ liệu đã lưu thành công trong Local Cache, không cản trở flow của người dùng
      }

      if (mounted) {
        ToastUtil.showSuccess(context, 'Hồ sơ đã được lưu thành công! ✨');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showError(context, 'Không thể lưu hồ sơ, vui lòng thử lại');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarSource = (_currentAvatar != null && _currentAvatar!.isNotEmpty)
        ? _currentAvatar!
        : (widget.initialAvatar != null && widget.initialAvatar!.isNotEmpty)
        ? widget.initialAvatar!
        : 'https://api.dicebear.com/7.x/adventurer/png?seed=${Uri.encodeComponent(_nameController.text.isNotEmpty ? _nameController.text : "User")}&backgroundColor=f3e8ff';

    final cleanPreviewHandle = _handleController.text.replaceAll('@', '');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(6.0),
          child: CustomBackButton(),
        ),
        title: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6366F1),
                    ),
                  )
                : const Text(
                    'Lưu',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: ResponsiveCenter(
          maxWidth: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Avatar Center
              EditProfileAvatarSection(
                avatarSource: avatarSource,
                onPickAvatar: _pickAvatar,
              ),
              const SizedBox(height: 18),

              // 2. Tên hiển thị (Display Name) - Quy định 30 ngày/lần
              EditProfileInputField(
                label: 'Tên hiển thị',
                hintText: 'Nhập tên của bạn...',
                controller: _nameController,
                icon: Icons.person_outline_rounded,
                isReadOnly: !_canChangeName,
                helperText: !_canChangeName
                    ? '🔒 Bạn chỉ có thể đổi lại Tên hiển thị sau $_daysUntilNameChange ngày nữa (quy định 30 ngày/lần).'
                    : '💡 Tên hiển thị được phép thay đổi 30 ngày một lần.',
                trailing: !_canChangeName
                    ? const Icon(
                        Icons.lock_rounded,
                        color: Color(0xFFF59E0B),
                        size: 18,
                      )
                    : null,
              ),
              const SizedBox(height: 20),

              // 3. Mã định danh (@username) - Quy định 7 ngày/lần
              EditProfileInputField(
                label: 'Mã định danh liên kết (@username)',
                hintText: '@username',
                controller: _handleController,
                icon: Icons.alternate_email_rounded,
                isReadOnly: !_canChangeHandle,
                helperText: !_canChangeHandle
                    ? '🔒 Bạn chỉ có thể đổi lại @ sau $_daysUntilHandleChange ngày nữa (quy định 7 ngày/lần).'
                    : '💡 Liên kết chia sẻ của bạn: meyu.com/m/@$cleanPreviewHandle (chỉ được đổi 7 ngày một lần).',
                trailing: !_canChangeHandle
                    ? const Icon(
                        Icons.lock_rounded,
                        color: Color(0xFFF59E0B),
                        size: 18,
                      )
                    : null,
              ),
              const SizedBox(height: 20),

              // 3.5 Giới tính (Gender selector)
              EditProfileGenderSelector(
                selectedGender: _selectedGender,
                onGenderChanged: (val) => setState(() => _selectedGender = val),
              ),
              const SizedBox(height: 20),

              // 4. Ngày sinh (Date of birth - Hiện đại với CosmicDatePickerModal)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ngày sinh',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDateOfBirth,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _dobController,
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.cake_outlined,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                          hintText: 'Chọn ngày sinh của bạn...',
                          hintStyle: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            color: Color(0xFF94A3B8),
                            fontSize: 13.5,
                          ),
                          suffixIcon: const Icon(
                            Icons.calendar_today_rounded,
                            color: Color(0xFF6366F1),
                            size: 18,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF6366F1),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 5. Địa chỉ / Nơi sống (Tích hợp AddressKit Autocomplete Highlight Vàng)
              AddressAutocompleteField(
                controller: _addressController,
                label: 'Địa chỉ / Khu vực sinh sống',
                hintText: 'VD: Hà Nội, TP.HCM, Đà Nẵng...',
                onAddressSelected: (val) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),

              // 6. Tagline / Châm ngôn sống (Giới hạn tối đa 100 ký tự)
              EditProfileInputField(
                label: 'Châm ngôn sống (Tagline / Bio)',
                hintText: 'VD: "Đang tìm kiếm một kết nối định mệnh..."',
                controller: _taglineController,
                icon: Icons.format_quote_rounded,
                maxLines: 2,
                maxLength: 100,
                showCounter: true,
                helperText:
                    'Tối đa 100 ký tự để giữ trọn vẹn thông điệp tinh tế.',
              ),
              const SizedBox(height: 24),

              // 6.5 --- GÓC TÂM HỒN (VIBE PHOTOS) ---
              EditProfileVibeManager(
                vibePhotos: _vibePhotos,
                onPickVibePhotos: _pickVibePhotos,
                onRemoveVibePhoto: _removeVibePhoto,
              ),
              const SizedBox(height: 24),

              // 7. --- TẦN SỐ NĂNG LƯỢNG ĐO LƯỜNG THỰC TẾ ---
              EditProfileFrequencyCard(
                selectedMoodIcon: _selectedMoodIcon,
                selectedHertz: _selectedHertz,
                currentMoodTitle: _currentMoodTitle,
                onScanRadar: () {
                  RadarScannerModal.show(
                    context,
                    onConnectMatch: () =>
                        Navigator.of(context).pushNamed('/matches'),
                  );
                },
              ),
              const SizedBox(height: 24),

              // 8. --- TÍNH NĂNG: CÔNG TẮC KHÓA DIỆN MẠO CÁ NHÂN ---
              ProfileFaceLockCard(
                isFaceLocked: _isFaceLocked,
                onToggle: (val) => setState(() => _isFaceLocked = val),
              ),
              const SizedBox(height: 32),

              // 9. Nút Lưu
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

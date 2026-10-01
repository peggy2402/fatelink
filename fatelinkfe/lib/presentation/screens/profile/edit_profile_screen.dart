import 'package:flutter/material.dart';
import '../../../core/utils/secure_storage_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/back.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/responsive/responsive.dart';
import '../home/widgets/radar_scanner_modal.dart';

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
  String _selectedMoodIcon = '✨';
  String _selectedHertz = '639 Hz';
  String _currentMoodTitle = 'Nhạc Indie';

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
    _nameController = TextEditingController(text: _originalName);
    _handleController = TextEditingController(
      text: '@${_originalName.toLowerCase().replaceAll(' ', '')}',
    );
    _dobController = TextEditingController();
    _addressController = TextEditingController();
    _taglineController = TextEditingController(
      text: widget.initialBio ?? 'Đang tìm kiếm một kết nối định mệnh...',
    );

    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final savedHandle = await SecureStorageHelper.read('userHandle');
    final savedName = await SecureStorageHelper.read('userName');

    final prefs = await SharedPreferences.getInstance();
    final locked = prefs.getBool('is_face_locked') ?? false;
    final icon = prefs.getString('user_frequency_icon') ?? '✨';
    final hertz = prefs.getString('user_frequency_hertz') ?? '639 Hz';
    final mood = prefs.getString('user_frequency_mood') ?? 'Nhạc Indie';
    final prefHandle = prefs.getString('user_handle');
    final prefDob = prefs.getString('user_dob') ?? '';
    final prefAddress = prefs.getString('user_address') ?? '';
    final prefTagline = prefs.getString('user_tagline');

    // Kiểm tra quy định thời hạn đổi tên hiển thị (30 ngày/lần)
    final lastNameChangeStr = prefs.getString('last_name_change_date');
    if (lastNameChangeStr != null) {
      final lastDate = DateTime.tryParse(lastNameChangeStr);
      if (lastDate != null) {
        final diff = DateTime.now().difference(lastDate).inDays;
        if (diff < 30) {
          _canChangeName = false;
          _daysUntilNameChange = 30 - diff;
        }
      }
    }

    // Kiểm tra quy định thời hạn đổi @handle (7 ngày/lần)
    final lastHandleChangeStr = prefs.getString('last_handle_change_date');
    if (lastHandleChangeStr != null) {
      final lastDate = DateTime.tryParse(lastHandleChangeStr);
      if (lastDate != null) {
        final diff = DateTime.now().difference(lastDate).inDays;
        if (diff < 7) {
          _canChangeHandle = false;
          _daysUntilHandleChange = 7 - diff;
        }
      }
    }

    if (mounted) {
      setState(() {
        if (savedName != null && savedName.isNotEmpty) {
          _originalName = savedName;
          _nameController.text = savedName;
        }
        final finalHandle = prefHandle ?? savedHandle ?? '@${_originalName.toLowerCase().replaceAll(' ', '')}';
        _originalHandle = finalHandle.startsWith('@') ? finalHandle : '@$finalHandle';
        _handleController.text = _originalHandle;

        _isFaceLocked = locked;
        _selectedMoodIcon = icon;
        _selectedHertz = hertz;
        _currentMoodTitle = mood;
        _dobController.text = prefDob;
        _addressController.text = prefAddress;
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
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Bạch Dương ♈';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Kim Ngưu ♉';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'Song Tử ♊';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'Cự Giải ♋';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Sư Tử ♌';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Xử Nữ ♍';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Thiên Bình ♎';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'Bọ Cạp ♏';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 'Nhân Mã ♐';
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return 'Ma Kết ♑';
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Bảo Bình ♒';
    return 'Song Ngư ♓';
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 20, 1, 1);
    final firstDate = DateTime(1940);
    final lastDate = DateTime(now.year - 14, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'CHỌN NGÀY SINH CỦA BẠN',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final age = now.year - picked.year;
      final zodiac = _getZodiacSign(picked);
      final formatted = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {
        _dobController.text = '$formatted ($age tuổi • $zodiac)';
      });
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final newName = _nameController.text.trim();
      var rawHandle = _handleController.text.trim().replaceAll('@', '').toLowerCase().replaceAll(' ', '');
      if (rawHandle.isEmpty) {
        rawHandle = newName.toLowerCase().replaceAll(' ', '');
      }
      final newHandle = '@$rawHandle';
      final newDob = _dobController.text.trim();
      final newAddress = _addressController.text.trim();
      final newTagline = _taglineController.text.trim();

      final prefs = await SharedPreferences.getInstance();

      // Xử lý đổi tên hiển thị
      if (newName != _originalName && newName.isNotEmpty) {
        if (!_canChangeName) {
          if (mounted) {
            ToastUtil.showWarning(context, 'Bạn chỉ có thể đổi Tên hiển thị sau $_daysUntilNameChange ngày nữa.');
            setState(() => _isSaving = false);
          }
          return;
        }
        await SecureStorageHelper.write('userName', newName);
        await prefs.setString('userName', newName);
        await prefs.setString('last_name_change_date', DateTime.now().toIso8601String());
      }

      // Xử lý đổi @handle
      if (newHandle != _originalHandle) {
        if (!_canChangeHandle) {
          if (mounted) {
            ToastUtil.showWarning(context, 'Bạn chỉ có thể đổi @ sau $_daysUntilHandleChange ngày nữa.');
            setState(() => _isSaving = false);
          }
          return;
        }
        await SecureStorageHelper.write('userHandle', newHandle);
        await prefs.setString('user_handle', newHandle);
        await prefs.setString('last_handle_change_date', DateTime.now().toIso8601String());
      }

      // Lưu các trường còn lại
      await prefs.setBool('is_face_locked', _isFaceLocked);
      await prefs.setString('user_dob', newDob);
      await prefs.setString('user_address', newAddress);
      await prefs.setString('user_tagline', newTagline);

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
    final avatarUrl = (widget.initialAvatar != null && widget.initialAvatar!.isNotEmpty)
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                  )
                : const Text(
                    'Lưu',
                    style: TextStyle(
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
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                            radius: 46,
                            backgroundColor: Color(0xFFE0E7FF),
                            child: Icon(Icons.person, color: Color(0xFF6366F1), size: 44),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: IconButton(
                        onPressed: () {
                          ToastUtil.showInfo(context, 'Tính năng chọn ảnh từ thư viện đang chuẩn bị ra mắt ✨');
                        },
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        icon: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 28),

            // 2. Tên hiển thị (Display Name) - Quy định 30 ngày/lần
            _buildInputField(
              label: 'Tên hiển thị',
              hintText: 'Nhập tên của bạn...',
              controller: _nameController,
              icon: Icons.person_outline_rounded,
              isReadOnly: !_canChangeName,
              helperText: !_canChangeName
                  ? '🔒 Bạn chỉ có thể đổi lại Tên hiển thị sau $_daysUntilNameChange ngày nữa (quy định 30 ngày/lần).'
                  : '💡 Tên hiển thị được phép thay đổi 30 ngày một lần.',
              trailing: !_canChangeName
                  ? const Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 18)
                  : null,
            ),
            const SizedBox(height: 20),

            // 3. Mã định danh (@username) - Quy định 7 ngày/lần
            _buildInputField(
              label: 'Mã định danh liên kết (@username)',
              hintText: '@username',
              controller: _handleController,
              icon: Icons.alternate_email_rounded,
              isReadOnly: !_canChangeHandle,
              helperText: !_canChangeHandle
                  ? '🔒 Bạn chỉ có thể đổi lại @ sau $_daysUntilHandleChange ngày nữa (quy định 7 ngày/lần).'
                  : '💡 Liên kết chia sẻ của bạn: meyu.com/m/@$cleanPreviewHandle (chỉ được đổi 7 ngày một lần).',
              trailing: !_canChangeHandle
                  ? const Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 18)
                  : null,
            ),
            const SizedBox(height: 20),

            // 4. Ngày sinh (Date of birth)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ngày sinh',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDateOfBirth,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _dobController,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.cake_outlined, color: Color(0xFF94A3B8), size: 20),
                        hintText: 'Chọn ngày sinh của bạn...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                        suffixIcon: const Icon(Icons.calendar_today_rounded, color: Color(0xFF6366F1), size: 18),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. Địa chỉ / Nơi sống
            _buildInputField(
              label: 'Địa chỉ / Khu vực sinh sống',
              hintText: 'VD: Hà Nội, Việt Nam',
              controller: _addressController,
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 20),

            // 6. Tagline / Châm ngôn sống
            _buildInputField(
              label: 'Châm ngôn sống (Tagline / Bio)',
              hintText: 'VD: "Đang tìm kiếm một kết nối định mệnh..."',
              controller: _taglineController,
              icon: Icons.format_quote_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // 7. --- TẦN SỐ NĂNG LƯỢNG ĐO LƯỜNG THỰC TẾ (Thay thế mockdata tĩnh) ---
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.graphic_eq_rounded, color: Color(0xFF6366F1), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tần số cảm xúc hiện tại',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_selectedMoodIcon $_selectedHertz',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Đang phát: $_currentMoodTitle',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tần số tâm hồn được hệ thống đo lường khách quan từ Trợ lý AI Faye và Radar 3 chạm theo thời gian thực (không phải cấu hình ngẫu nhiên).',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 14),

                  // Nút quét lại tần số
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        RadarScannerModal.show(
                          context,
                          onConnectMatch: () => Navigator.of(context).pushNamed('/matches'),
                        );
                      },
                      icon: const Icon(Icons.radar_rounded, color: Color(0xFF6366F1), size: 18),
                      label: const Flexible(
                        child: Text(
                          'Quét lại tần số tâm trạng (Radar 3 chạm)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.2),
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 8. --- TÍNH NĂNG: CÔNG TẮC KHÓA DIỆN MẠO CÁ NHÂN ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isFaceLocked ? const Color(0xFFEC4899).withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
                  width: _isFaceLocked ? 1.5 : 1,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isFaceLocked
                              ? const Color(0xFFEC4899).withValues(alpha: 0.12)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isFaceLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                          color: _isFaceLocked ? const Color(0xFFEC4899) : const Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Khóa diện mạo cá nhân',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _isFaceLocked ? const Color(0xFFEC4899) : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isFaceLocked ? 'Đang bật ẩn danh' : 'Mặc định: Hiện khi 2 bên cùng thả tim',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _isFaceLocked ? const Color(0xFFEC4899) : const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isFaceLocked,
                        activeTrackColor: const Color(0xFFEC4899),
                        onChanged: (val) {
                          setState(() => _isFaceLocked = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isFaceLocked
                        ? '🔒 Khi BẬT: Người khác sẽ KHÔNG THỂ nhìn thấy Tên thật, Ảnh đại diện và Góc tâm hồn (Vibes) của bạn kể cả khi cả hai đã thả tim / follow nhau. Họ chỉ kết nối qua Tần số và Chiều sâu tâm lý.'
                        : '✨ Khi TẮT: Ảnh đại diện, Tên thật và Góc tâm hồn (Vibes) sẽ tự động mở khóa ngay khi cả hai người cùng thả tim / follow nhau.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Lưu thay đổi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
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

  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    bool isReadOnly = false,
    String? helperText,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: isReadOnly,
          style: TextStyle(
            fontSize: 15,
            color: isReadOnly ? const Color(0xFF64748B) : const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixIcon: maxLines == 1 ? Icon(icon, color: isReadOnly ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8), size: 20) : null,
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
            filled: true,
            fillColor: isReadOnly ? const Color(0xFFF1F5F9) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isReadOnly ? const Color(0xFFE2E8F0) : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isReadOnly ? const Color(0xFFE2E8F0) : const Color(0xFF6366F1),
                width: isReadOnly ? 1 : 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText,
            style: TextStyle(
              fontSize: 11.5,
              color: isReadOnly ? const Color(0xFFD97706) : const Color(0xFF64748B),
              fontWeight: isReadOnly ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/utils/toast_utils.dart';

class QrHubModal extends StatefulWidget {
  final String? userName;
  final String? userHandle;
  final String? avatarUrl;

  const QrHubModal({
    super.key,
    this.userName,
    this.userHandle,
    this.avatarUrl,
  });

  static Future<void> show(
    BuildContext context, {
    String? userName,
    String? userHandle,
    String? avatarUrl,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QrHubModal(
        userName: userName,
        userHandle: userHandle,
        avatarUrl: avatarUrl,
      ),
    );
  }

  @override
  State<QrHubModal> createState() => _QrHubModalState();
}

class _QrHubModalState extends State<QrHubModal>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0; // 0: Quét mã QR, 1: Mã QR của tôi
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  bool _isFlashOn = false;
  final TextEditingController _soulIdInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _soulIdInputController.dispose();
    super.dispose();
  }

  void _onConnectManual() {
    final code = _soulIdInputController.text.trim();
    if (code.isEmpty) {
      ToastUtil.showWarning(context, 'Vui lòng nhập Soul ID hoặc mã kết nối');
      return;
    }
    Navigator.pop(context);
    ToastUtil.showSuccess(context, 'Đang dò tìm tần số tâm hồn của $code... ✨');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 16;

    final displayName = (widget.userName != null && widget.userName!.isNotEmpty)
        ? widget.userName!
        : 'Bạn';
    final handle = (widget.userHandle != null && widget.userHandle!.isNotEmpty)
        ? widget.userHandle!
        : '@meyu_user';
    final cleanHandle = handle.replaceAll('@', '');
    final qrData = 'https://meyu.com/u/@$cleanHandle';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x300F172A),
            blurRadius: 32,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Thanh kéo handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // 2. Tab switcher: Quét mã QR vs Mã QR của tôi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _buildTabItem(0, 'Quét mã QR', Icons.qr_code_scanner_rounded),
                  _buildTabItem(1, 'Mã QR của tôi', Icons.qr_code_2_rounded),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // 3. Nội dung theo Tab
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
              child: _selectedTabIndex == 0
                  ? _buildScannerTab()
                  : _buildMyQrTab(displayName, handle, qrData),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 1: GIAO DIỆN QUÉT MÃ QR ---
  Widget _buildScannerTab() {
    return Column(
      children: [
        const SizedBox(height: 6),
        const Text(
          'Đồng điệu tần số bạn bè',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Hướng camera vào mã QR để kết nối tức thì',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 18),

        // Khung quét camera mô phỏng với laser vũ trụ
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Lưới tọa độ ngầm
                Opacity(
                  opacity: 0.15,
                  child: GridPaper(
                    color: Colors.cyanAccent,
                    interval: 30,
                    divisions: 1,
                    subdivisions: 1,
                  ),
                ),

                // 4 Góc ngắm camera (Viewfinder corners)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Color(0xFF00E5FF), width: 3.5),
                                left: BorderSide(color: Color(0xFF00E5FF), width: 3.5),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Color(0xFF00E5FF), width: 3.5),
                                right: BorderSide(color: Color(0xFF00E5FF), width: 3.5),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFEC4899), width: 3.5),
                                left: BorderSide(color: Color(0xFFEC4899), width: 3.5),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFEC4899), width: 3.5),
                                right: BorderSide(color: Color(0xFFEC4899), width: 3.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tia laser quét lên xuống
                AnimatedBuilder(
                  animation: _laserAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: 40 + (_laserAnimation.value * 160),
                      left: 30,
                      right: 30,
                      child: Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFF00E5FF),
                              Color(0xFFEC4899),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Icon camera mờ ở giữa
                const Icon(
                  Icons.camera_alt_outlined,
                  size: 36,
                  color: Colors.white24,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Các nút công cụ: Đèn Flash & Chọn ảnh
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildToolButton(
              icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              label: _isFlashOn ? 'Bật đèn' : 'Tắt đèn',
              isActive: _isFlashOn,
              onTap: () {
                setState(() => _isFlashOn = !_isFlashOn);
                HapticFeedback.lightImpact();
              },
            ),
            const SizedBox(width: 16),
            _buildToolButton(
              icon: Icons.photo_library_rounded,
              label: 'Thư viện ảnh',
              isActive: false,
              onTap: () {
                ToastUtil.showInfo(context, 'Đang mở thư viện ảnh...');
              },
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Nhập mã Soul ID thủ công
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hoặc nhập Soul ID / Mã kết nối',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: TextField(
                        controller: _soulIdInputController,
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'VD: Soul#W13X8',
                          hintStyle: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                          prefixIcon: Icon(
                            Icons.tag_rounded,
                            size: 18,
                            color: Color(0xFF6366F1),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _onConnectManual,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Kết nối',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF6366F1)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive ? Colors.white : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: GIAO DIỆN MÃ QR CỦA TÔI ---
  Widget _buildMyQrTab(String name, String handle, String qrData) {
    return Column(
      children: [
        // Thẻ danh thiếp 3D chứa mã QR
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.10),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header thẻ: Avatar + Name + Handle
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFFF3E8FF),
                      backgroundImage: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                          ? NetworkImage(widget.avatarUrl!) as ImageProvider
                          : const AssetImage('assets/images/default_avatar.png'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          handle,
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '528 Hz',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Mã QR
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 180.0,
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

              // URL badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  qrData,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Các nút hành động: Lưu ảnh & Chia sẻ
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ToastUtil.showSuccess(context, 'Đã lưu mã QR vào thư viện ảnh ✨');
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Lưu mã QR'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: qrData));
                  HapticFeedback.lightImpact();
                  ToastUtil.showSuccess(context, 'Đã sao chép liên kết hồ sơ của bạn! 💕');
                },
                icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                label: const Text(
                  'Sao chép link',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

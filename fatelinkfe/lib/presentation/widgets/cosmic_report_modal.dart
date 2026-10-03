import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/secure_storage_helper.dart';
import '../../core/utils/toast_utils.dart';

/// Modal báo cáo vi phạm người dùng (CosmicReportModal)
/// - Tuân thủ phong cách thiết kế Cosmic Dark/Light thanh lịch
/// - Cung cấp đầy đủ lý do báo cáo theo tiêu chuẩn an toàn cộng đồng
/// - Hỗ trợ tùy chọn đồng thời chặn người bị báo cáo
class CosmicReportModal extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final Function(bool blocked)? onReported;

  const CosmicReportModal({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.onReported,
  });

  static Future<void> show(
    BuildContext context, {
    required String targetUserId,
    required String targetUserName,
    Function(bool blocked)? onReported,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CosmicReportModal(
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        onReported: onReported,
      ),
    );
  }

  @override
  State<CosmicReportModal> createState() => _CosmicReportModalState();
}

class _CosmicReportModalState extends State<CosmicReportModal> {
  final _detailsController = TextEditingController();
  String _selectedReason = 'harassment';
  bool _blockAlso = true;
  bool _isSubmitting = false;

  final List<Map<String, String>> _reasons = const [
    {
      'id': 'harassment',
      'label': 'Quấy rối, đe dọa hoặc làm phiền',
      'desc': 'Tin nhắn gây khó chịu, xúc phạm hoặc đe dọa an toàn',
    },
    {
      'id': 'impersonation',
      'label': 'Giả mạo danh tính',
      'desc': 'Dùng hình ảnh, tên hoặc thông tin của người khác',
    },
    {
      'id': 'scam_spam',
      'label': 'Lừa đảo hoặc phát tán spam',
      'desc': 'Gửi link độc hại, bán hàng hoặc mượn tiền',
    },
    {
      'id': 'inappropriate',
      'label': 'Hình ảnh / Nội dung nhạy cảm 18+',
      'desc': 'Ảnh hồ sơ hoặc tin nhắn khiêu dâm, không phù hợp',
    },
    {
      'id': 'hate_speech',
      'label': 'Ngôn từ thù ghét / Kích động',
      'desc': 'Phân biệt chủng tộc, tôn giáo, giới tính hoặc công kích',
    },
    {
      'id': 'other',
      'label': 'Lý do khác',
      'desc': 'Hành vi vi phạm tiêu chuẩn cộng đồng khác',
    },
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (token != null && mounted) {
        final url =
            '${AppConstants.baseUrl}/${AppConstants.userReport(widget.targetUserId)}';
        await ApiService.post(
          url,
          context,
          token: token,
          body: jsonEncode({
            'reason': _selectedReason,
            'details': _detailsController.text.trim(),
            'blockAlso': _blockAlso,
          }),
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ToastUtil.showSuccess(
          context,
          'Cảm ơn bạn. FateLink đã ghi nhận báo cáo và sẽ xử lý vi phạm trong 24h ✨',
        );
        widget.onReported?.call(_blockAlso);
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showError(
          context,
          'Gửi báo cáo thất bại. Vui lòng kiểm tra lại kết nối mạng!',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFFEF4444),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Báo cáo ${widget.targetUserName}',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Báo cáo của bạn được ẩn danh và bảo mật tuyệt đối',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade200, height: 1),

          // Danh sách lý do báo cáo
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vui lòng chọn lý do vi phạm:',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._reasons.map((r) {
                    final isSelected = _selectedReason == r['id'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedReason = r['id']!),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEF4444).withValues(alpha: 0.06)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                color: isSelected
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r['label']!,
                                      style: TextStyle(
                                        fontFamily: 'BeVietnamPro',
                                        fontSize: 13.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF991B1B)
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r['desc']!,
                                      style: const TextStyle(
                                        fontFamily: 'BeVietnamPro',
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  // Chi tiết thêm
                  const Text(
                    'Mô tả chi tiết (tùy chọn):',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _detailsController,
                    maxLines: 3,
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 13.5,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Cung cấp thêm chi tiết giúp ban quản trị xác minh nhanh hơn...',
                      hintStyle: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 12.5,
                        color: Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFF6366F1), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tùy chọn đồng thời chặn người này
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.block_rounded,
                          color: Color(0xFF475569),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Đồng thời chặn người này',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Cả hai sẽ không còn nhìn thấy nhau trên FateLink',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _blockAlso,
                          activeThumbColor: const Color(0xFFEF4444),
                          onChanged: (val) => setState(() => _blockAlso = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nút gửi báo cáo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flag_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Gửi báo cáo an toàn',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

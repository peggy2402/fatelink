import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/back.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/secure_storage_helper.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../services/api_service.dart';

class SettingsListBlockScreen extends StatefulWidget {
  const SettingsListBlockScreen({super.key});

  @override
  State<SettingsListBlockScreen> createState() => _SettingsListBlockScreenState();
}

class _SettingsListBlockScreenState extends State<SettingsListBlockScreen> {
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBlockedUsers();
  }

  /// Tải danh sách người dùng đã chặn từ Backend
  Future<void> _fetchBlockedUsers() async {
    setState(() => _isLoading = true);
    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (token != null && mounted) {
        final url = '${AppConstants.baseUrl}/${AppConstants.userBlockedList}';
        final res = await ApiService.get(url, context, token: token);
        if (res is List && mounted) {
          setState(() {
            _blockedUsers = res.map((item) {
              if (item is Map<String, dynamic>) {
                return item;
              }
              return <String, dynamic>{};
            }).toList();
          });
        }
      }
    } catch (_) {
      // Bỏ qua lỗi hoặc giữ danh sách rỗng
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Thao tác "Bỏ chặn" người dùng thật
  Future<void> _handleUnblockUser(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Bỏ chặn người dùng?',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Sau khi bỏ chặn, $name sẽ có thể tìm thấy tần số của bạn trên Radar và gửi sóng trở lại.',
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 13.5,
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Giữ chặn',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Bỏ chặn',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    HapticFeedback.lightImpact();

    try {
      final token = await SecureStorageHelper.read('accessToken');
      if (token != null && mounted) {
        final url = '${AppConstants.baseUrl}/${AppConstants.userUnblock(id)}';
        await ApiService.delete(url, context, token: token, showLoading: true);
      }
      if (mounted) {
        setState(() {
          _blockedUsers.removeWhere((u) => u['id'] == id || u['_id'] == id);
        });
        ToastUtil.showSuccess(context, 'Đã bỏ chặn $name thành công ✨');
      }
    } catch (_) {
      if (mounted) {
        ToastUtil.showError(context, 'Thao tác bỏ chặn thất bại. Vui lòng thử lại!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Danh sách chặn',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            )
          : _blockedUsers.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchBlockedUsers,
                  color: const Color(0xFF6366F1),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: _blockedUsers.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final user = _blockedUsers[index];
                      final userId = (user['id'] ?? user['_id'] ?? '').toString();
                      final userName = (user['name'] ?? 'Người dùng').toString();
                      final avatarUrl = (user['avatar'] ?? '').toString();

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFEEF2FF),
                              backgroundImage: avatarUrl.isNotEmpty &&
                                      avatarUrl.startsWith('http')
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl.isEmpty || !avatarUrl.startsWith('http')
                                  ? Text(
                                      userName.isNotEmpty
                                          ? userName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontFamily: 'BeVietnamPro',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Đã chặn tương tác',
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 12,
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => _handleUnblockUser(userId, userName),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF6366F1), width: 1.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              child: const Text(
                                'Bỏ chặn',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  color: Color(0xFF6366F1),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 48,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Bạn chưa chặn ai cả ✨',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Không gian kết nối định mệnh của bạn hoàn toàn tự do và tràn đầy năng lượng tích cực.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../../data/models/match_user.dart';
import '../../match/match_chat_screen.dart';
import '../../profile/user_detail_screen.dart';
import 'explore_list_card.dart';

/// Chế độ Lưới Tần Số (Orbit Cards View):
/// - Sử dụng ExploreListCard siêu mượt (Zero lag, 120 FPS)
/// - Hỗ trợ cacheExtent để tải trước các thẻ, loại bỏ hoàn toàn hiện tượng giật khựng
/// - Khoảng đệm đáy tính toán chính xác để không bị nút Trái tim hồng che khuất
class ExploreGridView extends StatelessWidget {
  final List<MatchUser> users;
  final Future<void> Function() onRefresh;

  const ExploreGridView({
    super.key,
    required this.users,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.sensors_off_rounded,
                  size: 36,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Không tìm thấy tần số phù hợp',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hãy thử điều chỉnh lại bộ lọc hoặc mở rộng phạm vi tìm kiếm',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFFEC4899),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(0, 6, 0, 130 + bottomPadding),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        cacheExtent: 800.0, // Tải trước các thẻ ngoài màn hình để cuộn mượt 120 FPS
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ExploreListCard(
            key: ValueKey(user.id),
            user: user,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserDetailScreen(user: user),
                ),
              );
            },
            onChat: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MatchChatScreen(
                    partnerName: user.displayName,
                    partnerId: user.id,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

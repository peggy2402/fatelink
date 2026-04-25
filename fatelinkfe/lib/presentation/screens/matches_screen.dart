import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fatelinkfe/presentation/screens/match_chat_screen.dart'; // Màn hình chat mới
import '../../logic/blocs/matches/matches_bloc.dart';
import '../../logic/blocs/matches/matches_event.dart';
import '../../logic/blocs/matches/matches_state.dart';

class MatchedUser {
  final String id;
  final String name;
  final String latestEmotion;
  final int score;

  MatchedUser({
    required this.id,
    required this.name,
    required this.latestEmotion,
    required this.score,
  });

  factory MatchedUser.fromJson(Map<String, dynamic> json) {
    return MatchedUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? json['displayName'] ?? 'Người Dấu Tên',
      latestEmotion: json['latestEmotion'] ?? 'Bí ẩn',
      // Tạm thời lấy random score từ 75-98 dựa vào ID do API /matches hiện tại chỉ trả về mảng User
      score: 75 + (json['_id'].toString().hashCode % 24),
    );
  }
}

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Khởi tạo data lần đầu thông qua BLoC
    context.read<MatchesBloc>().add(LoadMatches());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Kích hoạt load thêm khi cuộn gần đến cuối danh sách (cách 200px)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<MatchesBloc>().add(LoadMoreMatches());
    }
  }

  void _showUnmatchDialog(MatchedUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF001520),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Text(
          'Hủy ghép đôi',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Bạn có chắc chắn muốn hủy kết nối định mệnh với ${user.name} không?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Giữ lại',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Gọi sự kiện unmatch
              context.read<MatchesBloc>().add(UnmatchUserEvent(user));
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('matches_cancelled ${user.name}'.tr()),
                  backgroundColor: Colors.white.withOpacity(0.1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Hủy ghép đôi',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Nền Gradient & Blur
          Positioned(
            top: -50,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFBD114A), // Pink/Red glow
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: const SizedBox(),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Text(
                    'matches_title'.tr(),
                    style: const TextStyle(
                      fontFamily: 'serif',
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Danh sách Matches
                Expanded(
                  child: BlocBuilder<MatchesBloc, MatchesState>(
                    builder: (context, state) {
                      if (state is MatchesLoading || state is MatchesInitial) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFFBD114A)),
                        );
                      }
                      
                      if (state is MatchesError) {
                        return Center(
                          child: Text(state.message, style: const TextStyle(color: Colors.red)),
                        );
                      }
                      
                      if (state is MatchesLoaded) {
                        if (state.matches.isEmpty) {
                          return Center(
                            child: Text(
                              'no_matches'.tr(),
                              style: const TextStyle(color: Colors.white54, fontSize: 15),
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: state.matches.length + (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.matches.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(
                                  child: CircularProgressIndicator(color: Color(0xFFBD114A)),
                                ),
                              );
                            }
                            return _buildMatchItem(state.matches[index]);
                          },
                        );
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchItem(MatchedUser user) {
    return GestureDetector(
      onTap: () async {
        final shouldReload = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchChatScreen(
              partnerName: user.name,
              partnerId: user.id, // Đã fix: Truyền thêm partnerId
            ),
          ),
        );
        if (shouldReload == true) {
          context.read<MatchesBloc>().add(LoadMatches());
        }
      },
      onLongPress: () {
        _showUnmatchDialog(user);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1E88E5), width: 2),
            ),
            child: const CircleAvatar(
              radius: 26,
              backgroundImage: AssetImage('assets/images/default_avatar.png'),
            ),
          ),
          title: Text(
            user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Đang cảm thấy ${user.latestEmotion}...', // Hoặc 'feeling'.tr(args: [user.latestEmotion])
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${user.score}%',
                  style: const TextStyle(
                    color: Colors.lightBlueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

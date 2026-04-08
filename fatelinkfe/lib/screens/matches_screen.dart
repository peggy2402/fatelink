import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fatelinkfe/screens/match_chat_screen.dart'; // Màn hình chat mới
import '../utils/constants.dart';

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
  final _secureStorage = const FlutterSecureStorage();
  List<MatchedUser> _matches = [];
  bool _isLoading = true;

  // Biến phục vụ chức năng Load More (Phân trang)
  int _page = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMatches();
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
      if (!_isLoadingMore && _hasMore && !_isLoading) {
        _fetchMoreMatches();
      }
    }
  }

  Future<void> _fetchMatches() async {
    setState(() {
      _isLoading = true;
      _page = 1;
      _hasMore = true;
    });
    await _loadData();
  }

  Future<void> _fetchMoreMatches() async {
    setState(() {
      _isLoadingMore = true;
      _page++;
    });
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      if (token == null) throw Exception('Token is null');

      final parts = token.split('.');
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final userId = jsonDecode(payload)['sub'] ?? jsonDecode(payload)['id'];

      // Gọi API có truyền thêm số trang (page)
      final url = Uri.parse(
        '${AppConstants.baseUrl}/users/$userId/matches?page=$_page&limit=10',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 && mounted) {
        // FIX BUG: Tránh crash màn hình đỏ do parse JSON rỗng hoặc lỗi
        try {
          if (response.body.trim().isEmpty)
            throw Exception("Response body is empty");

          final decoded = jsonDecode(response.body);
          if (decoded is List) {
            final newMatches = decoded
                .map((json) => MatchedUser.fromJson(json))
                .toList();

            setState(() {
              if (_page == 1) {
                _matches = newMatches;
              } else {
                _matches.addAll(newMatches);
              }

              // Nếu trả về ít hơn 10 thì xem như hết dữ liệu
              if (newMatches.length < 10) _hasMore = false;

              _isLoading = false;
              _isLoadingMore = false;
            });
          }
        } catch (e) {
          debugPrint('Lỗi Parse JSON: $e');
          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
            _hasMore = false; // Ngừng load thêm khi gặp lỗi
          });
        }
      } else {
        if (mounted)
          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
          });
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách ghép đôi: $e');
      if (mounted)
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
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
              _unmatchUser(user);
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

  void _unmatchUser(MatchedUser user) {
    // TODO: Bổ sung API gọi backend để hủy ghép đôi thực sự

    // Cập nhật giao diện trước cho nhanh nhạy
    setState(() {
      _matches.removeWhere((u) => u.id == user.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('matches_cancelled ${user.name}'.tr()),
        backgroundColor: Colors.white.withOpacity(0.1),
        behavior: SnackBarBehavior.floating,
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Text(
                    'Định mệnh của bạn', // Tạm thời để nguyên, bạn có thể bọc .tr() sau: 'matches_title'.tr()
                    style: TextStyle(
                      fontFamily: 'serif',
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Danh sách Matches
                _isLoading
                    ? const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFBD114A),
                          ),
                        ),
                      )
                    : _matches.isEmpty
                    ? const Expanded(
                        child: Center(
                          child: Text(
                            'Chưa có mảnh ghép nào cùng tần số với bạn.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: _matches.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Hiển thị loading spinner ở cuối danh sách
                            if (index == _matches.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFBD114A),
                                  ),
                                ),
                              );
                            }
                            return _buildMatchItem(_matches[index]);
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
          _fetchMatches(); // Gọi lại API để làm mới danh sách nếu vừa unmatch
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

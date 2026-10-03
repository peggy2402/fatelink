import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/responsive/responsive.dart';
import '../../../data/models/match_user.dart';
import '../../../presentation/widgets/chat_input_bar.dart';
import '../../../presentation/widgets/typing_indicator.dart';
import 'match_chat_screen.dart';

// Components tách rời sạch sẽ
import 'widgets/soul_countdown_badge.dart';
import 'widgets/soul_icebreaker_box.dart';
import 'widgets/soul_mist_avatar_bar.dart';
import 'widgets/supernova_burst_dialog.dart';

/// Phòng Giao Thoa Linh Hồn 120 Giây (Soul Sanctuary 120s):
/// - Không gian trò chuyện ẩn danh thử thách định mệnh 120s
/// - Hiệu ứng Avatar Sương Mù (Mist Blur): Gương mặt mờ ảo ban đầu và tự động tan biến sương mù sau mỗi tin nhắn
/// - Thẻ câu hỏi phá băng định mệnh (Icebreaker) giúp mở lời tự nhiên
/// - Cơ chế "Double Heart Sync" (Cả hai cùng chạm tim): Bùng nổ Siêu Tân Tinh (Supernova), phá bỏ giới hạn 120s vĩnh viễn!
/// - Nếu hết 120s hoặc 1 bên rời đi: Cuộc trò chuyện tan biến vào vũ trụ (Cosmic Dissolve)
class SoulSanctuaryScreen extends StatefulWidget {
  final MatchUser partner;

  const SoulSanctuaryScreen({super.key, required this.partner});

  @override
  State<SoulSanctuaryScreen> createState() => _SoulSanctuaryScreenState();
}

class _SoulSanctuaryScreenState extends State<SoulSanctuaryScreen>
    with TickerProviderStateMixin {
  // Bộ đếm thời gian định mệnh 120s
  static const int _initialDuration = 120;
  int _remainingSeconds = _initialDuration;
  Timer? _countdownTimer;

  // Trạng thái sương mù làm mờ avatar (Mist Blur)
  double _currentBlur = 18.0;

  // Trạng thái thả tim định mệnh (Double Heart Sync)
  bool _myHeartPressed = false;
  bool _partnerHeartPressed = false;
  bool _isUnlockedForever = false;

  // Controllers
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _supernovaController;
  late AnimationController _heartPulseController;

  // Trạng thái chat & typing
  bool _isPartnerTyping = false;
  final List<_SanctuaryMessage> _messages = [];

  // Gợi ý câu hỏi phá băng
  static const List<String> _icebreakers = [
    'Nếu tối nay có thể gác lại mọi âu lo, bạn muốn đi dạo ở đâu nhất?',
    'Bài hát nào khiến bạn cảm thấy bình yên và được chữa lành nhất?',
    'Điều gì vừa xảy ra hôm nay khiến bạn mỉm cười nhẹ nhõm?',
    'Bạn thích ngắm hoàng hôn bên bờ hồ hay ngắm sao đêm trên tầng thượng?',
  ];
  late String _selectedIcebreaker;

  // Kịch bản phản hồi thông minh của đối phương
  static const List<String> _partnerReplies = [
    'Chào bạn! Thật kỳ lạ là mình cũng đang cảm thấy rất cần một khoảng lặng như vậy...',
    'Mình cũng thích cảm giác này. Nghe tần số 432Hz thật sự làm dịu đi rất nhiều mệt mỏi trong ngày.',
    'Câu trả lời của bạn làm mình thấy rất ấm áp. Hiếm khi gặp được ai đồng điệu như vậy trên mạng...',
    'Mình vừa bấm tim rồi đấy! Hy vọng chúng ta giữ được kết nối này sau 120 giây nhé ❤️',
  ];
  int _replyIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIcebreaker = _icebreakers[math.Random().nextInt(_icebreakers.length)];

    // Controller Siêu Tân Tinh (Supernova Particle Burst)
    _supernovaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Controller nhịp tim đập
    _heartPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _startCountdown();

    // Đối phương gửi lời chào mở đầu sau 1.4s
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      _addMessage(
        text: 'Xin chào! Mình vừa bắt được tần số của bạn. Thật vui vì định mệnh đã kết nối chúng ta ✨',
        isMe: false,
      );
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isUnlockedForever) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          if (_remainingSeconds == 30) {
            HapticFeedback.mediumImpact();
          } else if (_remainingSeconds <= 10 && _remainingSeconds > 0) {
            HapticFeedback.lightImpact();
          }
        } else {
          timer.cancel();
          _handleTimeOut();
        }
      });
    });
  }

  void _handleTimeOut() {
    if (_isUnlockedForever) return;
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildTimeoutDialog(),
    );
  }

  void _handleLeave() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16152B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5E97), size: 24),
            SizedBox(width: 8),
            Text(
              'Rời khỏi phòng?',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Nếu rời đi lúc này, sợi dây định mệnh 120s sẽ tan biến vào vũ trụ và không thể khôi phục lại.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Ở lại trò chuyện', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2A6D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Rời đi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _sendMessage([String? customText]) {
    final text = customText ?? _textController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.selectionClick();
    _textController.clear();
    _addMessage(text: text, isMe: true);

    // Giảm độ mờ của Avatar (sương mù tan dần)
    setState(() {
      _currentBlur = math.max(0.0, _currentBlur - 3.2);
    });

    // Đối phương phản hồi tự động
    _simulatePartnerResponse();
  }

  void _simulatePartnerResponse() {
    if (_replyIndex >= _partnerReplies.length) return;

    setState(() => _isPartnerTyping = true);

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      setState(() => _isPartnerTyping = false);

      final replyText = _partnerReplies[_replyIndex % _partnerReplies.length];
      _replyIndex++;
      _addMessage(text: replyText, isMe: false);

      // Sương mù tiếp tục tan biến
      setState(() {
        _currentBlur = math.max(0.0, _currentBlur - 3.0);
      });

      // Nếu đối phương nói đã bấm tim thì kích hoạt bên đối phương
      if (_replyIndex == 4) {
        _triggerPartnerHeart();
      }
    });
  }

  void _addMessage({required String text, required bool isMe}) {
    setState(() {
      _messages.add(_SanctuaryMessage(
        text: text,
        isMe: isMe,
        time: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onMyHeartTap() {
    if (_myHeartPressed) return;
    HapticFeedback.heavyImpact();

    setState(() {
      _myHeartPressed = true;
    });

    // Nếu đối phương chưa bấm, tự động cho đối phương phản hồi sau 2s
    if (!_partnerHeartPressed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFF2A6D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: const Row(
            children: [
              Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bạn đã gửi rung động tim ❤️ Đang chờ đối phương cùng chạm tim...',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _triggerPartnerHeart();
      });
    } else {
      _triggerSupernovaSuccess();
    }
  }

  void _triggerPartnerHeart() {
    if (_partnerHeartPressed) return;
    setState(() => _partnerHeartPressed = true);

    if (_myHeartPressed) {
      _triggerSupernovaSuccess();
    }
  }

  void _triggerSupernovaSuccess() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isUnlockedForever = true;
      _currentBlur = 0.0;
    });
    _countdownTimer?.cancel();
    _supernovaController.forward(from: 0.0);

    // Hiện modal chúc mừng kết nối định mệnh
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => SupernovaBurstDialog(
          partner: widget.partner,
          onContinue: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MatchChatScreen(
                  partnerName: widget.partner.displayName,
                  partnerId: widget.partner.id,
                ),
              ),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _supernovaController.dispose();
    _heartPulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A15),
      body: Stack(
        children: [
          // 1. Nền tinh vân chuyển màu mộng mị
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF190F2C), Color(0xFF0B0D1A), Color(0xFF05060E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 2. Hiệu ứng hạt Siêu Tân Tinh (Supernova Particle Explosion) khi cả 2 cùng tim
          AnimatedBuilder(
            animation: _supernovaController,
            builder: (context, _) {
              if (_supernovaController.value == 0.0) return const SizedBox.shrink();
              return Positioned.fill(
                child: CustomPaint(
                  painter: SupernovaPainter(progress: _supernovaController.value),
                ),
              );
            },
          ),

          // 3. Toàn bộ nội dung giao diện theo bố cục Column chuẩn mực (bám sát foot đáy)
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Header: Countdown Timer & Nút Rời Đi
                _buildHeader(),

                // Thước đo sương mù & Avatar đối phương
                SoulMistAvatarBar(
                  partner: widget.partner,
                  currentBlur: _currentBlur,
                  isUnlockedForever: _isUnlockedForever,
                ),

                // Danh sách tin nhắn & Icebreaker Card
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      // Thẻ phá băng định mệnh
                      SoulIcebreakerBox(
                        question: _selectedIcebreaker,
                        onSelectPrompt: (p) => _sendMessage(p),
                      ),
                      const SizedBox(height: 12),

                      // Danh sách tin nhắn
                      ..._messages.map((m) => _buildMessageBubble(m)),

                      // Typing Indicator của đối phương
                      if (_isPartnerTyping)
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TypingIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),

                // Thanh ChatInputBar tích hợp nút Double Heart Sync chuẩn tối
                ChatInputBar(
                  controller: _textController,
                  onSubmitted: (text) => _sendMessage(text),
                  showQuickChips: false, // Không hiện chips bot của Faye AI
                  isDark: true,
                  hintText: 'Nhắn điều gì đó chân thành...',
                  leading: _buildHeartSyncButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Nút Chạm Tim Định Mệnh (Double Heart Sync)
  Widget _buildHeartSyncButton() {
    return GestureDetector(
      onTap: _onMyHeartTap,
      child: AnimatedBuilder(
        animation: _heartPulseController,
        builder: (context, _) {
          final scale = _myHeartPressed
              ? 1.0 + (_heartPulseController.value * 0.15)
              : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _myHeartPressed
                      ? [const Color(0xFFFF2A6D), const Color(0xFFFF5E97)]
                      : [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _myHeartPressed ? const Color(0xFFFF5E97) : Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: _myHeartPressed
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF2A6D).withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _myHeartPressed ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _myHeartPressed ? Colors.white : Colors.white70,
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Header chứa đồng hồ đếm ngược 120s và thông tin định mệnh
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nút Rời đi
          GestureDetector(
            onTap: _handleLeave,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Rời đi',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          // Đồng hồ đếm ngược 120s (Cosmic Ring Timer)
          SoulCountdownBadge(
            remainingSeconds: _remainingSeconds,
            isUnlockedForever: _isUnlockedForever,
          ),

          // Huy hiệu tương hợp
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF9D00FF).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF9D00FF).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  '${widget.partner.compatibilityScore}%',
                  style: const TextStyle(
                    color: Color(0xFFD896FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bong bóng tin nhắn
  Widget _buildMessageBubble(_SanctuaryMessage m) {
    return Align(
      alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: context.screenWidth * 0.76),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: m.isMe ? const Color(0xFFFF2A6D) : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(m.isMe ? 18 : 4),
            bottomRight: Radius.circular(m.isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          m.text,
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
        ),
      ),
    );
  }

  /// Dialog khi hết thời gian 120s
  Widget _buildTimeoutDialog() {
    return AlertDialog(
      backgroundColor: const Color(0xFF131526),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Center(
        child: Text('🌌 Sóng Định Mệnh Tan Biến', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      content: const Text(
        'Thời gian 120 giây đã kết thúc mà cả hai chưa kịp chạm tim nhau. Tần số này đã hòa vào ngân hà bao la. Chúc bạn luôn an yên!',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
      ),
      actions: [
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Trở về trang chủ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _SanctuaryMessage {
  final String text;
  final bool isMe;
  final DateTime time;

  _SanctuaryMessage({required this.text, required this.isMe, required this.time});
}

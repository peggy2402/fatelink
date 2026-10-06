import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/voice_note_service.dart';

/// Widget thanh ghi âm giọng nói phong cách Telegram (Telegram Voice Recording Bar)
/// - Nhấn giữ để ghi âm, thả ra để gửi
/// - Vuốt sang trái để hủy (Slide to cancel)
/// - Vuốt lên trên để khóa (Slide up to lock)
/// - Chế độ khóa: hỗ trợ tạm dừng, tiếp tục, hủy và gửi bằng nút bấm
class TelegramVoiceRecorderBar extends StatefulWidget {
  final Function(VoiceRecordResult result) onRecordComplete;
  final VoidCallback onRecordCancel;

  const TelegramVoiceRecorderBar({
    super.key,
    required this.onRecordComplete,
    required this.onRecordCancel,
  });

  @override
  State<TelegramVoiceRecorderBar> createState() => _TelegramVoiceRecorderBarState();
}

class _TelegramVoiceRecorderBarState extends State<TelegramVoiceRecorderBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _uiTimer;

  bool _isLocked = false;
  bool _isPaused = false;
  bool _isCanceling = false;
  double _dragOffsetX = 0.0;
  double _dragOffsetY = 0.0;
  int _currentMilliseconds = 0;

  static const double _kCancelThresholdX = -90.0;
  static const double _kLockThresholdY = -70.0;
  static const int _kMaxDurationMs = 300000; // 5 phút

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _startRecordingSession();
  }

  Future<void> _startRecordingSession() async {
    HapticFeedback.heavyImpact();
    final started = await VoiceNoteService().startRecording(context);
    if (!started) {
      widget.onRecordCancel();
      return;
    }

    // Cập nhật UI thời gian mỗi 100ms
    _uiTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      final ms = VoiceNoteService().elapsedMilliseconds;
      setState(() {
        _currentMilliseconds = ms;
      });

      // Tự động gửi nếu đạt 5 phút
      if (ms >= _kMaxDurationMs) {
        _handleFinishAndSend();
      }
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(int ms) {
    final totalSecs = ms ~/ 1000;
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void onPointerMove(PointerMoveEvent event) {
    if (_isLocked || _isCanceling) return;

    setState(() {
      _dragOffsetX += event.delta.dx;
      _dragOffsetY += event.delta.dy;
    });

    // 1. Kiểm tra vuốt LÊN để KHÓA
    if (_dragOffsetY <= _kLockThresholdY) {
      HapticFeedback.mediumImpact();
      setState(() {
        _isLocked = true;
        _dragOffsetX = 0;
        _dragOffsetY = 0;
      });
      debugPrint('🔒 [TelegramRecorder] Đã KHÓA ghi âm (Lock mode)');
      return;
    }

    // 2. Kiểm tra vuốt TRÁI để HỦY
    if (_dragOffsetX <= _kCancelThresholdX) {
      _handleCancelRecording();
    }
  }

  void onPointerUp(PointerUpEvent event) {
    if (_isLocked || _isCanceling) return;

    // Nếu chưa khóa, thả tay ra là HOÀN THÀNH VÀ GỬI
    _handleFinishAndSend();
  }

  Future<void> _handleCancelRecording() async {
    if (_isCanceling) return;
    _isCanceling = true;
    HapticFeedback.heavyImpact();
    _uiTimer?.cancel();
    await VoiceNoteService().cancelRecording();
    widget.onRecordCancel();
  }

  Future<void> _handleFinishAndSend() async {
    _uiTimer?.cancel();

    // Nếu thời lượng dưới 1 giây (< 1000ms), tự hủy và cảnh báo nhẹ
    if (_currentMilliseconds < 1000) {
      HapticFeedback.lightImpact();
      await VoiceNoteService().cancelRecording();
      widget.onRecordCancel();
      debugPrint('⚠️ [TelegramRecorder] Ghi âm dưới 1 giây -> Tự hủy không gửi');
      return;
    }

    HapticFeedback.mediumImpact();
    final result = await VoiceNoteService().stopRecording();
    if (result != null) {
      widget.onRecordComplete(result);
    } else {
      widget.onRecordCancel();
    }
  }

  Future<void> _handleTogglePause() async {
    HapticFeedback.lightImpact();
    if (_isPaused) {
      await VoiceNoteService().resumeRecording();
      setState(() => _isPaused = false);
    } else {
      await VoiceNoteService().pauseRecording();
      setState(() => _isPaused = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNearCancel = _dragOffsetX < -40.0;

    return Listener(
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEC4899).withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1. Chấm đỏ nhấp nháy báo đang thu âm
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return Opacity(
                  opacity: _isPaused ? 0.3 : (0.4 + 0.6 * _pulseController.value),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),

            // 2. Đồng hồ đếm thời gian mm:ss
            Text(
              _formatDuration(_currentMilliseconds),
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _isPaused ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 12),

            // 3. Nội dung giữa: "‹ Trượt để hủy" (khi chưa khóa) HOẶC Trạng thái khóa
            Expanded(
              child: _isLocked
                  ? Center(
                      child: Text(
                        _isPaused ? 'Đang tạm dừng' : 'Đang ghi âm (Đã khóa)',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12.5,
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Transform.translate(
                      offset: Offset(_dragOffsetX.clamp(-60.0, 0.0), 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chevron_left_rounded,
                            size: 18,
                            color: isNearCancel
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF94A3B8),
                          ),
                          Text(
                            isNearCancel ? 'Thả để hủy' : 'Trượt để hủy',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 12.5,
                              fontWeight: isNearCancel ? FontWeight.w700 : FontWeight.w500,
                              color: isNearCancel
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // 4. Các nút điều khiển khi ĐÃ KHÓA
            if (_isLocked) ...[
              // Nút Xóa / Hủy
              GestureDetector(
                onTap: _handleCancelRecording,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 24,
                  ),
                ),
              ),

              // Nút Tạm dừng / Tiếp tục
              GestureDetector(
                onTap: _handleTogglePause,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    _isPaused ? Icons.play_circle_outline_rounded : Icons.pause_circle_outline_rounded,
                    color: const Color(0xFF7C3AED),
                    size: 25,
                  ),
                ),
              ),

              // Nút GỬI
              GestureDetector(
                onTap: _handleFinishAndSend,
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Gợi ý vuốt lên để khóa (nhỏ gọn)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard_arrow_up_rounded, size: 14, color: Color(0xFF64748B)),
                    Text(
                      'Khóa',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

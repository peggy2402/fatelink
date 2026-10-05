import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/voice_note_service.dart';
import '../../../../core/utils/toast_utils.dart';

/// Modal ghi âm giọng nói trực tiếp (Voice Note) phong cách Telegram / WhatsApp
/// Tích hợp Microphone thật bằng VoiceNoteService (record package) & Upload lên Cloudinary
class CosmicVoiceRecorderModal extends StatefulWidget {
  final Function(String voiceMessageText, int durationSeconds) onSendVoice;

  const CosmicVoiceRecorderModal({
    super.key,
    required this.onSendVoice,
  });

  static void show(
    BuildContext context, {
    required Function(String voiceMessageText, int durationSeconds) onSendVoice,
  }) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CosmicVoiceRecorderModal(onSendVoice: onSendVoice),
    );
  }

  @override
  State<CosmicVoiceRecorderModal> createState() => _CosmicVoiceRecorderModalState();
}

class _CosmicVoiceRecorderModalState extends State<CosmicVoiceRecorderModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _timer;
  int _seconds = 0;
  bool _isPaused = false;
  bool _isUploading = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _initAndStartRecording();
  }

  Future<void> _initAndStartRecording() async {
    final hasPermission = await VoiceNoteService().hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ToastUtil.showError(context, 'Vui lòng cấp quyền Microphone để ghi âm giọng nói');
        Navigator.pop(context);
      }
      return;
    }

    final filePath = await VoiceNoteService().startRecording();
    if (filePath == null) {
      if (mounted) {
        ToastUtil.showError(context, 'Không thể khởi động bộ ghi âm trên thiết bị');
        Navigator.pop(context);
      }
      return;
    }

    if (mounted) {
      setState(() => _isReady = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isPaused && mounted) {
          setState(() => _seconds++);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _handleCancel() async {
    HapticFeedback.lightImpact();
    await VoiceNoteService().cancelRecording();
    if (mounted) {
      Navigator.pop(context);
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

  Future<void> _handleSend() async {
    if (_isUploading) return;
    if (_seconds == 0) _seconds = 1;

    HapticFeedback.mediumImpact();
    setState(() => _isUploading = true);

    // 1. Dừng ghi âm và nhận đường dẫn file .m4a thực tế
    final localPath = await VoiceNoteService().stopRecording();

    if (localPath == null) {
      if (mounted) {
        ToastUtil.showError(context, 'Ghi âm thất bại, vui lòng thử lại');
        Navigator.pop(context);
      }
      return;
    }

    // 2. Upload file lên Cloudinary CDN
    if (!mounted) return;
    final cloudUrl = await VoiceNoteService().uploadVoiceFile(
      context: context,
      localPath: localPath,
    );

    // 3. Tạo payload tin nhắn thoại hoàn chỉnh
    final durationSeconds = _seconds;
    final formattedTime = _formatDuration(durationSeconds);
    final voiceUrl = cloudUrl ?? localPath;
    final voicePayload = '🎙️ [voice:$voiceUrl|duration:$durationSeconds|time:$formattedTime]';

    widget.onSendVoice(voicePayload, durationSeconds);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Color(0x33EC4899),
              blurRadius: 28,
              offset: Offset(0, -6),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.paddingOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh kéo
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),

            // Huy hiệu Đang ghi âm nhấp nháy
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animController,
                  builder: (ctx, child) => Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEF4444).withValues(
                        alpha: _isPaused ? 0.3 : (0.4 + _animController.value * 0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isUploading
                      ? 'Đang gửi tin nhắn thoại...'
                      : (!_isReady
                          ? 'Đang khởi động micro...'
                          : (_isPaused ? 'Đã tạm dừng' : 'Đang lắng nghe giọng nói...')),
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isPaused ? const Color(0xFF64748B) : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Thời gian ghi âm đếm thực tế
            Text(
              _formatDuration(_seconds),
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Sóng âm giả lập chuyển động nhịp nhàng (Waveform Bars)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(24, (i) {
                      final factor = (i % 5 + 1) * 0.18;
                      final waveHeight = (_isPaused || !_isReady)
                          ? 8.0
                          : (12.0 + 36.0 * ((_animController.value + factor) % 1.0));
                      return Container(
                        width: 4,
                        height: waveHeight,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Hàng nút điều khiển: Hủy - Tạm dừng - Gửi
            if (_isUploading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF6366F1),
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Nút Hủy
                  IconButton(
                    onPressed: _handleCancel,
                    iconSize: 48,
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFF64748B),
                        size: 24,
                      ),
                    ),
                  ),

                  // Nút Tạm dừng / Tiếp tục
                  IconButton(
                    onPressed: _isReady ? _handleTogglePause : null,
                    iconSize: 52,
                    icon: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDDD6FE)),
                      ),
                      child: Icon(
                        _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        color: const Color(0xFF7C3AED),
                        size: 26,
                      ),
                    ),
                  ),

                  // Nút Gửi tin nhắn thoại
                  GestureDetector(
                    onTap: _isReady ? _handleSend : null,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

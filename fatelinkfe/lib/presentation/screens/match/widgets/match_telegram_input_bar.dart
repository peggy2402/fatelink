import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/services/voice_note_service.dart';
import '../../../../data/models/chat_message.dart';
import 'telegram_voice_recorder_bar.dart';

class MatchTelegramInputBar extends StatelessWidget {
  final TextEditingController chatController;
  final FocusNode focusNode;
  final bool hasInputText;
  final bool isRecordingVoice;
  final bool isEmojiPickerVisible;
  final String partnerDisplayName;
  final ChatMessage? replyingMessage;
  final VoidCallback onCancelReply;
  final VoidCallback onShowMediaActionSheet;
  final VoidCallback onPickCamera;
  final VoidCallback onShowAiSuggestionModal;
  final VoidCallback onToggleEmojiPicker;
  final ValueChanged<String> onSendMessage;
  final VoidCallback onStartRecordVoice;
  final VoidCallback onCancelRecordVoice;
  final Function(VoiceRecordResult result) onVoiceRecordComplete;

  const MatchTelegramInputBar({
    super.key,
    required this.chatController,
    required this.focusNode,
    required this.hasInputText,
    required this.isRecordingVoice,
    required this.isEmojiPickerVisible,
    required this.partnerDisplayName,
    this.replyingMessage,
    required this.onCancelReply,
    required this.onShowMediaActionSheet,
    required this.onPickCamera,
    required this.onShowAiSuggestionModal,
    required this.onToggleEmojiPicker,
    required this.onSendMessage,
    required this.onStartRecordVoice,
    required this.onCancelRecordVoice,
    required this.onVoiceRecordComplete,
  });

  Widget _buildReplyBanner() {
    if (replyingMessage == null) return const SizedBox.shrink();

    final isSentByMe = replyingMessage!.isSentByMe;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFF8B5CF6), width: 3.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, color: Color(0xFF8B5CF6), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Đang trả lời ${isSentByMe ? 'chính bạn' : partnerDisplayName}',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  replyingMessage!.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 12.5,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
            onPressed: onCancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    final effectiveBottomPadding = isEmojiPickerVisible
        ? 6.0
        : (bottomInset > 0
            ? 6.0
            : (safeBottom > 0 ? safeBottom : 8.0));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildReplyBanner(),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                border: const Border(
                  top: BorderSide(
                    color: Color(0xFFF1E5ED),
                    width: 1.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 10,
                right: 10,
                top: 8,
                bottom: effectiveBottomPadding,
              ),
              child: isRecordingVoice
                  ? TelegramVoiceRecorderBar(
                      onRecordComplete: onVoiceRecordComplete,
                      onRecordCancel: onCancelRecordVoice,
                    )
                  : Row(
                      children: [
                        // 1. Nút '+' mở Popup/Sheet đa tiện ích
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            color: Color(0xFF6366F1),
                            size: 26,
                          ),
                          tooltip: 'Chia sẻ ảnh, vị trí, voice note',
                          onPressed: onShowMediaActionSheet,
                        ),

                        // 2. Nút Camera chụp nhanh
                        IconButton(
                          icon: const Icon(
                            Icons.camera_alt_outlined,
                            color: Color(0xFF64748B),
                            size: 24,
                          ),
                          tooltip: 'Chụp ảnh nhanh',
                          onPressed: onPickCamera,
                        ),

                        // 3. Khung ô nhập văn bản tích hợp Emoji & Faye AI
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: chatController,
                                    focusNode: focusNode,
                                    style: const TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 14.5,
                                      color: Color(0xFF0F172A),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Nhắn tin cho $partnerDisplayName...',
                                      hintStyle: const TextStyle(
                                        fontFamily: 'BeVietnamPro',
                                        fontSize: 14,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (val) => onSendMessage(val),
                                  ),
                                ),
                                // Icon Faye AI gợi ý trả lời
                                GestureDetector(
                                  onTap: onShowAiSuggestionModal,
                                  behavior: HitTestBehavior.opaque,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                                    child: Icon(
                                      Icons.auto_awesome_rounded,
                                      color: Color(0xFF8B5CF6),
                                      size: 21,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                // Icon Emoji chuyển đổi giữa Bàn phím & Bảng chọn Emoji inline
                                GestureDetector(
                                  onTap: onToggleEmojiPicker,
                                  child: Icon(
                                    isEmojiPickerVisible
                                        ? Icons.keyboard_alt_outlined
                                        : Icons.sentiment_satisfied_alt_rounded,
                                    color: const Color(0xFF7C3AED),
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // 4. Nút Hành động chuyển đổi linh hoạt: Gửi vs Ghi âm
                        GestureDetector(
                          onTap: () {
                            if (hasInputText) {
                              onSendMessage(chatController.text);
                            } else {
                              onStartRecordVoice();
                            }
                          },
                          onLongPress: () {
                            if (!hasInputText) {
                              onStartRecordVoice();
                            }
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                hasInputText ? Icons.arrow_upward_rounded : Icons.mic_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../data/models/chat_message.dart';
import 'cosmic_voice_player_bubble.dart';
import 'glassmorphic_card_stack.dart';
import 'glassmorphic_image_viewer.dart';

class MatchMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMultiSelectMode;
  final bool isSelected;
  final LinearGradient auraGradient;
  final Widget partnerAvatarWidget;
  final VoidCallback onPartnerProfileTap;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final ValueChanged<ChatMessage> onRetrySendMessage;
  final ValueChanged<ChatMessage> onRetrySendImageMessage;
  final ValueChanged<ChatMessage> onRetrySendVoiceMessage;
  final VoidCallback onStartVoiceCall;

  const MatchMessageBubble({
    super.key,
    required this.message,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.auraGradient,
    required this.partnerAvatarWidget,
    required this.onPartnerProfileTap,
    required this.onLongPress,
    required this.onTap,
    required this.onRetrySendMessage,
    required this.onRetrySendImageMessage,
    required this.onRetrySendVoiceMessage,
    required this.onStartVoiceCall,
  });

  Widget _buildImageError() {
    return Container(
      width: 200,
      height: 150,
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8), size: 36),
      ),
    );
  }

  Widget _buildImageLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageErrorOverlay(VoidCallback onRetry) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onRetry,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chạm để thử lại',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyQuoteBox(bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.18)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white : const Color(0xFF8B5CF6),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyToSender ?? 'Tin nhắn',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isMe ? Colors.white : const Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyToText ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 12,
              color: isMe ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallMessageBubble(bool isMe) {
    final isMissed = message.isCallMissed;
    final isRejected = message.isCallRejected;
    final isFailed = isMissed || isRejected;

    final IconData icon = isMissed
        ? Icons.phone_missed_rounded
        : (isRejected ? Icons.phone_disabled_rounded : Icons.phone_in_talk_rounded);

    final Color statusColor = isFailed
        ? const Color(0xFFFF4757)
        : (isMe ? const Color(0xFF2ED573) : const Color(0xFF10B981));

    String title;
    String subtitle;
    if (isMissed) {
      title = isMe ? 'Cuộc gọi đi nhỡ' : 'Cuộc gọi thoại nhỡ';
      subtitle = isMe ? 'Đối phương không trả lời' : 'Bạn đã bỏ lỡ cuộc gọi';
    } else if (isRejected) {
      title = isMe ? 'Cuộc gọi bị từ chối' : 'Đã từ chối cuộc gọi';
      subtitle = isMe ? 'Đối phương đã từ chối' : 'Cuộc gọi thoại bị từ chối';
    } else {
      title = 'Cuộc gọi thoại';
      subtitle = message.text.contains('(') ? message.text : 'Đã kết thúc cuộc gọi';
    }

    if (message.durationMs != null && message.durationMs! > 0) {
      final totalSec = message.durationMs! ~/ 1000;
      final m = (totalSec ~/ 60).toString().padLeft(2, '0');
      final s = (totalSec % 60).toString().padLeft(2, '0');
      subtitle = 'Thời lượng: $m:$s';
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 165),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe
                  ? Colors.white.withValues(alpha: 0.22)
                  : statusColor.withValues(alpha: 0.12),
            ),
            child: Icon(
              icon,
              color: isMe ? Colors.white : statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: isMe ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: isMe ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF64748B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.phone_forwarded_rounded,
              color: isMe ? Colors.white : const Color(0xFF8B5CF6),
              size: 20,
            ),
            tooltip: 'Gọi lại',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            onPressed: onStartVoiceCall,
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleContent(
    BuildContext context,
    bool isMe,
    bool isSingleImage,
    bool isImageStack,
    bool isVoice,
    bool isLocation,
    bool isRevoked,
  ) {
    if (isRevoked) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block_flipped, color: Color(0xFF94A3B8), size: 16),
          SizedBox(width: 6),
          Text(
            'Tin nhắn đã được thu hồi',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              color: Color(0xFF94A3B8),
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    if (isImageStack) {
      return Stack(
        alignment: Alignment.center,
        children: [
          GlassmorphicCardStack(
            images: message.imageUrls,
            isSentByMe: isMe,
          ),
          if (message.isSending) _buildImageLoadingOverlay(),
          if (message.isSendError)
            _buildImageErrorOverlay(() => onRetrySendImageMessage(message)),
        ],
      );
    }

    if (isSingleImage) {
      final img = message.imageUrls.isNotEmpty
          ? message.imageUrls.first
          : message.text.replaceFirst('[Hình ảnh]', '').trim();

      return Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (message.isSendError) {
                onRetrySendImageMessage(message);
              } else if (!message.isSending) {
                GlassmorphicImageViewer.show(context, images: [img], initialIndex: 0);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: img.startsWith('file://')
                  ? Image.file(
                      File(img.replaceFirst('file://', '')),
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => _buildImageError(),
                    )
                  : Image.network(
                      img,
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => _buildImageError(),
                    ),
            ),
          ),
          if (message.isSending) _buildImageLoadingOverlay(),
          if (message.isSendError)
            _buildImageErrorOverlay(() => onRetrySendImageMessage(message)),
        ],
      );
    }

    if (isVoice) {
      return CosmicVoicePlayerBubble(
        message: message,
        isSentByMe: isMe,
        onRetrySend: message.isSendError ? () => onRetrySendVoiceMessage(message) : null,
      );
    }

    if (isLocation) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMe ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: isMe ? Colors.white : const Color(0xFF059669),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.text,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                color: isMe ? Colors.white : const Color(0xFF1E293B),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    if (message.isCall) {
      return _buildCallMessageBubble(isMe);
    }

    return Text(
      message.text,
      style: TextStyle(
        fontFamily: 'BeVietnamPro',
        color: isMe ? Colors.white : const Color(0xFF1E293B),
        fontSize: 14.5,
        height: 1.45,
        letterSpacing: 0.1,
        fontWeight: isMe ? FontWeight.w500 : FontWeight.w400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMe = message.isSentByMe;
    final timeString =
        "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}";

    final isImageStack = message.messageType == 'imageStack' || message.imageUrls.length > 1;
    final isSingleImage = message.messageType == 'image' || (message.imageUrls.length == 1) || message.text.startsWith('[Hình ảnh]');
    final isVoice = message.isVoice;
    final isLocation = message.messageType == 'location' || message.text.startsWith('📍 [Vị trí]');
    final isRevoked = message.isRevoked;

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: isMultiSelectMode ? onTap : null,
      child: Container(
        color: isSelected ? const Color(0xFFEDE9FE).withValues(alpha: 0.5) : Colors.transparent,
        child: Row(
          children: [
            if (isMultiSelectMode)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
                  size: 22,
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Avatar đối phương bên trái
                    if (!isMe) ...[
                      GestureDetector(
                        onTap: onPartnerProfileTap,
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 8, bottom: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: auraGradient,
                          ),
                          padding: const EdgeInsets.all(1.5),
                          child: ClipOval(
                            child: partnerAvatarWidget,
                          ),
                        ),
                      ),
                    ],

                    // Nội dung bong bóng
                    Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.74,
                              ),
                              padding: (isImageStack || isSingleImage)
                                  ? const EdgeInsets.all(4)
                                  : (isVoice
                                      ? const EdgeInsets.symmetric(vertical: 4, horizontal: 8)
                                      : const EdgeInsets.symmetric(vertical: 12, horizontal: 16)),
                              decoration: BoxDecoration(
                                gradient: isMe && !isRevoked
                                    ? const LinearGradient(
                                        colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isRevoked
                                    ? const Color(0xFFF1F5F9)
                                    : (isMe ? null : Colors.white),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(22),
                                  topRight: const Radius.circular(22),
                                  bottomLeft: isMe ? const Radius.circular(22) : const Radius.circular(6),
                                  bottomRight: isMe ? const Radius.circular(6) : const Radius.circular(22),
                                ),
                                border: (isMe && !isRevoked)
                                    ? null
                                    : Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: isMe && !isRevoked
                                        ? const Color(0xFFEC4899).withValues(alpha: 0.25)
                                        : const Color(0xFF64748B).withValues(alpha: 0.08),
                                    blurRadius: isMe ? 12 : 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (message.replyToText != null && !isRevoked)
                                    _buildReplyQuoteBox(isMe),
                                  _buildBubbleContent(
                                    context,
                                    isMe,
                                    isSingleImage,
                                    isImageStack,
                                    isVoice,
                                    isLocation,
                                    isRevoked,
                                  ),
                                ],
                              ),
                            ),
                            // Badge Reaction nổi
                            if (message.reaction != null && !isRevoked)
                              Positioned(
                                bottom: -8,
                                right: isMe ? null : -4,
                                left: isMe ? -4 : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    message.reaction!,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Thời gian và trạng thái gửi
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                timeString,
                                style: const TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10.5,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                if (message.isSending)
                                  const SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF94A3B8)),
                                    ),
                                  )
                                else if (message.isSendError)
                                  GestureDetector(
                                    onTap: () => onRetrySendMessage(message),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.error_outline_rounded, color: Color(0xFFFF3B30), size: 13),
                                        SizedBox(width: 2),
                                        Text(
                                          'Thử lại',
                                          style: TextStyle(
                                            fontFamily: 'BeVietnamPro',
                                            color: Color(0xFFFF3B30),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.done_all_rounded,
                                    color: Color(0xFF6366F1),
                                    size: 13,
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

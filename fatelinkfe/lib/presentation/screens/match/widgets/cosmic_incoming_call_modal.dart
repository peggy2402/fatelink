import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Legacy stub wrapper for CosmicIncomingCallModal.
/// Hiện tại cuộc gọi đến được CallManager quản lý tự động qua socket sự kiện toàn app.
class CosmicIncomingCallModal extends StatelessWidget {
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final IO.Socket socket;
  final dynamic offerSdp;

  const CosmicIncomingCallModal({
    super.key,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.socket,
    this.offerSdp,
  });

  static void show(
    BuildContext context, {
    required String callerId,
    required String callerName,
    String? callerAvatar,
    required IO.Socket socket,
    dynamic offerSdp,
  }) {
    // CallManager đã tự động mở route full-screen khi nhận incomingVoiceCall từ socket
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

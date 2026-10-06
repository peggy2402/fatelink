import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../../services/call_manager.dart';

/// Legacy stub wrapper for CosmicVoiceCallModal.
/// Chuyển tiếp toàn bộ yêu cầu sang CallManager và Route full-screen CosmicVoiceCallScreen.
class CosmicVoiceCallModal extends StatelessWidget {
  final String partnerName;
  final String? partnerAvatar;
  final String partnerId;
  final IO.Socket socket;
  final bool isIncomingAccept;
  final dynamic offerSdp;

  const CosmicVoiceCallModal({
    super.key,
    required this.partnerName,
    required this.partnerId,
    required this.socket,
    this.partnerAvatar,
    this.isIncomingAccept = false,
    this.offerSdp,
  });

  static void show(
    BuildContext context, {
    required String partnerName,
    required String partnerId,
    required IO.Socket socket,
    String? partnerAvatar,
    bool isIncomingAccept = false,
    dynamic offerSdp,
  }) {
    if (isIncomingAccept) {
      CallManager.instance.acceptIncomingCall();
    } else {
      CallManager.instance.startOutgoingCall(
        partnerId: partnerId,
        partnerName: partnerName,
        partnerAvatar: partnerAvatar,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
